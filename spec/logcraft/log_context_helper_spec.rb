# frozen_string_literal: true

RSpec.describe Logcraft::LogContextHelper do
  describe '#within_log_context' do
    let(:context_logging_test_class) do
      Class.new do
        include Logcraft::LogContextHelper

        def log_within_context
          logger = Logcraft.logger 'TestLogger'
          within_log_context data: 'context' do
            logger.info 'test1'
          end
          logger.info 'test2'
        end
      end
    end

    it 'runs the passed block within the specified log context' do
      context_logging_test_class.new.log_within_context

      expect(log_output).to include_log_message message: 'test1', data: 'context'
      expect(log_output).to include_log_message message: 'test2'
      expect(log_output).not_to include_log_message message: 'test2', data: 'context'
    end
  end

  describe '#add_to_log_context' do
    let(:context_logging_test_class) do
      Class.new do
        include Logcraft::LogContextHelper

        def log_with_context_added_beforehand
          logger = Logcraft.logger 'TestLogger'
          within_log_context do
            add_to_log_context data: 'context'
            logger.info 'test1'
          end
          logger.info 'test2'
        end
      end
    end

    it 'adds the specified params to the current log context' do
      context_logging_test_class.new.log_with_context_added_beforehand

      expect(log_output).to include_log_message message: 'test1', data: 'context'
      expect(log_output).to include_log_message message: 'test2'
      expect(log_output).not_to include_log_message message: 'test2', data: 'context'
    end
  end
end
