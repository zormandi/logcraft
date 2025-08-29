# frozen_string_literal: true

module Logcraft
  module Rails
    module ActionController
      class LogSubscriber < ActiveSupport::LogSubscriber
        def process_action(event)
          request = event.payload[:request]
          status = event.payload[:status]
          logger.info message: '%s %s - %i (%s)' % [request.method, request.filtered_path, status, Rack::Utils::HTTP_STATUS_CODES[status]],
                      http: {
                        method: request.method,
                        status_code: status,
                        url: request.filtered_path,
                        url_details: {
                          path: request.path,
                          params: params_to_log(request),
                        },
                        referer: request.referer,
                      }.compact,
                      network: {
                        client: {
                          ip: request.remote_ip,
                        }
                      },
                      duration: event.duration.round,
                      db: {
                        duration: event.payload[:db_runtime].to_f.round(1),
                        duration_percentage: (event.payload[:db_runtime] / event.duration * 100).round(1),
                        queries: event.payload[:queries_count].to_i,
                        cached_queries: event.payload[:cached_queries_count].to_i,
                      },
                      view: {
                        duration: event.payload[:view_runtime].to_f.round(1),
                        duration_percentage: (event.payload[:view_runtime] / event.duration * 100).round(1),
                      }
        end

        private

        def params_to_log(request)
          request.filtered_parameters
        end
      end
    end
  end
end
