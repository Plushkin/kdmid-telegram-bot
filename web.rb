require './lib/boot'

require 'sinatra'

set :bind, '0.0.0.0'
set :port, 3000
$stdout.sync = true

if ENV.fetch('APP_ENV') == 'production'
  use Rack::Auth::Basic do |username, password|
    username == ENV['basic_auth_username'] && password == ENV['basic_auth_password']
  end
end

get '/' do
  @stat = Services::Stat.call.result
  erb :index
end
