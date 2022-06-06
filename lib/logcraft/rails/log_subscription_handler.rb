# frozen_string_literal: true

require 'rails/version'

module Logcraft
  module Rails
    class LogSubscriptionHandler
      class << self
        def detach(subscriber_class, namespace)
          case ::Rails::VERSION::MAJOR
          when 5
            subscriber = ::ActiveSupport::LogSubscriber.log_subscribers.find { |subscriber| subscriber.is_a? subscriber_class }
            return unless subscriber

            subscriber.patterns.each do |pattern|
              ::ActiveSupport::Notifications.notifier.listeners_for(pattern).each do |listener|
                ::ActiveSupport::Notifications.unsubscribe listener if listener.instance_variable_get('@delegate').is_a? subscriber_class
              end
            end

          else
            subscriber_class.detach_from namespace
          end
        end

        def attach(subscriber_class, namespace)
          subscriber_class.attach_to namespace
        end
      end
    end
  end
end
