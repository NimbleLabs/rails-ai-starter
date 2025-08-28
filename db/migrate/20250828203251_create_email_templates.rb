class CreateEmailTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :email_templates do |t|
      t.string :subject
      t.text :body
      t.string :send_group
      t.string :slug, index: true
      t.timestamps
    end

    add_column :ahoy_messages, :email_template_id, :integer
  end
end
