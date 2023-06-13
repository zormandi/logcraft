# frozen_string_literal: true

require 'time'

module Logcraft
  class LogLayout < Logging::Layout
    JSON_FORMATTER = ->(event) { MultiJson.dump(event) + "\n" }.freeze
    LOGGING_LEVEL_FORMATTER = ->(level) { Logging::LNAMES[level] }.freeze

    def initialize(global_context = {}, options = {})
      @global_context = global_context
      @formatter = options.fetch :formatter, JSON_FORMATTER
      @level_formatter = options.fetch :level_formatter, LOGGING_LEVEL_FORMATTER
    end

    def format(event)
      log_entry = background_of(event).merge evaluated_global_context,
                                             dynamic_log_context,
                                             message_from(event.data)
      @formatter.call log_entry
    end

    private

    def background_of(event)
      {
        'timestamp' => event.time.iso8601(3),
        'level' => @level_formatter.call(event.level),
        'logger' => event.logger,
        'hostname' => Socket.gethostname,
        'pid' => Process.pid
      }
    end

    def evaluated_global_context
      if @global_context.respond_to? :call
        @global_context.call
      else
        @global_context
      end
    end

    def dynamic_log_context
      Logging.mdc.context
    end

    def message_from(payload)
      case payload
      when Hash
        format_hash payload
      when Exception
        {'message' => payload.message, 'error' => format_exception(payload)}
      else
        {'message' => payload}
      end
    end

    def format_hash(hash)
      hash.transform_values { |v| v.is_a?(Exception) ? format_exception(v) : v }
    end

    def format_exception(exception)
      error_hash = {'class' => exception.class.name, 'message' => exception.message}
      error_hash['backtrace'] = exception.backtrace.first(20) if exception.backtrace
      error_hash['cause'] = format_cause(exception.cause) if exception.cause
      error_hash
    end

    def format_cause(cause)
      cause = cause.cause while cause.cause
      format_exception cause
    end
  end
end
