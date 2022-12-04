class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks, force: true do |t|
      t.integer :status, default: 0, null: false
      t.belongs_to :user, null: false, foreign_key: true
      t.string :url
      t.string :subdomain, limit: 20
      t.string :order_id, limit: 20
      t.string :code, limit: 20

      t.timestamps
    end
  end
end
