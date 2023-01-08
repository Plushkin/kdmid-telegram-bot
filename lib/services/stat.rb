module Services
  class Stat < ApplicationService
    def perform
      @result = {}
      tasks_by_subdomain = Task.active.group(:subdomain).count

      tasks_by_subdomain.each do |subdomain, count|
        task = Task.active.where(subdomain: subdomain).order(created_at: :desc).first

        @result[subdomain] = {
          count: count,
          created_at: task.created_at,
          updated_at: task.updated_at,
          started_at: task.in_progress_at,
          last_success_checked_at: task.last_success_checked_at,
          success_checks_count: task.success_checks_count,
          failed_checks_count: task.failed_checks_count
        }
      end
    end
  end
end
