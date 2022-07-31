# frozen_string_literal: true

module ActionDispatch
  class DebugExceptions

    private

    def log_error_with_logcraft(request, wrapper)
      logger = logger(request)
      exception = wrapper.exception
      config = Rails.configuration.logcraft.unhandled_errors
      logger.public_send config.log_level, exception if config.log_errors_handled_by_rails || !handled_by_rails?(exception)
    end

    alias_method :original_log_error, :log_error
    alias_method :log_error, :log_error_with_logcraft

    def handled_by_rails?(exception)
      ActionDispatch::ExceptionWrapper.rescue_responses.key? exception.class.name
    end
  end
end
