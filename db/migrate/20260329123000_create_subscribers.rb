class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email_address, null: false

      t.timestamps
    end

    add_index :subscribers, :email_address, unique: true
  end
end
