class AddThemeToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :theme, :string, default: "terminal", null: false
    add_check_constraint :blogs, "theme IN ('terminal', 'editorial')", name: "blogs_theme_supported"
  end
end
