# frozen_string_literal: true

RSpec.describe Logcraft::Rails::RequestLogger do
  let(:middleware) { described_class.new app, Logcraft.logger('AccessLog'), config }
  let(:config) { OpenStruct.new config_options }
  let(:config_options) do
    {
      log_only_whitelisted_params: false,
      whitelisted_params: [:controller, :action],
      exclude_paths: []
    }
  end

  describe '#call' do
    subject(:call) do
      s, h, body_proxy = middleware.call env
      body_proxy.close
      [s, h, body_proxy]
    end

    let(:env) do
      {
        'REQUEST_METHOD' => 'GET',
        'QUERY_STRING' => 'test=true',
        'PATH_INFO' => '/healthcheck',
        'action_dispatch.remote_ip' => '127.0.0.1',
        'rack.input' => StringIO.new('')
      }
    end

    let(:app) { double 'application' }
    let(:app_call) { -> { [status, headers, body] } }

    let(:status) { 200 }
    let(:headers) { double 'headers' }
    let(:body) { double 'body' }

    before do
      allow(app).to receive(:call).with(env) { app_call.call }
    end

    it 'calls the next middleware in the stack and returns the results' do
      s, h, b = call
      expect(s).to eq status
      expect(h).to eq headers
      expect(b).to be_a ::Rack::BodyProxy
      expect(b.instance_variable_get :@body).to eq body
    end

    it 'logs the request path and result as a message' do
      expect { call }.to log(message: 'GET /healthcheck?test=true - 200 (OK)').at_level :info
    end

    it 'only writes the log after the request is finished' do
      body_proxy = nil
      expect { _, _, body_proxy = middleware.call(env) }.not_to log message: 'GET /healthcheck?test=true - 200 (OK)'
      expect { body_proxy.close }.to log message: 'GET /healthcheck?test=true - 200 (OK)'
    end

    it 'logs additional information about the request including all parameters' do
      expect { call }.to log logger: 'AccessLog',
                             remote_ip: '127.0.0.1',
                             method: 'GET',
                             path: '/healthcheck?test=true',
                             params: {test: 'true'},
                             response_status_code: 200
    end

    it 'logs the request duration' do
      allow(::Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC, :millisecond).and_return 2373390260,
                                                                                                          2373390403
      expect { call }.to log duration: 143,
                             duration_sec: 0.143
    end

    context 'when the request path is excluded from logging' do
      context 'if the ignored path is a string' do
        before { config.exclude_paths << '/healthcheck' }

        it 'does not log anything for that path' do
          call
          log_output_is_expected.to be_empty
        end

        it 'only ignores complete matches' do
          env['PATH_INFO'] = '/'
          call
          log_output_is_expected.not_to be_empty
        end
      end

      context 'if the ignored path is a regexp' do
        before { config.exclude_paths << %r(/he\w+ck) }

        it 'does not log anything for paths that match the ignored path' do
          call
          log_output_is_expected.to be_empty
        end
      end
    end

    context 'when the params contain sensitive information' do
      before do
        env['QUERY_STRING'] = 'password=test_pass'
        env['action_dispatch.parameter_filter'] = [:password]
      end

      it 'logs the request path with sensitive information filtered out' do
        expect { call }.to log message: 'GET /healthcheck?password=[FILTERED] - 200 (OK)'
      end

      it 'logs the request params with sensitive information filtered out' do
        expect { call }.to log params: {password: '[FILTERED]'}
      end
    end

    context 'when only whitelisted params should be logged' do
      before do
        config.log_only_whitelisted_params = true
        config.whitelisted_params << :allowed
        env['QUERY_STRING'] = 'allowed=1&not_allowed=2'
      end

      it 'logs only the whitelisted params' do
        expect { call }.to log params: {allowed: '1'}
      end

      context 'when the whitelisted params contain sensitive information' do
        before do
          env['action_dispatch.parameter_filter'] = [:allowed]
        end

        it 'logs only the whitelisted params with sensitive information filtered out' do
          expect { call }.to log params: {allowed: '[FILTERED]'}
        end
      end
    end

    context 'when the request raises an error' do
      let(:app_call) { -> { raise Exception, 'test error' } }

      it 'logs the request and reraises the error' do
        expect { call }.to raise_error(Exception, 'test error')
                             .and log(message: 'GET /healthcheck?test=true - 500 (Internal Server Error)')
      end
    end

    context 'when there are log subscribers for request.action_dispatch events' do
      let(:called) { {times: 0} }

      before do
        ActiveSupport::Notifications.subscribe 'request.action_dispatch' do |name, started, finished|
          called[:times] += 1
          expect(name).to eq 'request.action_dispatch'
          expect(started).to be_within(1).of Time.now
          expect(finished).to be_within(1).of Time.now
          expect(finished).to be > started
        end
      end

      it 'dispatches the appropriate event to the subscribers' do
        call
        expect(called[:times]).to eq 1
      end

      context 'when the request raises an error' do
        let(:app_call) { -> { raise Exception, 'test error' } }

        it 'still dispatches the appropriate event to the subscribers' do
          begin; call; rescue Exception; nil; end
          expect(called[:times]).to eq 1
        end
      end
    end
  end
end
