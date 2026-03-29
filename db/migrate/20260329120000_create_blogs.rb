class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs do |t|
      t.string :title, null: false
      t.text :subtitle
      t.boolean :singleton_guard, null: false, default: true

      t.timestamps
    end

    add_index :blogs, :singleton_guard, unique: true
    add_check_constraint :blogs, "singleton_guard = 1", name: "blogs_singleton_guard_true"
  end
end
