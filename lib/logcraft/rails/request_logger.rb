# frozen_string_literal: true

module Logcraft
  module Rails
    class RequestLogger
      def initialize(app, logger, config)
        @app = app
        @logger = logger
        @config = config
      end

      def call(env)
        start_time = current_time_in_milliseconds
        request = ActionDispatch::Request.new env

        instrumentation_start request
        status, headers, body = @app.call env
        body = ::Rack::BodyProxy.new(body) { instrumentation_finish request }
        log_request request, status, start_time

        [status, headers, body]
      rescue Exception => ex
        instrumentation_finish request
        log_request request, status_for_error(ex), start_time
        raise
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end

      private

      def current_time_in_milliseconds
        Process.clock_gettime Process::CLOCK_MONOTONIC, :millisecond
      end

      def instrumentation_start(request)
        instrumenter = ActiveSupport::Notifications.instrumenter
        instrumenter.start 'request.action_dispatch', request: request
      end

      def instrumentation_finish(request)
        instrumenter = ActiveSupport::Notifications.instrumenter
        instrumenter.finish 'request.action_dispatch', request: request
      end

      def log_request(request, status, start_time)
        return if path_ignored? request

        end_time = current_time_in_milliseconds
        @logger.info message: '%s %s - %i (%s)' % [request.method, request.filtered_path, status, Rack::Utils::HTTP_STATUS_CODES[status]],
                     remote_ip: request.remote_ip,
                     method: request.method,
                     path: request.filtered_path,
                     params: params_to_log(request),
                     response_status_code: status,
                     duration: end_time - start_time,
                     duration_sec: (end_time - start_time) / 1000.0
      end

      def path_ignored?(request)
        @config.exclude_paths.any? do |pattern|
          case pattern
          when Regexp
            pattern.match? request.path
          else
            pattern == request.path
          end
        end
      end

      def params_to_log(request)
        if @config.log_only_whitelisted_params
          request.filtered_parameters.slice *@config.whitelisted_params&.map(&:to_s)
        else
          request.filtered_parameters
        end
      end

      def status_for_error(error)
        ActionDispatch::ExceptionWrapper.status_code_for_exception error.class.name
      end
    end
  end
end
