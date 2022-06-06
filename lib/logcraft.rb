# frozen_string_literal: true

require 'logging'

require 'logcraft/version'
require 'logcraft/railtie' if defined? Rails

module Logcraft
  autoload :LogContextHelper, 'logcraft/log_context_helper'
  autoload :LogLayout, 'logcraft/log_layout'
  autoload :Rails, 'logcraft/rails'

  extend LogContextHelper

  def self.initialize(log_level: :info, initial_context: {}, layout_options: {})
    Logging.logger.root.appenders = Logging.appenders.stdout layout: LogLayout.new(initial_context, layout_options)
    Logging.logger.root.level = log_level
  end

  def self.logger(name, level = :info)
    Logging::Logger[name].tap { |logger| logger.level = level }
  end
end
