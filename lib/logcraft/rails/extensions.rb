module ActionDispatch
  class DebugExceptions
    def log_error_with_logcraft(request, wrapper)
      logger = logger(request)
      exception = wrapper.exception
      logger.fatal exception
    end

    alias_method :original_log_error, :log_error
    alias_method :log_error, :log_error_with_logcraft
  end
end
