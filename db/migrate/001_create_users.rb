class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, force: true do |t|
      t.integer :uid
      t.string :username
      t.string :chat_id

      t.timestamps
    end
  end
end
