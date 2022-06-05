# frozen_string_literal: true

module Logcraft
  module Rails
    module ActiveRecord
      autoload :LogSubscriber, 'logcraft/rails/active_record/log_subscriber'
    end
  end
end
