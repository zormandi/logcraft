# frozen_string_literal: true

require 'logging'
require 'ostruct'

require 'logcraft/version'
require 'logcraft/railtie' if defined? Rails

module Logcraft
  autoload :LogContextHelper, 'logcraft/log_context_helper'
  autoload :LogLayout, 'logcraft/log_layout'
  autoload :Rails, 'logcraft/rails'

  extend LogContextHelper

  def self.initialize(log_level: :info, global_context: {}, layout_options: {})
    Logging.logger.root.appenders = Logging.appenders.stdout layout: LogLayout.new(global_context, layout_options)
    Logging.logger.root.level = log_level
  end

  def self.logger(name, level = nil)
    Logging::Logger[name].tap do |logger|
      logger.level = level if level
      logger.instance_variable_set :@logdev, OpenStruct.new(dev: STDOUT)
      logger.define_singleton_method :dup do
        super().tap do |logger_copy|
          Logging::Logger.define_log_methods logger_copy
        end
      end
    end
  end
end
