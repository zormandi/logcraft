# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc 'Generate sample Rails app for acceptance testing'
task :generate_rails_app do
  project_root = File.dirname __FILE__
  Dir.chdir(project_root + '/spec') do
    FileUtils.rm_rf 'test-app'
    system 'rails new test-app --database=sqlite3 --skip-gemfile --skip-git --skip-keeps --skip-action-mailer'\
           '--skip-action-mailbox --skip-action-text --skip-active-job --skip-active-storage --skip-puma --skip-action-cable'\
           '--skip-sprockets --skip-spring --skip-listen --skip-javascript --skip-turbolinks --skip-jbuilder --skip-test'\
           '--skip-system-test --skip-bootsnap --skip-bundle --skip-webpack-install'
    FileUtils.cp_r 'fixtures/test-app/.', 'test-app', remove_destination: true
  end
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
