class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.boolean :pinned, null: false, default: false
      t.string :email_status, null: false, default: "not_started"
      t.string :start_emails_job_key

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_check_constraint :posts, "status IN ('draft', 'published')", name: "posts_status_check"
    add_check_constraint :posts,
                         "((status = 'published' AND published_at IS NOT NULL) OR (status = 'draft' AND published_at IS NULL))",
                         name: "posts_status_published_at_consistency"
    add_check_constraint :posts,
                         "email_status IN ('not_started', 'pending', 'initiated')",
                         name: "posts_email_status_check"
    add_check_constraint :posts,
                         "(email_status = 'not_started' AND start_emails_job_key IS NULL) OR start_emails_job_key IS NOT NULL",
                         name: "posts_email_status_job_key_consistency"
  end
end
