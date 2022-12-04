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
      raise 'Params invalid' if [subdomain, order_id, code].any?(&:nil?)
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
      task = Task.active.where(subdomain: subdomain, order_id: order_id, code: code)
      if task.exists?
        $logger.info "[Same task] #{task.inspect}"
        return
      end

      user.tasks.create!(subdomain: subdomain, order_id: order_id, code: code)
    end

  end
end
