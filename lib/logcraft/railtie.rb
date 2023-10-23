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
      require 'logcraft/rails/extensions'
      app.config.middleware.insert_before ::Rails::Rack::Logger,
                                          Logcraft::Rails::RequestLogger,
                                          Logcraft.logger(config.logcraft.access_log.logger_name),
                                          config.logcraft.access_log
      app.config.middleware.delete ::Rails::Rack::Logger
      app.config.middleware.insert_after ::ActionDispatch::RequestId, Logcraft::Rails::RequestIdLogger
    end

    config.after_initialize do
      Logcraft::Rails::LogSubscriptionHandler.detach ::ActionController::LogSubscriber, :action_controller
      require 'action_view/log_subscriber' unless defined? ::ActionView::LogSubscriber
      Logcraft::Rails::LogSubscriptionHandler.detach ::ActionView::LogSubscriber, :action_view
      if defined? ::ActiveRecord
        Logcraft::Rails::LogSubscriptionHandler.detach ::ActiveRecord::LogSubscriber, :active_record
        Logcraft::Rails::LogSubscriptionHandler.attach Logcraft::Rails::ActiveRecord::LogSubscriber, :active_record
      end
    end

    config.before_configuration do |app|
      app.config.logger = if defined? ActiveSupport::BroadcastLogger
                            ActiveSupport::BroadcastLogger.new Logcraft.logger('Application')
                          else
                            Logcraft.logger 'Application'
                          end
      app.config.log_level = ENV['LOG_LEVEL'] || :info
    end
  end
end
