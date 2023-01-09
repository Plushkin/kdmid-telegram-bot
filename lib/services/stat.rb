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
      tasks_by_subdomain = Task
        .active
        .group(:subdomain)
        .pluck(Arel.sql('subdomain, COUNT(*), SUM(success_checks_count), SUM(failed_checks_count)'))

      tasks_by_subdomain = tasks_by_subdomain.sort_by { |v| v[1] }.reverse
      tasks_by_subdomain.each do |v|
        subdomain, count, success_checks_count, failed_checks_count = v
        task = Task.active.where(subdomain: subdomain).order(updated_at: :desc).first

        last_success_checked_at = task.last_success_checked_at || Time.now
        minutes_between_update_and_check = (task.updated_at - last_success_checked_at).to_f / 60
        with_issue = minutes_between_update_and_check > 10 || failed_checks_count > success_checks_count

        @result[:subdomains][subdomain] = {
          count: count,
          created_at: task.created_at.in_time_zone('Europe/Istanbul').strftime('%Y-%m-%d %H:%M:%S'),
          updated_at: task.updated_at.in_time_zone('Europe/Istanbul').strftime('%Y-%m-%d %H:%M:%S'),
          started_at: task.in_progress_at&.in_time_zone('Europe/Istanbul')&.strftime('%Y-%m-%d %H:%M:%S'),
          last_success_checked_at: task.last_success_checked_at&.in_time_zone('Europe/Istanbul')&.strftime('%Y-%m-%d %H:%M:%S'),
          success_checks_count: success_checks_count,
          failed_checks_count: failed_checks_count,
          with_issue: with_issue
        }
      end
    end
  end
end
