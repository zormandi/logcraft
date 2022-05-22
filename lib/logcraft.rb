# frozen_string_literal: true

require 'logging'

require 'logcraft/version'
require 'logcraft/railtie'

module Logcraft
  autoload :LogContextHelper, 'logcraft/log_context_helper'
  autoload :LogLayout, 'logcraft/log_layout'
  autoload :Rails, 'logcraft/rails'

  extend LogContextHelper

  def self.logger(name, level = :info)
    Logging::Logger[name].tap { |logger| logger.level = level }
  end
end
