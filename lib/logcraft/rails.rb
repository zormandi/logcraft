# frozen_string_literal: true

require 'action_controller'
require 'action_controller/log_subscriber'

module Logcraft
  module Rails
    autoload :ActionController, 'logcraft/rails/action_controller'
    autoload :ActiveRecord, 'logcraft/rails/active_record'
    autoload :RequestIdLogger, 'logcraft/rails/request_id_logger'
    autoload :RequestLogger, 'logcraft/rails/request_logger'
    autoload :LogSubscriptionHandler, 'logcraft/rails/log_subscription_handler'
  end
end
