class CreatePostEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :post_emails do |t|
      t.references :post, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true

      t.timestamps
    end

    add_index :post_emails, [ :post_id, :subscription_id ], unique: true
  end
end
