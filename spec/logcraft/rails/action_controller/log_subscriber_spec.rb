# frozen_string_literal: true

require 'active_support'

RSpec.describe Logcraft::Rails::ActionController::LogSubscriber do
  before do
    allow(ActiveSupport::LogSubscriber).to receive(:logger).and_return Logcraft.logger('AccessLog')
  end

  describe '#process_action' do
    subject(:trigger_event) { described_class.new.process_action(event) }

    let(:request) do
      double 'Request',
             method: 'GET',
             filtered_path: '/widgets?x=1',
             path: '/widgets',
             referer: referer,
             remote_ip: '127.0.0.1',
             filtered_parameters: { x: '1' }
    end
    let(:referer) { 'https://example.test' }

    let(:event) do
      instance_double ActiveSupport::Notifications::Event,
                      payload: {
                        request: request,
                        status: 200,
                        db_runtime: 12.345,
                        queries_count: 3,
                        cached_queries_count: 1,
                        view_runtime: 45.6789
                      },
                      duration: 123.7
    end

    it 'logs a single structured message with request and timing details' do
      expect { trigger_event }.to log(message: 'GET /widgets?x=1 - 200 (OK)',
                                      http: {
                                        method: 'GET',
                                        status_code: 200,
                                        url: '/widgets?x=1',
                                        url_details: { path: '/widgets', params: { x: '1' } },
                                        referer: 'https://example.test'
                                      },
                                      network: { client: { ip: '127.0.0.1' } },
                                      duration: 124,
                                      db: {
                                        duration: 12.3,
                                        duration_percentage: 10.0,
                                        queries: 3,
                                        cached_queries: 1
                                      },
                                      view: {
                                        duration: 45.7,
                                        duration_percentage: 36.9
                                      }).at_level(:info)

    end

    context 'when request has no referer' do
      let(:referer) { nil }

      it 'does not include a referer value in the log' do
        expect { trigger_event }.to_not log http: include(referer: nil)

      end
    end
  end
end
