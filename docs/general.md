# Domain Decisions

This document explains why several core domain rules exist in Soapbox and how those rules are enforced in the application and database. The goal is not just to describe implementation details, but to make the product intent explicit so future changes can preserve the same business behavior.

## Singleton records: `Author` and `Blog`

Soapbox is built for one publication operated by one owner, not a multi-tenant publishing platform. That product decision drives the data model: there should only ever be one `Author` row and one `Blog` row in a healthy installation.

At the application level, both models expose singleton-oriented APIs (`instance`, `instance!`, and `instance?`) so the rest of the codebase can express domain intent directly instead of repeatedly asking for "the first" record. They also validate on create (`single_instance_only`) to provide immediate, user-friendly feedback if an extra row is attempted.

At the database level, each table uses a `singleton_guard` column that is constrained to `true` and uniquely indexed. This is a simple way to enforce a one-row invariant without introducing a separate singleton registry table. The business reason for both layers is straightforward: model validations make the admin experience understandable, while constraints keep the invariant intact under race conditions or any path that bypasses validations.

The request lifecycle also reflects this business rule. Until both singleton records exist, the site is considered not yet configured. `SiteSetup.complete?` checks for that state, `ApplicationController#ensure_site_setup!` returns `503` responses while setup is incomplete, and `bin/rails site:setup` is the supported bootstrap path. In product terms, this prevents visitors from seeing a half-configured blog that has no defined identity or owner.

## Subscription lifecycle

Subscriptions are modeled as periods of time, not as a single boolean flag attached to a subscriber forever. This preserves useful business history: a reader can subscribe, unsubscribe, and later re-subscribe, and each period remains auditable as a separate record.

`Subscriber#activate` and `Subscriber#deactivate` are intentionally idempotent. Repeating the same command does not create duplicate active state or produce noisy failures. That behavior supports real entry points such as repeat form submissions, repeated admin actions, and unsubscribe links clicked more than once.

A subscriber may have many `Subscription` rows over time, but only one active row at once. Active periods require a `start_date` and must not have an `end_date`; deactivation sets `end_date` (defaulting to `Date.current` when missing). The key business rule is that ended periods are historical facts and are not reopened. When someone returns to the list after unsubscribing, the system creates a new active period instead of mutating old history.

Unsubscribe behavior is deliberately routed through the same lifecycle. `Subscriber#unsubscribe` delegates to `deactivate`, so public unsubscribe links and admin state changes share one set of domain rules rather than drifting into separate implementations.

These behaviors are enforced in two places. `Subscription` model validations express the domain clearly in code, and the database backs them with a partial unique index (`active = 1`) plus check constraints for start/end date consistency. That dual enforcement keeps the lifecycle trustworthy even if callbacks or validations are bypassed.

## Post email status transitions

Email delivery for a post is modeled as a small state machine with three states: `not_started`, `pending`, and `initiated`. The business intent is to make sending explicit, controllable, and safe from duplicate fan-out.

`start_emails!` moves a post from `not_started` to `pending`, and `stop_emails!` moves it back to `not_started`. Only background initiation can move `pending` to `initiated`. A post cannot enter `pending` unless it is published, because sending draft content is an invalid business outcome. Once a post reaches `initiated`, its email status is frozen to preserve delivery history and prevent ambiguous restart semantics.

The lifecycle is intentionally callback-driven, and each callback maps to a specific business event.

When an editor starts emailing (`start_emails!`), the post status changes to `pending`. That status change triggers `Post::Emailing`'s `before_validation` callback (`update_start_emails_job_key`), which generates a fresh `start_emails_job_key`. After the record commits, `after_commit :enqueue_start_emails_job` runs (only for transitions to `pending`) and schedules `Post::StartEmailsJob` with a short delay. In product terms, this delay gives the system a controlled handoff point between "requested sending" and "begin sending."

When an editor stops emailing (`stop_emails!`), status returns to `not_started`. The same `before_validation` callback runs, but in this state it clears `start_emails_job_key` instead of generating a new one. No start job is enqueued, because the `after_commit` enqueue callback is scoped to transitions to `pending` only. This is what makes "stop" a true cancellation signal rather than just a UI toggle.

When the delayed start job executes, `Post::StartEmailsJob` calls `initiate_emails_using_key`. That method compares the job's key to the post's current `start_emails_job_key` and proceeds only on a match. The key therefore acts as a version token: if someone started, stopped, and restarted emailing, older enqueued jobs are intentionally ignored.

If the key matches, `initiate_emails` builds one `PostEmail` record for each active subscription and transitions the post to `initiated`. Creating each `PostEmail` then triggers its own `after_create_commit` callback (`enqueue_email`), which enqueues `PostEmailsMailer.post_email.deliver_later`. This second callback layer is what turns one post-level initiation event into many recipient-level delivery jobs.

The result is a two-stage fan-out flow: a single post-level callback chain (`pending` commit -> start job) followed by per-recipient callback chains (`PostEmail` commit -> mail delivery job). A unique index on `[post_id, subscription_id]` guarantees that each subscription receives at most one delivery record for a given post, even if retries or race conditions occur.

As with other domains, model rules are backed by database constraints on `posts` so invalid combinations cannot persist: email status must be valid, job key presence must match status, and `pending` requires a published post.

## Post code highlighting

Soapbox highlights code blocks on both the web post view and the emailed post view. The important product decision here is consistency: a reader should see the same content and formatting whether they read on the site or in their inbox.

There are excellent frontend syntax highlighters, but they depend on browser-side execution and do not carry over well to email clients. Because Soapbox intentionally reuses as much of the same rendering path as possible between web and email, code highlighting is done on the backend with Rouge. That lets us format once and deliver comparable output in both channels.

Authoring follows a simple convention that works with Trix: the first line of a code block is treated as the language hint (for example, `ruby`), and the remaining lines are treated as source code. During render, the language line is treated as metadata and removed from display, so readers only see the code itself. If the language hint is missing or unknown, the block is left unchanged instead of guessing and risking accidental content loss.

The rendering flow stays intentionally small and shared. Posts are transformed through helper logic that marks highlighted blocks with `.highlight`, then a shared Rouge theme style helper is applied in both the main app layout and the HTML mailer head. `premailer-rails` then inlines the needed styles for delivery. This keeps one coherent formatting story for technical posts across web and email without introducing separate presentation systems.
