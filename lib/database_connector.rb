require 'active_record'
require 'logger'

class DatabaseConnector
  class << self
    def establish_connection
      ActiveRecord::Base.logger = Logger.new(active_record_logger_path)

      connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))

      ActiveRecord::Base.establish_connection(connection_details)
    end

    private

    def active_record_logger_path
      'debug.log'
    end

    def database_config_path
      'config/database.yml'
    end
  end
end
