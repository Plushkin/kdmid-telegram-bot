require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

require 'telegram/bot'
require 'aasm'

require './lib/message_responder'
require './lib/app_configurator'
require './lib/checker_tasks/create'
require './lib/queue_checker'

$config = AppConfigurator.new
$config.configure

$logger = $config.get_logger
