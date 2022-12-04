module CheckerTasks
  class Create

    KDMID_URL_REGEXP = /^https?:\/\/(.+)\.kdmid\.ru\/queue\/OrderInfo\.aspx\?id=(.+)&cd=(.+)/
    attr_reader :url, :user

    def initialize(url:, user:)
      @url = url.strip
      @user = user
    end

    def call
      subdomain, order_id, code = task_params
      create_task(subdomain, order_id, code)
    end

    private

    def task_params
      matches = url.match(KDMID_URL_REGEXP)
      subdomain, order_id, code = matches.to_a.slice(1, 3)
      $logger.info "[New task] subdomain: #{subdomain} order_id: #{order_id} code: #{code}"
      [subdomain, order_id, code]
    end

    def create_task(subdomain, order_id, code)
      active_tasks = Task.where(subdomain: subdomain).active
      if active_tasks.exists?
        $logger.info "[Active tasks] #{active_tasks.inspect}"
        return
      end

      user.tasks.create!(subdomain: subdomain, order_id: order_id, code: code)
    end

  end
end
