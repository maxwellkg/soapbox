class CreateActionTextTables < ActiveRecord::Migration[6.0]
  def change
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :action_text_markdowns, id: primary_key_type do |t|
      t.string :name, null: false
      t.text :content, null: false, default: ""
      t.references :record, null: false, polymorphic: true, index: false, type: foreign_key_type

      t.timestamps

      t.index [ :record_type, :record_id, :name ], name: "index_action_text_markdowns_uniqueness", unique: true
    end
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [ primary_key_type, foreign_key_type ]
    end
end
