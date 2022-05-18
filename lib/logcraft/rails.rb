# frozen_string_literal: true

require 'action_controller'
require 'action_controller/log_subscriber'

module Logcraft
  module Rails
    autoload :LogSubscriptionHandler, 'logcraft/rails/log_subscription_handler'
  end
end
