module Services
  module CheckerTasks
    class Cancel < ApplicationService

      attr_reader :user

      def initialize(user:)
        @user = user
      end

      private

      def perform
        delete_task
      end

      def delete_task
        task = user.tasks.where(status: %i[created in_progress stopped]).order(:id).first
        unless task
          @result = false
          return
        end

        $logger.info "[Cancel task] #{task.inspect}"
        if task.cancel!
          @result = task.url
        end
      end

    end
  end
end
