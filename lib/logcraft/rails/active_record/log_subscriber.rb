# frozen_string_literal: true

module Logcraft
  module Rails
    module ActiveRecord
      class LogSubscriber < ActiveSupport::LogSubscriber
        def sql(event)
          ::ActiveRecord::Base.logger.debug { log_message_from(event) }
        end

        private

        def log_message_from(event)
          basic_message_from(event).tap do |message|
            params = params_from event
            message[:params] = params if params.any?
          end
        end

        def basic_message_from(event)
          {
            message: "SQL - #{event.payload[:name] || 'Query'} (#{event.duration.round}ms)",
            sql: event.payload[:sql],
            duration: (event.duration * 1_000_000).round,
            duration_ms: event.duration.round,
            duration_sec: (event.duration / 1000.0).round(5)
          }
        end

        def params_from(event)
          return {} if event.payload.fetch(:binds, []).empty?

          params = event.payload[:binds]
          values = type_casted_values_from event
          param_value_pairs = params.zip(values).map do |param, value|
            [param.name, value_of(param, value)]
          end

          Hash[param_value_pairs]
        rescue NoMethodError
          params
        end

        def type_casted_values_from(event)
          binds = event.payload[:type_casted_binds]
          binds.respond_to?(:call) ? binds.call : binds
        end

        def value_of(param, value)
          param.type.binary? ? '-binary data-' : value
        end
      end
    end
  end
end
