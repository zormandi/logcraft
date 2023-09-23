# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

def add_logcraft_options_to_application_configuration
  project_root = File.dirname __FILE__
  Dir.chdir(project_root + '/spec') do
    app_config = File.readlines 'test-app/config/application.rb'
    modified_config = app_config.each_with_object([]) do |line, config|
      config << line
      if line.include? 'config.load_defaults'
        logcraft_config = File.readlines 'fixtures/test-app/config/logcraft_config.rb'
        config.concat logcraft_config
      end
    end
    File.write 'test-app/config/application.rb', modified_config.join
  end
end

def remove_sprockets_configuration_for_rails7_compatibility
  project_root = File.dirname __FILE__
  Dir.chdir(project_root + '/spec/test-app') do
    FileUtils.rm_rf 'config/initializers/assets.rb'
    app_config = File.readlines 'config/environments/development.rb'
    modified_config = app_config.each_with_object([]) do |line, config|
      config << line unless line.include? 'config.assets'
    end
    File.write 'config/environments/development.rb', modified_config.join
  end
end

desc 'Generate sample Rails app for acceptance testing'
task :generate_rails_app do
  project_root = File.dirname __FILE__
  Dir.chdir(project_root + '/spec') do
    FileUtils.rm_rf 'test-app'
    system 'rails new test-app --database=sqlite3 --skip-gemfile --skip-git --skip-keeps'\
           '--skip-action-mailbox --skip-action-text --skip-active-storage --skip-puma --skip-action-cable'\
           '--skip-sprockets --skip-spring --skip-listen --skip-javascript --skip-turbolinks --skip-jbuilder --skip-test'\
           '--skip-system-test --skip-bootsnap --skip-bundle --skip-webpack-install'
    FileUtils.cp_r 'fixtures/test-app/.', 'test-app', remove_destination: true
    add_logcraft_options_to_application_configuration
    remove_sprockets_configuration_for_rails7_compatibility
  end
end

namespace :spec do
  desc 'Run RSpec unit tests'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.exclude_pattern = 'spec/integration/*_spec.rb'
  end

  desc 'Run RSpec integration tests'
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/*_spec.rb'
  end
end

desc 'Run all RSpec examples'
task spec: [:'spec:unit', :'spec:integration']

task default: :spec
