# Soapbox

Soapbox is a Ruby on Rails app for running a self-hosted, single-author blog with email delivery. You can write and publish posts on the web, and send those posts to subscribers by email.

## Core models

Soapbox is built around a few core ActiveRecord classes:

- `Post` - the primary content model for drafted and published writing
- `Subscriber` / `Subscription` - the reader list and subscription lifecycle
- `Author` - the owner account that signs in and manages the site
- `Blog` - site identity and metadata (title, subtitle, description)

Because Soapbox is designed to be a single blog with a single author, the `Author` and `Blog` models have special logic to enforce a singleton pattern while still using ActiveRecord. This allows us to store the data from these important models in the database and then access it throughout the application more idiomatically than implementing some special storage pattern.

Architecture notes for singleton behavior, subscription lifecycle, and post email status transitions are documented in `docs/general.md`.

## Production deploy config

Soapbox assumes Kamal deployment.

Before launching in production, set your canonical URL in `config/environments/production.rb` by updating `default_url_options`:

```ruby
default_url_options = { host: "blog.example.com", protocol: "https" }
config.action_mailer.default_url_options = default_url_options
routes.default_url_options = default_url_options
```

In the same file, enable SSL for production traffic:

```ruby
config.force_ssl = true
```

If SSL is terminated by a reverse proxy (common with Kamal + proxy), also enable:

```ruby
config.assume_ssl = true
```

Also set your sender identity in `app/mailers/application_mailer.rb`:

```ruby
default from: "updates@blog.example.com"
```

Important: the `from` address sets sender identity, but it does not configure actual email delivery by itself. You must also configure Action Mailer delivery settings in production (for example, SMTP credentials in production config/credentials) so emails can actually be sent.

## Setup and first run

Before setup is complete, visitors will see:

`there's nothing here yet`

That is expected on a fresh install. Soapbox cannot serve normal content until the required singleton records for `Blog` and `Author` exist.

To bootstrap a fresh environment, create the database and then run `bin/rails site:setup`.

`site:setup` will prompt you in the terminal for the details required to create the author and the blog records. Note that the blog's description is rich text and so cannot be collected via the terminal. Once the setup process is complete, you can log into the admin section of your new blog in order to set the full description at `admin/blog/edit`, if you wish to do so.

## After setup

Once you've completed the setup process, you can sign into the admin area at `/admin` to review blog settings, create and publish your first post, and manually create subscribers.

## Search

Search is used for both posts and subscribers.

The implementation uses a single-table index approach so different searchable records are indexed and queried through one shared index model/table.

Search architecture and behavior are fully documented in `docs/search.md`.

To rebuild all configured search indexes, run `bin/rails search:reindex_all`.

## Further documentation

More in-depth documentation is written in `docs/general.md`, with some topics given their own separate docs in the `/docs` directory.
