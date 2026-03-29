class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.boolean :singleton_guard, null: false, default: true

      t.timestamps
    end

    add_index :authors, :singleton_guard, unique: true
    add_check_constraint :authors, "singleton_guard = 1", name: "authors_singleton_guard_true"
  end
end
