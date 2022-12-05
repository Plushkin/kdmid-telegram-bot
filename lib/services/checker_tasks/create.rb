module Services
  module CheckerTasks
    class Create < ApplicationService

      KDMID_URL_REGEXP = /^https?:\/\/(.+)\.kdmid\.ru\/queue\/OrderInfo\.aspx\?id=(.+)&cd=(.+)/
      attr_reader :url, :user

      def initialize(url:, user:)
        @url = url.strip
        @user = user
      end

      private

      def perform
        subdomain, order_id, code = task_params
        if [subdomain, order_id, code].any?(&:nil?)
          errors.add(:url, I18n.t('errors.url.invalid'))
          return
        end
        create_task(subdomain, order_id, code)
      end

      def validate_call
        super
        errors.add(:url, I18n.t('errors.url.invalid')) if url.empty?
        errors.add(:url, I18n.t('errors.url.invalid')) if url.length > 255
        # errors.add(:url, I18n.t('errors.url.not_available')) unless url_available?
      end

      def url_available?
        return true if ENV.fetch('APP_ENV') == 'test'

        conn = Faraday.new(url: url) do |connection|
          connection.response :follow_redirects
          connection.options[:open_timeout] = 3
          connection.options[:timeout] = 3
        end
        response = conn.head('/')
        response.success?
      rescue Faraday::ConnectionFailed => e
        $logger.error("#{url} connection failed")
        false
      end

      def task_params
        matches = url.match(KDMID_URL_REGEXP)
        subdomain, order_id, code = matches.to_a.slice(1, 3)
        $logger.info "[New task] subdomain: #{subdomain} order_id: #{order_id} code: #{code}"
        [subdomain, order_id, code]
      end

      def create_task(subdomain, order_id, code)
        task = Task.where(subdomain: subdomain, order_id: order_id, code: code).order(:id).last
        if task.nil? || task.canceled?
          $logger.info "[Create task] #{task.inspect}"
          @result = user.tasks.create(url: url, subdomain: subdomain, order_id: order_id, code: code)
          return
        end

        case
        when task.created? || task.in_progress?
          $logger.info "[Active task] #{task.inspect}"
        when task.stopped?
          $logger.info "[Stopped task] #{task.inspect}"
          @result = task.restart!
        end
      end

    end
  end
end
