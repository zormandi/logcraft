# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails log output', type: :request do
  describe 'access log' do
    it 'contains all relevant information about the request in a single line' do
      get '/access'

      expect(log_output.length).to eq 1
      log_output_is_expected.to include_log_message logger: 'AccessLog',
                                                    message: 'GET /access - 200 (OK)'
    end
  end

  describe 'manual logging' do
    it 'contains the custom log message in a structured format with all fields' do
      expect { get '/basic' }.to log logger: 'Application',
                                     message: 'test message',
                                     data: 12345
    end

    it 'contains the id of the request automatically' do
      expect { get '/basic', headers: {'X-Request-Id': 'test-request-id'} }.to log request_id: 'test-request-id'
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
      expect { get '/sql' }.to log logger: 'Application',
                                   sql: 'SELECT 1'
    end
  end
end
