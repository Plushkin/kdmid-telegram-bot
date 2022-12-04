require 'logger'

require './lib/database_connector'

class AppConfigurator
  def configure
    setup_i18n
    setup_database
    Bugsnag.configure do |config|
      config.api_key = ENV.fetch('BUGSNAG_KEY')
    end

    at_exit do
      if $!
        Bugsnag.notify($!)
      end
    end
  end

  def get_token
    ENV.fetch('TELEGRAM_BOT_TOKEN')
  end

  def get_logger
    Logger.new(STDOUT, Logger::DEBUG)
  end

  private

  def setup_i18n
    I18n.load_path = Dir['config/locales.yml']
    I18n.locale = :en
    I18n.backend.load_translations
  end

  def setup_database
    DatabaseConnector.establish_connection
  end
end
