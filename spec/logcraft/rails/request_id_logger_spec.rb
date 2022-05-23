# frozen_string_literal: true

RSpec.describe Logcraft::Rails::RequestIdLogger do
  describe '#call' do
    subject(:call) { middleware.call env }

    let(:middleware) { described_class.new app }
    let(:env) { {'action_dispatch.request_id' => 'unique request ID'} }
    let(:app) { double 'application' }
    let(:app_call) do
      -> do
        Logcraft.logger('Application').info 'test message'
        app_call_result
      end
    end
    let(:app_call_result) { 'app_call_result' }

    before do
      allow(app).to receive(:call).with(env) { app_call.call }
    end

    it 'calls the next middleware in the stack and returns the results' do
      expect(call).to eq app_call_result
    end

    it 'adds the request ID to the log context' do
      expect { call }.to log message: 'test message',
                             request_id: 'unique request ID'
    end
  end
end
