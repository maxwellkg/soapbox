# Soapbox

<img src="docs/screenshots/soapbox_logo.png" width="150" alt="Soapbox Logo">

Soapbox is a self-hosted, single-author blogging application built with Ruby on Rails. It gives one person a simple way to run a publication — publish writing on the web, manage the readers who subscribe to it, and send that writing to them by email — in an app you run yourself.

## Status

Soapbox is very much a work in progress. Nothing here is stable yet: APIs, the database schema, and the shape of configuration may all change between versions, and there is no guaranteed upgrade path. If you run Soapbox, plan to follow the repository closely.

## Running Your Own Copy

Soapbox is distributed as a complete Rails application through a [GitHub template repository](https://github.com/maxwellkg/soapbox). Running your own publication means creating a new repository from that template, cloning it, configuring it for your domain, and deploying it yourself.

The supported deployment path is [Kamal](https://kamal-deploy.org/); the repository ships with a Dockerfile and a ready-to-edit `config/deploy.yml`. Other deployment approaches are possible, but the included configuration and documentation only cover Kamal.

A fresh deployment is not a blog yet. Until first-time setup creates the publication's single author and blog records, visitors see a "nothing here yet" page instead of a blog. Running `bin/rails site:setup` — or `bin/kamal site_setup` on a Kamal deployment — walks through creating those records; the blog's rich-text description is finished afterward in the admin area.

## Configuration

A small set of configuration concerns need updating before your application will be ready to deploy.

- **Deployment** — `config/deploy.yml` defines where your publication lives: the server address, the domain and SSL proxy settings, the container registry, and the storage volume.
- **Production URL** — `default_url_options` in `config/environments/production.rb` sets the canonical host and protocol used for links generated in emails and routes. There is intentionally no default: the application refuses to boot in production until you set your public URL, so a placeholder can never reach your readers.
- **Credentials** — secrets live in Rails encrypted credentials, unlocked by `RAILS_MASTER_KEY` (sourced from `config/master.key` via `.kamal/secrets`). This is where the email delivery token belongs.
- **Email delivery** — Soapbox sends through Postmark using the `postmark_api_token` credential, and the sender address is the `default from:` in `app/mailers/application_mailer.rb`. Without working delivery, subscribers receive nothing.
- **Persistent storage** — the SQLite databases and uploaded files live under `/rails/storage` on the `soapbox_storage` volume. That volume holds the entire state of the publication, and it is the thing to back up.

The full documentation covers each of these settings in detail.

## Documentation

For detailed setup, deployment, first-time setup, and author guidance, see the full documentation:

https://docs.mgove.dev/2/soapbox

It covers getting your own copy of the repository, production configuration, first-time setup, and the author guide to posts, subscribers, and settings.

## License

Soapbox is licensed under the MIT License. See [LICENSE](LICENSE) for the full terms.
