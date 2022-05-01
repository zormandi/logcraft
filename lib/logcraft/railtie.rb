# frozen_string_literal: true

require 'rails/railtie'

module Logcraft
  class Railtie < Rails::Railtie
    config.logcraft = ActiveSupport::OrderedOptions.new
    config.logcraft.initial_context = {}
    config.logcraft.layout_options = {}

    initializer 'logcraft.configure_logging' do |app|
      log_layout = Logcraft::LogLayout.new app.config.logcraft.initial_context,
                                           app.config.logcraft.layout_options
      Logging.logger.root.appenders = Logging.appenders.stdout layout: log_layout
      Logging.logger.root.level = app.config.log_level
    end

    config.before_configuration do |app|
      app.config.logger = Logcraft.logger 'Application'
      app.config.log_level = ENV['LOG_LEVEL'] || :info
    end
  end
end
