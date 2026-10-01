# Creates lived-in sample data in the development database
# published posts spread across the last few months, a couple of drafts, 
# readers at every stage of the subscription lifecycle,
# and one completed email delivery.
#
# Nothing is ever mailed. The job adapter is set to :test, so the lifecycle
# emails and post emails these records naturally trigger are only enqueued.
# The script can be run more than once: every run adds new records, with
# fresh slugs and addresses, next to the ones already there.
#
# run with `bin/rails runner script/create_sample_records.rb`

require "active_support/testing/time_helpers"
include ActiveSupport::Testing::TimeHelpers

abort "Create an author and a blog first — the sample records build on your existing site." unless Author.instance? && Blog.instance?

ActiveJob::Base.queue_adapter = :test

RNG = Random.new(20260930)

PUBLISHED_TITLES = [
  "Notes From the Editor's Desk",
  "On Writing in Public",
  "The Shape of a Good Post",
  "Why I Still Publish an Atom Feed",
  "Small Tools, Long Lifetimes",
  "Reading Slowly in a Fast Year",
  "The Quiet Discipline of Editing",
  "What the Archive Taught Me"
]
PENDING_EMAILS_TITLE = "Lessons From a Year of Weekly Posts"
DELIVERED_EMAILS_TITLE = "Designing for One Reader"
DRAFT_TITLES = [ "A Field Guide to Drafts", "The Mailbag, Reconsidered" ]

ACTIVELY_READING_EMAILS = [
  "clara.whitfield@hey.com.invalid",
  "dov.rosenfeld@posteo.net.invalid",
  "ines.moreau@gmx.com.invalid",
  "waldo.brandt@tutanota.com.invalid",
  "priya.raghavan@fastmail.com.invalid",
  "otto.lindqvist@proton.me.invalid",
  "maeve.oconnell@icloud.com.invalid",
  "santiago.vera@outlook.com.invalid"
]
AWAITING_CONFIRMATION_EMAILS = [
  "yusuf.demir@gmail.com.invalid",
  "greta.sorensen@yahoo.com.invalid",
  "harold.kim@zmail.infomail.io.invalid",
  "noor.haddad@mailbox.org.invalid"
]
LONG_AGO_UNSUBSCRIBED_EMAILS = [ "bianca.lupescu@me.com.invalid", "arvid.johansson@lavabit.com.invalid" ]
NEVER_CONFIRMED_EMAIL = "tessa.dark@gmail.com.invalid"

LOREM_SENTENCES = [
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
  "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
  "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
  "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam.",
  "Eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.",
  "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores.",
  "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.",
  "Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur.",
  "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.",
  "At vero eos et accusamus et iusto odio dignissimos ducimus, qui blanditiis praesentium voluptatum deleniti atque corrupti.",
  "Et harum quidem rerum facilis est et expedita distinctio, nam libero tempore cum soluta nobis est eligendi.",
  "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae.",
  "Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis.",
  "Nam omnis iste natus error sit voluptatem, quae ab illo inventore veritatis et quasi architecto.",
  "Accusamus et iusto odio dignissimos ducimus, qui blanditiis praesentium voluptatum deleniti atque.",
  "Corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.",
  "Similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga."
]
LOREM_WORDS = "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore dolore magna aliqua enim ad minim veniam quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo consequat duis aute irure reprehenderit voluptate velit esse cillum fugit nulla pariatur excepteur sint occaecat cupidatat non proident in culpa qui officia deserunt mollit anim id est laborum".split

# The verbs the story below is told with. Each one drives the real models
# through their intended API at the moment in time it names, so timestamps,
# transitions, tokens, and callbacks behave exactly as they would live.

def signs_up(email_address, on:)
  travel_to(on) { Subscriber.create!(email_address: a_fresh_address(email_address)) }
end

def confirms(subscriber, on:)
  travel_to(on) { raise "could not confirm #{subscriber.email_address}" unless subscriber.latest_subscription.confirm }
end

def unsubscribes(subscriber, on:)
  travel_to(on) { raise "could not unsubscribe #{subscriber.email_address}" unless subscriber.unsubscribe }
end

def resubscribes(subscriber, on:)
  travel_to(on) { raise "could not resubscribe #{subscriber.email_address}" unless subscriber.subscribe }
end

def drafts(title, pinned: false)
  Post.create!(title: title, slug: unique_slug(title), pinned: pinned, summary: a_lorem_paragraph(minimum: 2, maximum: 3), content: a_lorem_post)
end

def publishes(title:, on:, pinned: false)
  travel_to(on) do
    post = drafts(title, pinned: pinned)
    raise "could not publish '#{title}'" unless post.publish
    post
  end
end

def starts_email_delivery(post)
  raise "could not start email delivery for '#{post.title}'" unless post.start_emails
end

def finishes_email_delivery(post)
  starts_email_delivery(post)
  Post::StartEmailsJob.perform_now(post: post, key: post.start_emails_job_key)
end

def a_fresh_address(email_address)
  local_part, domain = email_address.split("@")
  address = email_address
  attempt = 0

  while Subscriber.exists?(email_address: address)
    attempt += 1
    address = "#{local_part}+#{attempt}@#{domain}"
  end

  address
end

def unique_slug(title)
  root = title.parameterize[0, 42]
  slug = root
  attempt = 0

  while Post.exists?(slug: slug)
    attempt += 1
    slug = "#{root}-#{attempt}"
  end

  slug
end

def random_days_ago(at_least, at_most)
  random_between(at_least, at_most).days.ago
end

def random_between(low, high)
  RNG.rand(low..high)
end

def a_lorem_paragraph(minimum: 5, maximum: 9)
  Array.new(random_between(minimum, maximum)) { LOREM_SENTENCES.sample(random: RNG) }.join(" ")
end

def a_lorem_heading
  "## " + a_phrase_of_lorem(capitalize_each_word: true)
end

def a_lorem_list
  Array.new(3) { "- " + a_phrase_of_lorem }.join("\n")
end

def a_lorem_link
  "[#{a_phrase_of_lorem(capitalize_each_word: true)}](https://example.com)"
end

def a_phrase_of_lorem(capitalize_each_word: false)
  words = Array.new(random_between(2, 9)) { LOREM_WORDS.sample(random: RNG) }
  words = words.map(&:capitalize) if capitalize_each_word
  words.join(" ")
end

def a_lorem_post
  [
    a_lorem_paragraph(minimum: 5, maximum: 6),
    a_lorem_heading,
    a_lorem_paragraph,
    a_lorem_paragraph,
    a_lorem_heading,
    a_lorem_paragraph,
    "**#{a_lorem_paragraph(minimum: 2, maximum: 3)}**",
    a_lorem_list,
    a_lorem_paragraph,
    "#{a_lorem_paragraph(minimum: 3, maximum: 4)} #{a_lorem_link}"
  ].join("\n\n")
end

# Readers first: the completed email delivery builds one PostEmail for every
# reader who is actively subscribed at that moment.

actively_reading = ACTIVELY_READING_EMAILS.map do |email_address|
  signed_up_on = random_days_ago(60, 180)
  reader = signs_up(email_address, on: signed_up_on)
  confirms(reader, on: signed_up_on + 1.day)
  reader
end

# The first of them has the fullest history: subscribed, left, and came back,
# so the admin has a reader with more than one subscription to show.

came_back = actively_reading.first
unsubscribes(came_back, on: 40.days.ago)
resubscribes(came_back, on: 12.days.ago)
confirms(came_back, on: 11.days.ago)

# Four readers have signed up recently and never confirmed.

AWAITING_CONFIRMATION_EMAILS.each do |email_address|
  signs_up(email_address, on: random_days_ago(1, 30))
end

# Two long-time readers eventually left.

LONG_AGO_UNSUBSCRIBED_EMAILS.each do |email_address|
  signed_up_on = random_days_ago(200, 300)
  reader = signs_up(email_address, on: signed_up_on)
  confirms(reader, on: signed_up_on + 2.days)
  unsubscribes(reader, on: random_days_ago(30, 90))
end

# One reader signed up, never confirmed, and gave up.

never_confirmed = signs_up(NEVER_CONFIRMED_EMAIL, on: random_days_ago(2, 20))
unsubscribes(never_confirmed, on: 1.day.ago)

# Posts: eight published across the last three months. The list runs newest
# first, and the newest of them is pinned.

PUBLISHED_TITLES.each_with_index do |title, index|
  publishes(title: title, on: (index * 10 + random_between(0, 6)).days.ago, pinned: index.zero?)
end

DRAFT_TITLES.each do |title|
  drafts(title)
end

# One post sits with emails pending — delivery has started but the delayed
# job has not run, which is the cancellation window the admin can stop from.

pending_emails = publishes(title: PENDING_EMAILS_TITLE, on: 1.day.ago)
starts_email_delivery(pending_emails)

# One delivery has finished, one post email per actively reading subscriber.

delivered_emails = publishes(title: DELIVERED_EMAILS_TITLE, on: 3.days.ago)
finishes_email_delivery(delivered_emails)

puts <<~SAMPLE_DATA_SUMMARY
  Sample records created.

    Posts        #{Post.count} total — #{Post.published.count} published (#{Post.published.where(pinned: true).count} pinned), #{Post.draft.count} drafts
    Email flows  '#{pending_emails.title}' is #{pending_emails.email_status}; '#{delivered_emails.title}' is #{delivered_emails.email_status} with #{delivered_emails.emails.count} post emails
    Subscribers  #{Subscriber.count} total — #{Subscriber.active.count} active, #{Subscriber.pending_confirmation.count} awaiting confirmation, #{Subscriber.unsubscribed.count} unsubscribed
SAMPLE_DATA_SUMMARY
