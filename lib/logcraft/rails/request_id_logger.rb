# frozen_string_literal: true

module Logcraft
  module Rails
    class RequestIdLogger
      include LogContextHelper

      def initialize(app)
        @app = app
      end

      def call(env)
        within_log_context request_id: env['action_dispatch.request_id'] do
          @app.call env
        end
      end
    end
  end
end
