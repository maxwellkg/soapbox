class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.boolean :pinned, null: false, default: false

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_check_constraint :posts, "status IN ('draft', 'published')", name: "posts_status_check"
    add_check_constraint :posts,
                         "((status = 'published' AND published_at IS NOT NULL) OR (status = 'draft' AND published_at IS NULL))",
                         name: "posts_status_published_at_consistency"
  end
end
