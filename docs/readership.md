# Readership

Readers can subscribe to a soapbox blog in order to receive future posts delivered to their email address. Soapbox separates a reader's identity from the state of their readership. A `Subscriber` owns the reader's details (currently, just an email address) and a `Subscription` records a period of readership. This separation preserves opt-in history if someone unsubscribes and later re-subscribes and also makes it possible to accurately track trends in readership over time.

## Subscribers

Subscribers are identified by their email address. This is currently the only detail the application collects about them. Email addresses are normalized before validation and uniqueness is enforced. Because subscription confirmation is tied to a specific inbox, email address is an immutable field.

`Subscriber` does not directly track the current state of readership. Rather, a subscriber's current status comes from their most recent subscription. Status&mdash;`pending_confirmation`, `active`, or `unsubscribed`&mdash;is delegated to that subscription (see below for details on `Subscription` statuses).

The [`Subscriber`](../app/models/subscriber.rb) model deliberately reads current status through its `subscriptions` association instead of maintaining a separate `current_subscription` association or status column. A `has_one` association would replace the previous subscription when a new one is assigned, even though previous subscriptions need to remain attached as history. It would also maintain a separate association cache that could show stale status immediately after a new subscription is created. `latest_subscription` and the status scopes both use the subscription history as their source of truth, avoiding either problem.

## Subscriptions

Subscriptions are attached to subscribers. A subscriber is guaranteed at least one subscription, but it can potentially have many. However, validations enforce that there can only ever be one current subscription (defined as status `pending_confirmation` or `active`, otherwise explained as excluding `unsubscribed`) per subscriber.

Subscriptions follow a strict lifecycle enforced at both the application and database levels. A subscription can be in one of three states:

* `pending_confirmation` means a subscription has been created, but the user has not yet confirmed it
* `active` means the subscriber has confirmed their subscription and is currently subscribed; they will receive future post emails
* `unsubscribed` means the user has ended their subscription; they are no longer part of the mailing list and will not receive future post emails

A subscription can only travel in one direction through the lifecycle. Subscriptions pending confirmation can either be confirmed or unsubscribed without an activation period. An active subscription can be unsubscribed. Once unsubscribed, a subscription can never be reactivated.

```text

   (new subscription)
          │
          ▼
   pending_confirmation ────── [ confirm ] ──────────▶ active
          │                                       │
          └────────────── [ unsubscribe ] ────────┘
                              │
                              ▼
                        unsubscribed

```

Callbacks drive significant features of the `Subscription` lifecycle. On creation, the subscriber is automatically sent a confirmation email that includes a link they visit to confirm and activate their subscription ([`SubscriptionsMailer#confirmation`](../app/mailers/subscriptions_mailer.rb)). The author is also sent an email notifying them that the blog has a new signup ([`SubscriptionsMailer#new_subscriber_author_notification`](../app/mailers/subscriptions_mailer.rb)). On confirmation, the subscriber receives an email letting them know they have completed the opt-in process ([`SubscriptionsMailer#subscribed`](../app/mailers/subscriptions_mailer.rb)).

The timestamp fields `confirmed_at` and `unsubscribed_at` track the progression of a subscription through its lifecycle. Confirmation sets `confirmed_at`, and unsubscription sets `unsubscribed_at`, both to the current time at run. Like the emails, these timestamp fields are set by callbacks when the subscription status changes.

The implementation is split into two concerns included by [`Subscription`](../app/models/subscription.rb). [`Subscription::Lifecycle`](../app/models/subscription/lifecycle.rb) owns the statuses, permitted transitions, timestamps, confirmation tokens, and the rule that a subscriber can have only one current subscription. [`Subscription::Notifications`](../app/models/subscription/notifications.rb) owns the emails triggered by creation and confirmation.

The lifecycle is also protected in the database by database constraints. Check constraints keep each status paired with the appropriate timestamps. A partial unique index on `subscriber_id` permits only one `pending_confirmation` or `active` subscription for a subscriber while allowing any number of historical `unsubscribed` subscriptions.

## Subscribing

Visitors to the blog subscribe by submitting their email address to a form on the site that is handled by [`Subscribers::SignupsController`](../app/controllers/subscribers/signups_controller.rb). The result of a signup depends on the subscriber's current state. Submission of a previously unseen email address creates new subscriber (which, in turn, attaches a new pending subscription by default). Submission of an email address belonging to an existing subscriber is handled according to that subscriber's current state: if the subscriber's subscription is still `pending_confirmation`, signing up resends the confirmation email for the existing subscription; if the subscriber's latest subscription is `active`, signing up does nothing; if the subscriber's latest subscription is `unsubscribed` then a new pending subscription will be created.

Authors can also add subscribers through the blog's admin area. This process follows the same lifecyle rules as visitor-initiated signups.

The public signup process includes several features to mitigate potential spam. In addition to requiring confirmation via email before activating a subscription, signup attempts are limited to three requests in ten minutes. The form also includes a hidden honeypot field; submissions that include a value for a honeypot field will not trigger the subscribe process.

## Confirming a Subscription

On creation of a new subscription (or an attempt to subscribe a subscriber whose `latest_subscrition` is `pending_confirmation`), an email ([`SubscriptionsMailer#confirmation`](../app/mailers/subscriptions_mailer.rb)) will be sent to the subscriber with a link to confirm their subscription. The confirmation link includes a confirmation token via `generates_token_for`; confirmation links can only be generated for pending subscriptions and expire after a subscription moves from pending to another status.

Following the link in a confirmation email brings the subscriber to a page where they must click to finally confirm their subscription. This extra step prevents email scanners and link previews from completing the opt-in process by merely opening the URL.

[`Subscriptions::ConfirmationsController#show`](../app/controllers/subscriptions/confirmations_controller.rb) handles the `GET` request that displays the page, while [`Subscriptions::ConfirmationsController#update`](../app/controllers/subscriptions/confirmations_controller.rb) handles the `PATCH` request that confirms the subscription.


## Unsubscribing

Readers who no longer wish to receive updates via email can unsubscribe from the publication. Unsubscribe links are included in the footer of email updates.

A reader following an unsubscribe link is brought to a confirmation page. Submitting that page ends their current subscription. Like with the confirmation links, this two-step process is in place to ensure that email scanners and link previews do not accidentally trigger the unsubscribe process. One-click unsubscribe links are, however, included in the email headers (`List-Unsubscribe` and `List-Unsubscribe-Post`) in accordance with RFC 8058, so readers with applications that have features around those one-click links will be able to use that rather than the two-step process.

[`Subscribers::UnsubscribesController#show`](../app/controllers/subscribers/unsubscribes_controller.rb) handles the `GET` request that displays the confirmation page, and [`Subscribers::UnsubscribesController#complete`](../app/controllers/subscribers/unsubscribes_controller.rb) handles the `PATCH` request that ends the subscription. [`Subscribers::UnsubscribesController#one_click`](../app/controllers/subscribers/unsubscribes_controller.rb) handles the `POST` request made by mail clients using one-click unsubscribe.

Unsubscribe links also include a token that identifies the subscriber trying to unsubscribe. Note that unsubscribe tokens&mdash;unlike confirmation tokens&mdash;are related to the subscriber directly rather than the subscription. This is to ensure that unsubscribe links always apply to the reader. For example, if a reader subscribes, unsubscribes, re-subscribes, and then tries to unsubscribe again using a link generated from the first subscription, it will still successfully unsubscribe the later subscription.
