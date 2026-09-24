class CreateRubyLlmV2Chats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats, id: :bigint do |t|
      t.references :ruby_llm_model, null: false, foreign_key: { to_table: :ruby_llm_models }, type: :bigint
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.string :title
      t.boolean :cancelled, null: false, default: false
      t.timestamps
    end
  end
end
