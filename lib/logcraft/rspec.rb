# frozen_string_literal: true

require 'logging'
require 'rspec/logging_helper'
require_relative 'rspec/helpers'
require_relative 'rspec/matchers'
require_relative 'log_layout'

RSpec.configure do |config|
  config.include Ezlog::RSpec::Helpers
  config.before(:suite) do
    Logging.appenders.string_io('__logcraft_stringio__', layout: Logging.logger.root.appenders.first&.layout || Logcraft::LogLayout.new)
    config.capture_log_messages to: '__logcraft_stringio__'
  end
end
