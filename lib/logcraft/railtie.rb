# frozen_string_literal: true

require 'rails/railtie'

module Logcraft
  class Railtie < ::Rails::Railtie
    config.logcraft = ActiveSupport::OrderedOptions.new
    config.logcraft.initial_context = {}
    config.logcraft.layout_options = {}

    config.logcraft.access_log = ActiveSupport::OrderedOptions.new
    config.logcraft.access_log.logger_name = 'AccessLog'
    config.logcraft.access_log.exclude_paths = []
    config.logcraft.access_log.log_only_whitelisted_params = false
    config.logcraft.access_log.whitelisted_params = [:controller, :action]

    initializer 'logcraft.configure_logging' do |app|
      log_layout = Logcraft::LogLayout.new app.config.logcraft.initial_context,
                                           app.config.logcraft.layout_options
      Logging.logger.root.appenders = Logging.appenders.stdout layout: log_layout
      Logging.logger.root.level = app.config.log_level
    end

    initializer 'ezlog.configure_rails_middlewares' do |app|
      app.config.middleware.insert_before ::Rails::Rack::Logger,
                                          Logcraft::Rails::RequestLogger,
                                          Logcraft.logger(config.logcraft.access_log.logger_name),
                                          config.logcraft.access_log
      app.config.middleware.delete ::Rails::Rack::Logger
    end

    config.after_initialize do
      case ::Rails::VERSION::MAJOR
      when 5
        Logcraft::Rails::LogSubscriptionHandler.detach ::ActionController::LogSubscriber
        Logcraft::Rails::LogSubscriptionHandler.detach ::ActionView::LogSubscriber
      else
        ::ActionController::LogSubscriber.detach_from :action_controller
        if defined? ::ActionView
          require 'action_view/log_subscriber' unless defined? ::ActionView::LogSubscriber
          ::ActionView::LogSubscriber.detach_from :action_view
        end
      end
    end

    config.before_configuration do |app|
      app.config.logger = Logcraft.logger 'Application'
      app.config.log_level = ENV['LOG_LEVEL'] || :info
    end
  end
end
