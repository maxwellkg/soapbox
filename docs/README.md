# Technical Documentation

These documents explain how Soapbox works for people maintaining or customizing the application.

The [Soapbox user guide](https://docs.mgove.dev/2/soapbox) separately covers installation, deployment, first-time setup, and using the application as an author. The documents in this directory do not repeat that guidance.

## Application

- [Application overview](application-overview.md) explains the blog and author records, authentication, application setup, and other configuration details.
- [Publishing](publishing.md) explains posts, publication and display rules, email delivery, and Atom feed behavior.
- [Readership](readership.md) explains subscriber identity, subscription history, confirmation, and unsubscribe behavior.

## Libraries

These documents describe the custom libraries the application includes, rather than Soapbox's own behavior.

- [ActionText::Markdown](libraries/action-text-markdown.md) explains Markdown storage, rendering, sanitization, uploads, and plain-text conversion.
- [Searchable](libraries/searchable.md) explains the two search interfaces, the shared full-text index, and how the index is maintained.
