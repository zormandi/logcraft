# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails log output', type: :request do
  describe 'access log' do
    it 'contains all relevant information about the request in a single line' do
      get '/access'

      expect(log_output.length).to eq 1
      log_output_is_expected.to include_log_message logger: include(name: 'AccessLog'),
                                                    message: 'GET /access - 200 (OK)',
                                                    request_id: match(/[\w-]+/)
    end
  end

  describe 'manual logging' do
    it 'contains the custom log message in a structured format with all fields' do
      expect { get '/basic' }.to log logger: include(name: 'Application'),
                                     message: 'test message',
                                     data: 12345
    end

    it 'contains the id of the request automatically' do
      expect { get '/basic', headers: {'X-Request-Id': 'test-request-id'} }.to log request_id: 'test-request-id'
    end

    it 'contains the custom initial context set in the application configuration' do
      expect { get '/basic' }.to log custom: 'data'
    end
  end

  describe 'database query logs' do
    around do |spec|
      original_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = :debug
      spec.run
      ActiveRecord::Base.logger.level = original_log_level
    end

    it 'contains log messages for SQL queries' do
      expect { get '/sql' }.to log logger: include(name: 'Application'),
                                   sql: 'SELECT 1'
    end
  end

  describe 'unhandled error logging' do
    it 'contains the unhandled error log message in a single line and structured format at the configured log level' do
      expect { get '/error' }.to log logger: include(name: 'Application'),
                                     level: 'ERROR',
                                     message: 'Unhandled error'
      expect(log_output.size).to eq 2
    end

    it 'can be configured to suppress logs for errors handled by Rails' do
      expect { get '/not_found' }.not_to log message: /No route matches.*/
      expect(log_output.size).to eq 1
    end
  end
end
