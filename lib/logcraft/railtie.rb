# frozen_string_literal: true

require 'rails/railtie'

module Logcraft
  class Railtie < ::Rails::Railtie
    config.logcraft = ActiveSupport::OrderedOptions.new
    config.logcraft.global_context = {}
    config.logcraft.layout_options = ActiveSupport::OrderedOptions.new

    config.logcraft.access_log = ActiveSupport::OrderedOptions.new
    config.logcraft.access_log.logger_name = 'AccessLog'
    config.logcraft.access_log.exclude_paths = []
    config.logcraft.access_log.log_only_whitelisted_params = false
    config.logcraft.access_log.whitelisted_params = [:controller, :action]

    config.logcraft.unhandled_errors = ActiveSupport::OrderedOptions.new
    config.logcraft.unhandled_errors.log_level = :fatal
    config.logcraft.unhandled_errors.log_errors_handled_by_rails = true

    initializer 'logcraft.initialize' do |app|
      Logcraft.initialize log_level: app.config.log_level,
                          global_context: app.config.logcraft.global_context,
                          layout_options: app.config.logcraft.layout_options
    end

    initializer 'logcraft.configure_rails' do |app|
      require 'rails_extensions/action_dispatch/debug_exceptions'
      app.config.middleware.insert_before ::Rails::Rack::Logger,
                                          Logcraft::Rails::RequestLogger,
                                          Logcraft.logger(config.logcraft.access_log.logger_name),
                                          config.logcraft.access_log
      app.config.middleware.delete ::Rails::Rack::Logger
      app.config.middleware.insert_after ::ActionDispatch::RequestId, Logcraft::Rails::RequestIdLogger
    end

    config.before_configuration do |app|
      app.config.logger = if defined? ActiveSupport::BroadcastLogger
                            ActiveSupport::BroadcastLogger.new Logcraft.logger('Application')
                          else
                            Logcraft.logger 'Application'
                          end
      app.config.log_level = ENV['LOG_LEVEL'] || :info
    end

    config.after_initialize do
      detach_rails_log_subscribers
      attach_logcraft_log_subscribers
    end

    private

    def self.detach_rails_log_subscribers
      ::ActionController::LogSubscriber.detach_from :action_controller
      require 'action_view/log_subscriber' unless defined? ::ActionView::LogSubscriber
      ::ActionView::LogSubscriber.detach_from :action_view
      ::ActiveRecord::LogSubscriber.detach_from :active_record if defined? ::ActiveRecord
    end

    def self.attach_logcraft_log_subscribers
      Logcraft::Rails::ActiveRecord::LogSubscriber.attach_to :active_record if defined? ::ActiveRecord
    end
  end
end
