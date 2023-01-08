require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

require 'telegram/bot'
require 'aasm'
require 'bugsnag'
require 'faraday/follow_redirects'

require './lib/message_responder'
require './lib/app_configurator'
require './lib/services/application_service'
require './lib/services/checker_tasks/create'
require './lib/services/checker_tasks/cancel'
require './lib/services/stat'
require './lib/queue_checker'

$config = AppConfigurator.new
$config.configure

$logger = $config.get_logger

ENV['RACK_ENV'] = ENV.fetch('APP_ENV')
