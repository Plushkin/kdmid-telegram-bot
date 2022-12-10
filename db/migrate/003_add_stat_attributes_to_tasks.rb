class AddStatAttributesToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :in_progress_at, :datetime
    add_column :tasks, :last_success_checked_at, :datetime
    add_column :tasks, :success_checks_count, :integer, default: 0
    add_column :tasks, :failed_checks_count, :integer, default: 0
  end
end
