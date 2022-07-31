# frozen_string_literal: true

RSpec.describe Logcraft::Rails::RequestIdLogger do
  describe '#call' do
    subject(:call) { middleware.call env }

    let(:middleware) { described_class.new app }
    let(:env) { {'action_dispatch.request_id' => 'unique request ID'} }
    let(:app) do
      ->(env) do
        Logcraft.logger('Application').info 'test message'
        "app result for #{env['action_dispatch.request_id']}"
      end
    end

    it 'calls the next middleware in the stack with the environment and returns the results' do
      expect(call).to eq 'app result for unique request ID'
    end

    it 'adds the request ID to the log context' do
      expect { call }.to log message: 'test message',
                             request_id: 'unique request ID'
    end
  end
end
