# frozen_string_literal: true

require 'logging'
require_relative "logcraft/version"

module Logcraft
  autoload :LogLayout, 'logcraft/log_layout'

  def self.logger(name)
    ::Logging::Logger[name]
  end
end
