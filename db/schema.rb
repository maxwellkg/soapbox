# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_31_120000) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index [ "record_type", "record_id", "name" ], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.boolean "singleton_guard", default: true, null: false
    t.datetime "updated_at", null: false
    t.index [ "singleton_guard" ], name: "index_authors_on_singleton_guard", unique: true
    t.check_constraint "singleton_guard = 1", name: "authors_singleton_guard_true"
  end

  create_table "blogs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "singleton_guard", default: true, null: false
    t.text "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index [ "singleton_guard" ], name: "index_blogs_on_singleton_guard", unique: true
    t.check_constraint "singleton_guard = 1", name: "blogs_singleton_guard_true"
  end

  create_table "post_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.integer "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "post_id", "subscription_id" ], name: "index_post_emails_on_post_id_and_subscription_id", unique: true
    t.index [ "post_id" ], name: "index_post_emails_on_post_id"
    t.index [ "subscription_id" ], name: "index_post_emails_on_subscription_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_status", default: "not_started", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "start_emails_job_key"
    t.string "status", default: "draft", null: false
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.index [ "slug" ], name: "index_posts_on_slug", unique: true
    t.index [ "start_emails_job_key" ], name: "index_posts_on_start_emails_job_key", unique: true
    t.check_constraint "((status = 'published' AND published_at IS NOT NULL) OR (status = 'draft' AND published_at IS NULL))", name: "posts_status_published_at_consistency"
    t.check_constraint "(email_status = 'not_started' AND start_emails_job_key IS NULL) OR start_emails_job_key IS NOT NULL", name: "posts_email_status_job_key_consistency"
    t.check_constraint "NOT (email_status = 'pending' AND status <> 'published')", name: "posts_pending_email_requires_published"
    t.check_constraint "email_status IN ('not_started', 'pending', 'initiated')", name: "posts_email_status_check"
    t.check_constraint "status IN ('draft', 'published')", name: "posts_status_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index [ "author_id" ], name: "index_sessions_on_author_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "updated_at", null: false
    t.index [ "email_address" ], name: "index_subscribers_on_email_address", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.date "start_date"
    t.integer "subscriber_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "subscriber_id" ], name: "index_subscriptions_on_subscriber_id"
    t.index [ "subscriber_id" ], name: "index_subscriptions_on_subscriber_id_when_active", unique: true, where: "active = 1"
    t.check_constraint "active = 0 OR end_date IS NULL", name: "subscriptions_active_requires_blank_end_date"
    t.check_constraint "active = 0 OR start_date IS NOT NULL", name: "subscriptions_active_requires_start_date"
    t.check_constraint "end_date IS NULL OR start_date IS NULL OR end_date >= start_date", name: "subscriptions_end_date_after_start_date"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "post_emails", "posts"
  add_foreign_key "post_emails", "subscriptions"
  add_foreign_key "sessions", "authors"
  add_foreign_key "subscriptions", "subscribers"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "search_index_entries", "fts5", [ "indexable_type UNINDEXED", "indexable_id UNINDEXED", "field UNINDEXED", "content", "tokenize = 'porter'" ]
end
