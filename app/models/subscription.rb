# A subscription lives in exactly one state and moves along the paths below;
# timestamps must match the state, and each move fires the listed emails on commit.
#
#   (new subscription)
#          │
#          ▼
#   pending_confirmation ────── confirm ─────▶ active
#          │                                  │
#          └────────────── unsubscribe ───────┘
#                              │
#                              ▼
#                        unsubscribed
#
#   on create                  → author is told about the new subscriber
#                                (+ confirmation email, still pending)
#   pending_confirmation→active → subscribed email
#
#   Re-subscribing starts a new subscription.

class Subscription < ApplicationRecord
  # Manages the subscription state machine: status enum, legal transitions,
  # timestamp tracking, confirmation tokens, and the one-current-subscription rule.
  include Subscription::Lifecycle

  # Handles notifications triggered by subscription lifecycle events:
  # author notifications, confirmation emails, and subscribed welcome emails.
  include Subscription::Notifications

  belongs_to :subscriber, touch: true, inverse_of: :subscriptions
end
