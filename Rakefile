require 'rubygems'
require 'bundler/setup'

require 'pg'
require 'active_record'
require 'yaml'

task :console do
  require 'pry'
  require './lib/boot'

  ARGV.clear
  Pry.start
end

task default: :test
task :test do
  Dir.glob('./test/*_test.rb').each { |file| require file}
end

namespace :db do

  desc 'Migrate the database'
  task :migrate do
    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))
    ActiveRecord::Base.establish_connection(connection_details)

    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrations_paths = 'db/migrate'
    ActiveRecord::Tasks::DatabaseTasks.migrate(ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  task :up do
    raise "VERSION is required" if !ENV["VERSION"] || ENV["VERSION"].empty?

    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))

    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Tasks::DatabaseTasks.check_target_version
    ActiveRecord::Base.connection.migration_context.run(
      :up,
      ActiveRecord::Tasks::DatabaseTasks.target_version
    )
  end

  task :down do
    raise "VERSION is required - To go down one migration, use db:rollback" if !ENV["VERSION"] || ENV["VERSION"].empty?

    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))

    ActiveRecord::Base.establish_connection(connection_details)

    ActiveRecord::Tasks::DatabaseTasks.check_target_version

    ActiveRecord::Base.connection.migration_context.run(
      :down,
      ActiveRecord::Tasks::DatabaseTasks.target_version
    )
  end

  desc "Rollback database for current environment (specify steps w/ STEP=n)."
  task :rollback do
    step = ENV["STEP"] ? ENV["STEP"].to_i : 1
    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))

    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Base.connection.migration_context.rollback(step)
  end

  desc 'Create the database'
  task :create do
    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))
    ActiveRecord::Tasks::DatabaseTasks.create(connection_details)
  end

  desc 'Drop the database'
  task :drop do
    connection_details = ActiveSupport::ConfigurationFile.parse('config/database.yml').fetch(ENV.fetch('APP_ENV'))
    ActiveRecord::Tasks::DatabaseTasks.drop(connection_details)
  end

end
