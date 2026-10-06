# Publishing

Publishing is the core functionality of soapbox. Authors create posts and publish them when they are ready to make them available to readers. Publishing a post makes it available on the blog and adds it to the blog's Atom feed. Authors can separately choose to deliver a published post to subscribers by email. Soapbox tracks publication and email delivery independently so a post can be published without being emailed and email delivery can be stopped during its cancellation window without unpublishing the post.

## Posts

Each piece of writing is represented by a [`Post`](../app/models/post.rb). A post has a title, a slug used in its URL, an optional summary, Markdown content, a publication status, and a separate email status. The summary and content are stored through Soapbox's [Markdown](libraries/action-text-markdown.md) implementation.

The slug identifies the post in both public and administrative URLs. When an author does not provide one, Soapbox generates it from the title. Slugs are limited to 50 characters and must consist of lowercase letters and numbers separated by single hyphens. Model validation and a unique database index prevent two posts from using the same slug.

Slugs can be edited after publication, but Soapbox does not keep a history of previous slugs or redirect them to the new one. Because the slug is used in public web links, Atom feed entries, and the read-online links in post emails, changing it after publication will break links that have already been shared.

Summaries are optional. When a post has no summary, [`Post::Excerpt`](../app/models/post/excerpt.rb) builds one from the first 80 words of the rendered content's plain text. If there are more than 80 words in the content, an ellipsis is added at the end.

## Publishing a Post

Posts have a strictly defined lifecycle enforced at both the application and database layers. Moving a post through the different states of its lifecycle have side effects via callbacks.

Posts begin as drafts. Publishing makes a post available to readers; unpublishing removes it from the public blog and returns it to a draft.

```text

   draft ────── [ publish ] ──────▶ published
     ▲                                  │
     └──────── [ unpublish ] ───────────┘

```

A post must have content before it can be published. Publishing also sets `published_at` to the current time, while unpublishing clears it. `published_at` therefore reflects the time of the latest move to the published state rather than preserving the date of any earlier publishes.

Publishing behavior revolves largely around changing the state via the `status` field. However, it is generally discouraged from mutating that field directly. Using the `publish` and `unpublish` methods is preferred.

[`Admin::Posts::StatusesController`](../app/controllers/admin/posts/statuses_controller.rb) handles publish and unpublish requests from the admin area.

Published posts appear on the public blog on the web and in the Atom feed, in both cases handled by [`PostsController`](../app/controllers/posts_controller.rb). Draft posts are only accessible in the admin interface&mdash;attempting to view the public page for a slug whose post is draft will return a not-found response even though the post does actually exist.

Published posts are ordered first by whether they are pinned and then by publication time, newest first. The Atom feed has orders by publication time only (newest first) and does not take pinning into account.

## Emailing a Published Post

Readers can choose to subscribe to the blog and receive future updates via email. Publishing a post does not automatically email it to subscribers, though. An author must start email delivery separately. The email process, like the publishing process, is enforced by a strict lifecycle defined in [`Post::Emailing`](../app/models/post/emailing.rb).

This lifecycle is centered around the `email_status`. A post's email delivery status has three states:

* `not_started` means email delivery has not been requested
* `pending` means delivery has been requested but can still be stopped
* `initiated` means recipient records have been created and their delivery jobs have been queued

```text

   not_started
        │
        │ [ start emails ]
        │ generate key; wait one minute
        ▼
      pending ────── [ stop emails or unpublish ] ──────▶ not_started
        │
        │ delayed job runs with matching key
        │ create PostEmail records and enqueue mail
        ▼
     initiated

```

`Post#start_emails` changes the email status of the post to `pending`. Callbacks on the lifecycle create a unique job key and queue a [`Post::StartEmailsJob`](../app/jobs/post/start_emails_job.rb) with that key to run after a one-minute delay. This delay is to afford the author an opportunity to cancel the email process. Canceling the email process via `Post#stop_emails` moves the status back to `not_started` and clears the job key. [`Admin::Posts::EmailStatusesController`](../app/controllers/admin/posts/email_statuses_controller.rb) handles these start and stop requests from the admin area.

Active Job cannot cancel an already queued job, so the job key now acts as a cancellation signal. When the delayed job eventually runs, it first checks whether its key still matches the key on the post and only proceeds if they match.

`Post::Emailing` validates that only a published post can move to `pending`, that `initiated` can only follow `pending`, and that email status cannot change after reaching `initiated`. Database constraints separately protect the valid email statuses, the required relationship between email status and job key, and the rule that a draft post cannot have pending email delivery.

When the delayed job begins delivery, Soapbox selects active subscribers and creates one [`PostEmail`](../app/models/post_email.rb) for each subscriber's `latest_subscrition`. A `PostEmail` records that a particular subscription should receive a particular post via email. On creation, it queues [`PostMailer#post_email`](../app/mailers/post_mailer.rb) which will actually send the email. A unique database index on `post_id` and `subscription_id` prevents duplicate `PostEmail` records for the same post and subscription.

Unpublishing will stop an email delivery request that is still `pending`, moving `email_status` back to `not_started`. Once a post reaches `initiated`, though, its email status and recipient history are preserved regardless to changes in the publishing status. Unpublishing a post after it has been emailed to subscribers will not cancel its queued emails, delete its `PostEmail` records, or otherwise remove the history of its deliveries.

This pending-email cancellation is enforced by `Post::Emailing#prevent_emails_for_draft`, a callback that resets `email_status` whenever a post moves to draft. Keeping the behavior in the lifecycle means every path that unpublishes a post receives the same protection rather than relying on each caller to remember to stop email separately.

### Email Content and Delivery

Each `PostEmail` queues [`PostMailer#post_email`](../app/mailers/post_mailer.rb) after the recipient record has been committed. The mailer sends the message from the blog name at `updates@<blog domain>` and directs replies to the author's email address. The post title becomes the subject. The [HTML template](../app/views/post_mailer/post_email.html.erb) reuses the same [post partial](../app/views/posts/_post.html.erb) used on the website. The message is delivered through Postmark's `broadcast` message stream.

Post emails are sent as `multipart/alternative`, which gives the recipient's email application both an HTML version and a plain-text version of the same message.

Email applications do not reliably load external stylesheets. Before delivery, [Premailer](https://github.com/fphilipe/premailer-rails) reads those stylesheets, copies their rules into `style` attributes on the corresponding HTML elements, and removes the stylesheet links. This allows the emailed post to retain the website's formatting and Rouge syntax highlighting without depending on the recipient's email application to fetch Soapbox's CSS files.

The [plain-text template](../app/views/post_mailer/post_email.text.erb) includes the post title, author, publication date, original Markdown content, a link to read the post online, and an unsubscribe link.

Both versions include an unsubscribe link, and `PostMailer` also adds the one-click unsubscribe headers described in [Readership](readership.md#unsubscribing).


## Atom Feed

The blog is also available as an Atom feed. The Atom feed includes an entry for every published post, ordered by `published_at` newest to oldest. (Unlike the web representation of posts, pinning does not affect this order.) Each entry includes the full rendered post content, author name, public post URL, and the time the post was last updated. [`Blog::Feed`](../app/models/blog/feed.rb) is responsible for building the feed, while individual items are the responsibility of [`Blog::Feed::Entry`](../app/models/blog/feed/entry.rb).

Feed and entry IDs use stable tag URIs. The feed ID uses the blog's creation date and `/feed`; each entry uses the post's creation date and database ID. Changing a post's slug therefore changes its link but not its identity in feed readers.

The canonical host configured in production is part of the feed IDs and links. Changing it changes the publication identity exposed to feed readers.
