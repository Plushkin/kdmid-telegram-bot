module Services
  class Stat < ApplicationService
    def perform
      base_stat
      collect_for_subdomains
      collect_for_tasks
    end

    private

    def base_stat
      @result = { subdomains: {}, users_count: User.count, tasks_count: Task.count }
    end

    def collect_for_tasks
      @result[:tasks] = Task.includes(:user).order(created_at: :desc)
    end

    def collect_for_subdomains
      tasks_by_subdomain = Task.active.group(:subdomain).count

      tasks_by_subdomain = tasks_by_subdomain.sort_by { |v| v[1] }.reverse
      tasks_by_subdomain.each do |v|
        subdomain, count = v
        task = Task.active.where(subdomain: subdomain).order(updated_at: :desc).first

        @result[:subdomains][subdomain] = {
          count: count,
          created_at: task.created_at.in_time_zone('Europe/Istanbul').strftime('%Y-%m-%d %H:%M:%S'),
          updated_at: task.updated_at.in_time_zone('Europe/Istanbul').strftime('%Y-%m-%d %H:%M:%S'),
          started_at: task.in_progress_at&.in_time_zone('Europe/Istanbul')&.strftime('%Y-%m-%d %H:%M:%S'),
          last_success_checked_at: task.last_success_checked_at&.in_time_zone('Europe/Istanbul')&.strftime('%Y-%m-%d %H:%M:%S'),
          success_checks_count: task.success_checks_count,
          failed_checks_count: task.failed_checks_count
        }
      end
    end
  end
end
