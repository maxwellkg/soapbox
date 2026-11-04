# Application Overview

## The author and blog are singletons

Soapbox is a self-hosted publication for one author operating a single blog. `Blog` and `Author` are both implemented using `ActiveRecord` but include special design to enforce that there ever only be one instance of the class. The singleton methods `instance`, `instance!`, and `instance?` make that rule explicit to callers. The `authors` and `blogs` tables also have a `singleton_guard` column constrained to `true` and protected by a unique index.

## The blog's site image

The site image is the blog's visual identity and is displayed in the website header beside the blog title and as the favicon and Apple touch icon shown by browsers and devices.

The image is stored as a single Active Storage attachment on [`Blog`](../app/models/blog.rb). Soapbox does not store separate files for these uses; each one asks Active Storage for an appropriately sized copy of the original, so changing the site image updates every place it appears. When no site image has been attached, the favicon falls back to the packaged `icon.png`.

The blog edit form has a field for choosing a new image. Once an image is attached, the form also shows a "Remove current site image" checkbox; checking it and saving deletes the stored file. The form's `accept: "image/*"` hint only guides the browser's file picker; Soapbox does not validate the file's content type or size.

## Themes

Themes contain the visual design for the site. Different themes make the blog look different while keeping the same content, structure, and features.

The application is built on a shared design system defined by its HTML and base stylesheets:

- `base.css` defines typography, spacing, and layout.
- `application.css` styles web content and controls.
- `posts.css` styles the blog and its posts.
- `markdown_editor.css` styles the House editor.
- `actiontext.css` styles the Trix editor.
- `mailer.css` contains styles that are safe to use in email.

Each theme file, such as `themes/terminal.css` or `themes/editorial.css`, applies its own visual identity to that design system. It defines the theme's fonts and colors using shared names such as `--link`, `--paper`, and `--font-ui`. It is also the place for any CSS overrides specific to that theme.

Every theme must define the same set of shared values. `ThemePaletteTest` checks this. To add a theme, create a new theme file, provide all of those values, and add any design-system overrides the theme requires.

Browsers understand CSS custom properties directly. A stylesheet can use a property before the theme defines its value because the browser resolves it when applying the styles.

Email requires some extra processing. Premailer prepares an email for delivery by taking its stylesheets and copying the relevant styles directly into the HTML. Most email clients do not understand CSS custom properties, and Premailer would otherwise copy references such as `var(--link)` into the HTML without resolving them.

To prevent that, `ThemeCSSLoader` runs before Premailer's standard stylesheet loaders. It replaces each custom property reference with the actual value from the blog's current theme. Premailer then receives ordinary CSS values that it can safely inline into the email.

Premailer normally caches stylesheets by URL. We have turned that cache off because the active theme can change while the application is running. A cached stylesheet could therefore contain values from the wrong theme. Resolving the few kilobytes of CSS again for each message adds little work compared with inlining the email's styles.

Theme files may also import web fonts. Browsers load those fonts normally. Premailer removes the imports from emails because it receives the CSS without the theme file's location and therefore cannot resolve their URLs.

## Setup

The blog is not operational before the singleton records for blog and author exist. This prevents public pages and mailers from operating with no publication identity or owner.

Prior to setup, visitors to the site will see a message indicating "there's nothing here yet". The author must set up the site by calling `bin/kamal site_setup` in a production environment or `bin/rails site:setup` in a development environment. This script will walk the author through the process of creating the necessary records to get the blog up and running. The blog description and site image are not part of setup completeness. They can be added later through the admin area without blocking the site.

## Author access

The application has one user: the author. Signing in as that person is the whole access-control story&mdash;there are no roles and no per-resource checks, because a single-owner blog has no second person to distinguish. Controllers require authentication by default, and a controller exposes something public by opting out with `allow_unauthenticated_access`: post pages, the feed, signup, confirmation, unsubscribe, sign-in, password reset, and retrieval of files embedded in Markdown.

Signing in creates a persisted `Session` recording the request's user agent and IP address, and stores its ID in a permanent signed, HTTP-only, SameSite=Lax cookie ([`Authentication`](../app/controllers/concerns/authentication.rb)). A protected request visited while signed out remembers its URL, so the author returns there after signing in.

Sign-in and password-reset requests are limited to ten attempts in three minutes, and a password-reset request answers the same whether or not the address exists. A successful password change destroys every session, forcing reauthentication everywhere.

## Public and administrative request surfaces

The public surface exposes published posts, the Atom feed, subscription signup and lifecycle links, authentication, and public retrieval of files embedded in Markdown.

The administrative surface manages the singleton author and blog, posts and their publication and email states, and subscribers. Publication, unpublication, starting email, and stopping email are separate commands rather than attributes accepted by the ordinary post form.


## Production data topology

Soapbox runs on a single host. Everything durable lives under `/rails/storage`: the application database, separate SQLite files for Solid Cache, Queue, and Cable, and the files Active Storage has uploaded. The supplied Kamal configuration mounts that directory as one volume, so records, queued jobs, and uploads survive a deploy together.

Background jobs run inside the web process by default, through `SOLID_QUEUE_IN_PUMA`. Every outgoing email is queued work, so mail stops whenever the web process is not running.
