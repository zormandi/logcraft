# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('../test-app/config/environment', __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.before :all, type: :request do
    host! 'localhost'
  end
end

