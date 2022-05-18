# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails log output', type: :request do
  it 'contains all relevant information about the request in a single line' do
    get '/access'

    expect(log_output.length).to eq 1
    log_output_is_expected.to include_log_message logger: 'AccessLog', message: 'GET /access - 200 (OK)'
  end

  it 'contains the custom log message in a structured format with all fields' do
    expect { get '/basic' }.to log(message: 'test message', data: 12345).at_level :info
  end
end
