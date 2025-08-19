# frozen_string_literal: true

RSpec.describe Logcraft::LogLayout do
  before(:all) { Logging.init unless Logging.initialized? }

  describe '#format' do
    subject(:log_line) { layout.format event }
    let(:log_line_hash) { JSON.parse log_line }

    let(:layout) { described_class.new context, options }
    let(:context) { {} }
    let(:options) { {} }
    let(:event) { Logging::LogEvent.new 'TestLogger', Logging::LEVELS['info'], event_data, false }
    let(:event_data) { '' }

    it 'includes the basic context of the event' do
      expect(log_line_hash).to include 'timestamp' => event.time.iso8601(3),
                                       'level' => 'INFO',
                                       'logger' => {
                                         'name' => 'TestLogger',
                                          'thread_id' => Thread.current.native_thread_id,
                                          'process_id' => Process.pid,
                                       },
                                       'hostname' => Socket.gethostname
    end

    it 'includes the logging thread name if it has one' do
      Thread.current.name = 'test_thread'
      expect(log_line_hash['logger']).to include 'thread_name' => 'test_thread'
      Thread.current.name = nil
    end

    it 'ends with a new line' do
      expect(log_line).to end_with "\n"
    end

    describe 'event data formatting' do
      context 'when the event data is a String' do
        let(:event_data) { 'Hello, World!' }

        it 'contains the data in the message field' do
          expect(log_line_hash).to include 'message' => 'Hello, World!'
        end
      end

      context 'when the event data is a Hash' do
        let(:event_data) { {test: 'data', field: 'value'} }

        it 'contains the complete event data' do
          expect(log_line_hash).to include 'test' => 'data',
                                           'field' => 'value'
        end

        context 'when one of the values is an exception' do
          let(:event_data) { {message: 'failure', error: StandardError.new('something went wrong')} }

          it 'contains the error context for the exception' do
            expect(log_line_hash).to include 'message' => 'failure',
                                             'error' => {
                                               'class' => 'StandardError',
                                               'message' => 'something went wrong'
                                             }
          end
        end
      end

      context 'when the event data is an Exception' do
        let(:event_data) { StandardError.new 'error message' }
        let(:backtrace) { nil }

        before { event_data.set_backtrace backtrace }

        it 'contains the details of the exception in the message and error fields' do
          expect(log_line_hash).to include 'message' => 'error message',
                                           'error' => {
                                             'class' => 'StandardError',
                                             'message' => 'error message'
                                           }
        end

        context 'when the exception contains a backtrace' do
          let(:backtrace) { ['file1:line1', 'file2:line2'] }

          it 'includes the backtrace in the error context' do
            expect(log_line_hash['error']).to include 'stack' => backtrace
          end

          context 'but the backtrace is long' do
            let(:backtrace) { 1.upto(25).map { |i| "file#{i}:line#{i}" } }

            it 'only includes the first 20 locations of the backtrace in the error context' do
              expect(log_line_hash['error']).to include 'stack' => backtrace.first(20)
            end
          end
        end

        context 'when the exception has an underlying cause' do
          let(:event_data) { nest_exception RuntimeError.new('original error'), StandardError.new('wrapping error') }

          it 'includes the underlying error in the cause field of the error context' do
            expect(log_line_hash).to include 'message' => 'wrapping error',
                                             'error' => {
                                               'class' => 'StandardError',
                                               'message' => 'wrapping error',
                                               'cause' => include(
                                                 'class' => 'RuntimeError',
                                                 'message' => 'original error'
                                               )
                                             }
          end

          context 'when there are nested causes' do
            let(:event_data) do
              error = nest_exception RuntimeError.new('original error'), StandardError.new('inner wrapping error')
              nest_exception error, StandardError.new('outer wrapping error')
            end

            it 'includes only the final underlying cause' do
              expect(log_line_hash).to include 'message' => 'outer wrapping error',
                                               'error' => {
                                                 'class' => 'StandardError',
                                                 'message' => 'outer wrapping error',
                                                 'cause' => include(
                                                   'class' => 'RuntimeError',
                                                   'message' => 'original error'
                                                 )
                                               }
            end
          end
        end

        def nest_exception(original_error, wrapping_error)
          begin
            raise original_error
          rescue
            raise wrapping_error
          end
        rescue => ex
          ex
        end
      end
    end

    context 'when a global context is provided upon initialization' do
      let(:context) { {context: 'data'} }

      it 'includes the global context fields' do
        expect(log_line_hash).to include 'context' => 'data'
      end

      context 'when the global context is callable (lambda or Proc)' do
        let(:context) { Proc.new { {custom_data: 'dynamic data'} } }

        it 'evaluates the lambda or Proc and includes the result' do
          expect(log_line_hash).to include 'custom_data' => 'dynamic data'
        end
      end
    end

    context 'when a formatter is provided as an option' do
      let(:options) { {formatter: ->(event) { YAML.dump event }} }
      let(:event_data) { 'Hello, World!' }

      it 'outputs the log event through the formatter' do
        expect(log_line).to eq <<~YAML
          ---
          timestamp: '#{event.time.iso8601(3)}'
          level: INFO
          logger:
            name: TestLogger
            thread_id: #{Thread.current.native_thread_id}
            process_id: #{Process.pid}
          hostname: #{Socket.gethostname}
          message: Hello, World!
        YAML
      end
    end

    context 'when a log level formatter is provided as an option' do
      let(:options) { {level_formatter: ->(level_number) { "level #{level_number}" }} }

      it 'includes the custom log level name' do
        expect(log_line_hash).to include 'level' => 'level 1'
      end
    end

    context 'when a log context is set' do
      before do
        Logging.mdc['customer_id'] = 'some_customer'
        Logging.mdc['request_id'] = 'the_request'
      end

      after { Logging.mdc.clear }

      it 'includes the log context fields' do
        expect(log_line_hash).to include 'customer_id' => 'some_customer',
                                         'request_id' => 'the_request'
      end

      context 'when the event data contains fields that conflict with the log context' do
        let(:event_data) { {'customer_id' => 'overriden'} }

        it 'contains the message data, not the log context' do
          expect(log_line_hash).to include 'customer_id' => 'overriden'
        end
      end
    end
  end
end
