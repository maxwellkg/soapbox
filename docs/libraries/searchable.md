# Searchable

`Searchable` is an internal library for adding search to a Rails application backed by SQLite. The point is to make adding search as simple as adding a line to a model. No external search service. No new index table for each searchable model. No migration every time you want to search another field. One line of model code, backed by a single search table and index model shared across every searchable model.

For small applications&mdash;which is to say most applications&mdash;that single table is sufficient, and the reduction in setup and maintenance is meaningful.

The library is experimental. It is not a stable API and is likely to change.

## Two Interfaces, One Syntax

A model can be made searchable by including `Searchable::Model`. `Searchable::Model` includes two interfaces: `Searchable::Basic` and `Searchable::FullText`.

The two interfaces declare search methods in the same way. They create methods on the model that can be called to perform the search. These methods are prefixed with `search_`, followed by the search name. Each takes a single search term and returns a relation of the records matching it. An empty term returns the relation unfiltered, so a listing needs no special case for a search box nobody has typed into.

A search against a single attribute can be declared using `basic_search_on` or `full_text_search_on` with the attribute name as the first argument; alternatively the `as:` argument can be passed to produce a search method with a different name than the attribute. For example, `basic_search_on :email_address` would produce a search method `search_email_address` against the `email_address` column. `basic_search_on :email_address, as: :email` would produce `search_email`, still against the column `email_address`.

A search against multiple attributes is declared using the method name and a list of attributes passed to the `on:` argument. This will result in a search method on the class with the method name. For example `full_text_search :title_and_body, on: %i[ title body ]` produces a search method `search_title_and_body`.

### Basic Search

Basic search declares a search method that takes a search term and looks for an Arel match (in SQLite, this uses case-insensitive `LIKE`) on one or more columns. When a value is likely quickly identifiable by a substring, this is the interface to use ([`Searchable::Basic`](../../lib/searchable/basic.rb)).

For example:

```ruby
class Subscriber
  basic_search :email, on: :email_address
end
```

will create a search method `search_email` that executes SQL equivalent to

```sql
SELECT *
FROM subscribers
WHERE email_address LIKE '%[search term]%' ESCAPE '\'
```

The term is wrapped on both sides, so it is found anywhere inside the value: `Subscriber.search_email("mgove.dev")` finds `maxwell@mgove.dev`. Declaring more than one column in `on:` joins the conditions with `OR`, so `basic_search :author, on: %i[ first_name last_name ]` matches a record whose first name or last name contains the term.

This can be simplified using `basic_search_on` when the method should take the column's own name. `basic_search_on :email_address` is exactly `basic_search :email_address, on: :email_address`.

Because `%` and `_` are wildcards in a `LIKE` pattern — any run of characters and any single character, respectively — they are escaped before the term is wrapped, and the condition declares `\` as its escape character so that escaping takes effect. A term of `reader_one` therefore finds `reader_one@example.com` and not `reader.one@example.com`, which the wildcard `_` would have caught by reading the period as the one character it stands for.

Because basic search queries the model's table directly, every attribute it declares must be backed by a database column.

### Full-Text Search

Full-text search declares the same kind of method, but the term is matched against text stored in an index rather than against the model's own columns. Use full-text search when a simple substring search is likely to be insufficient or inefficient, for example searching across large amounts of and/or large numbers of records.

The index gets its own model, [`Searchable::IndexEntry`](../../lib/searchable/index_entry.rb)&mdash;backed by the `search_index_entries` table&mdash;that is used as a shared search index across all searchable models. `search_index_entries` is an SQLite FTS5 virtual table created by [`CreateSearchIndexEntries`](../../db/migrate/20260331120000_create_search_index_entries.rb). In it, a row stores a record identifier (represented polymorphically by `indexable_type` and `indexable_id`) an attribute identifier (`field`), and the content (`content`) that will be searched. [`Searchable::FullText`](../../lib/searchable/full_text.rb) gives each searchable model a `has_many :search_index_entries` association to those rows, and the text is copied into them when the record saves.

For example:

```ruby
class Post
  full_text_search :title_summary_and_content, on: %i[ title plain_text_summary plain_text_content ]
end
```

will create a search method `search_title_summary_and_content` that executes SQL equivalent to

```sql
SELECT DISTINCT posts.*
FROM posts
INNER JOIN search_index_entries
  ON search_index_entries.indexable_type = 'Post'
  AND search_index_entries.indexable_id = posts.id
WHERE search_index_entries.field IN ('title', 'plain_text_summary', 'plain_text_content')
  AND search_index_entries MATCH '"[search term]"'
ORDER BY rank
```

In this query:

* The join is on `indexable_type` and `indexable_id`, so a search sees only the rows belonging to its own model.
* `field IN` restricts matching to the attributes that this method declared, so searching titles never reaches into body text.
* `MATCH` is SQLite's full-text operator, and it is what supplies both stemming and relevance. The library wraps the term in double quotes and doubles any quotes the reader typed, so input is matched as text rather than as search syntax — which also means a multi-word term is matched as a phrase, the words together in the given order: `"good morning"` finds a post containing that phrase, `"morning good"` finds nothing. The Porter tokenizer declared on the table softens word form: `reading` also finds `read`, and `errand` also finds `errands`.
* `rank` orders matches by relevance, and a caller can pass a different `order:` when a listing needs its own ordering to lead.
* `DISTINCT` returns a record once even when more than one of its declared fields matches.

The singular shorthand works here as it does for basic search. `full_text_search_on :title` is exactly `full_text_search :title, on: :title`, and `as:` renames the method without changing what gets indexed: `full_text_search_on :plain_text_content, as: :content` gives `Post.search_content` while the index rows keep the field name `plain_text_content`.

Because full-text search creates separate index records, it does not share the restriction basic search has that attributes must be database-backed. In fact, full text search can substitute true attributes for the results of any plain Ruby method as readily as a column (note: doing so would also require instituting a `changed?` method corresponding to that method).

#### Keeping the Index Current

The index automatically updates as records are saved via callbacks. After a record is created or updated, any indexed fields that have been changed have their corresponding `IndexEntry` records deleted and rewritten (see [`Searchable::FullText::Indexing`](../../lib/searchable/full_text/indexing.rb)). Destroying a record removes its rows through `dependent: :delete_all` on the association rather than through a reindex callback. No caller has to remember to reindex.

Rebuilding is driven by change detection; on save, the library asks each indexed field whether it changed by calling `saved_change_to_<field>?`. Attributes on the model will automatically include these methods via `ActiveRecord` and `ActiveModel`. A derived method or an `ActionText` field will not have these change methods out of the box, so the model must supply one.

For example, imagine a class `Post` has actiontext content `content`. It then implements a method `plain_text_content` to get the plain-text content to use in the search index. It must then also define `saved_change_to_plain_text_content?` so that the index can automatically be updated on that field.

```ruby
class Post
  has_rich_text :content

  def plain_text_content
    content.to_plain_text
  end

  def saved_change_to_plain_text_content?
    content.saved_change_to_content?
  end
end
```

A model that declares full-text fields can call `reindex_all!` on the class to force a rebuild of the index entries for each of its instances. `Searchable.reindex_all!` does the same across every model that declares full-text fields; a model using basic search only has no index to rebuild.

This can also be invoked via `bin/rake search:reindex_all` ([`search.rake`](../../lib/tasks/search.rake)). It's recommended this be run after making changes related to search configuration.


#### Implementation Detail

The index table is specifically a virtual table, and the Rails code therefore makes several accommodations that are important to be aware of. Virtual tables' rows have no `id` column; identity is SQLite's `rowid`, which `SELECT *` leaves out. However, Rails expects a primary key, so the index model explicitly declares it to be `rowid`, adds it to its default select, and removes it from count queries (otherwise `rowid` interferes with aggregation) ([`UnscopedCount`](../../lib/searchable/index_entry/unscoped_count.rb)). Search queries unscope that select before merging index rows into the model's relation, to avoid an ambiguous rowid in the joined SQL.

Both the index table and the `MATCH` operator belong to SQLite, so the full-text interface is tied closely to sqlite. Basic search, which goes through Arel, is not.
