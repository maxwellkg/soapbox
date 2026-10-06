# ActionText::Markdown

Soapbox stores authored long-form content as Markdown and renders it on the server for web pages, email, feeds, excerpts, and search. The storage and rendering path is shared so those outputs derive from the same source instead of maintaining separate HTML and text copies.

## Storage

`has_markdown` gives a model a named, autosaved `ActionText::Markdown` record. Posts declare `summary` and `content`; the blog declares `description`. Each value is stored in `action_text_markdowns` through a polymorphic association and is deleted with its owning record.

The macro builds an empty Markdown record when code first reads an unset value. Assignment changes that record's `content`, and autosave persists it with the owner. Changes to a Markdown record touch the owner so post and feed update times reflect content edits.

This is a custom Action Text extension, not Action Text rich text. The application uses Action Text's content conversion where useful, but authored content remains Markdown.

The core of this Markdown implementation is copied from 37signals's [Writebook](https://github.com/basecamp/writebook).

## Rendering

Soapbox converts Markdown into HTML on the server. The same conversion is used when content appears on the website, in email, or in the Atom feed. Excerpts and search indexing also begin with this rendered content before converting it to plain text.

[Redcarpet](https://github.com/vmg/redcarpet) is the Ruby library Soapbox uses to convert Markdown to HTML. Soapbox enables automatic links, fenced code blocks, strikethrough, tables, highlighted text, and relaxed spacing between blocks. [`ActionText::Markdown#to_html`](../../lib/rails_ext/action_text_markdown.rb) is the entry point that passes the stored content to Redcarpet, while [`MarkdownRenderer`](../../lib/markdown_renderer.rb) controls the custom HTML generated for code blocks, headings, and images.

[Rouge](https://github.com/rouge-ruby/rouge) is another Ruby library used to provide syntax highlighting for fenced code blocks. Authors identify the programming language by placing its name immediately after the opening three backticks:

````markdown
```ruby
puts "Hello, world!"
```
````

`MarkdownRenderer` also gives each heading an ID derived from its text and adds a link to that section of the page. If the same heading appears more than once, later headings receive numbered IDs such as `installation-2`.

## Sanitization

Redcarpet allows authors to include raw HTML in Markdown content. After Redcarpet renders the content, [`ActionText::Markdown#to_html`](../../lib/rails_ext/action_text_markdown.rb) passes the resulting HTML through [`HtmlScrubber`](../../app/models/html_scrubber.rb) before returning it. `HtmlScrubber` starts from Rails' allowed tags and adds media, iframe, table, details, and related content tags needed by authored posts.

Sanitization is part of `to_html` so every caller receives the same safe output by default. Web pages, HTML email, the Atom feed, excerpts, and search indexing therefore share one sanitization boundary rather than relying on each caller to remember to apply it.

Plain-text consumers render first and then use `ActionText::Content#to_plain_text`. Post excerpts and full-text search therefore index or display readable text derived from the same Markdown rendering path rather than Markdown punctuation.

## Uploading Files in Markdown

Authors can upload images and other files while editing Markdown. [`ActionText::Markdown::UploadsController`](../../app/controllers/action_text/markdown/uploads_controller.rb) handles the upload and requires the author to be signed in. Active Storage stores the file and attaches it to the specific `ActionText::Markdown` record being edited. The editor receives a public URL for the uploaded file and inserts that URL into the Markdown.

The upload request identifies the post or blog with a signed Global ID and names the Markdown field receiving the file, such as a post's `content`. The signed ID prevents the request from substituting an arbitrary record ID. [`safe_markdown_attribute`](../../lib/rails_ext/action_text_has_markdown.rb) then checks that the named field was actually declared with `has_markdown` before allowing a file to be attached to it.

Each attachment receives a public slug based on its original filename, followed by six random characters and the file extension. For example, `site-diagram.png` might become `site-diagram-A1b2C3.png`. [`ActiveStorage::Sluggable`](../../lib/rails_ext/active_storage_sluggable.rb) creates this slug.

The public URL begins with `/u/`. When that URL is requested, Soapbox finds the attachment by its slug and redirects to the file stored by Active Storage. These URLs are public because uploaded files need to appear wherever the Markdown is published, including the website, email, and Atom feed. Soapbox allows the redirect to be cached publicly for one year.
