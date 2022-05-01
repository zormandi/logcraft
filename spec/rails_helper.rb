# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('../test-app/config/environment', __FILE__)
require 'rspec/rails'
require 'logging'
require 'rspec/logging_helper'

RSpec.configure do |config|
  config.before :all, type: :request do
    host! 'localhost'
  end

  include RSpec::LoggingHelper
  config.before(:suite) do
    Logging.appenders.string_io('__logcraft_stringio__', layout: Logcraft::LogLayout.new)
    config.capture_log_messages to: '__logcraft_stringio__'
  end
end

