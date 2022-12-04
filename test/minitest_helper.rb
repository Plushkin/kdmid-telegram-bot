ENV['APP_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'minitest/hooks/default'

require_relative '../lib/boot'

module MyMinitestPlugin
  def before_setup
    super
    # ... stuff to do before setup is run
  end

  def after_setup
    # ... stuff to do after setup is run
    super
  end

  def before_teardown
    super
    # ... stuff to do before teardown is run
  end

  def after_teardown
    # ... stuff to do after teardown is run
    Task.delete_all
    User.delete_all
    super
  end
end

class MiniTest::Test
  include MyMinitestPlugin
end
