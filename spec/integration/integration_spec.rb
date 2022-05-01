# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails log output', type: :request do
  it 'contains the custom log message in a structured format with all fields' do
    get '/basic'

    expect(@log_output.clone.readlines).to satisfy do |log_lines|
      log_lines.any? do |line|
        parsed_line = JSON.parse line
        parsed_line > {'level' => 'INFO', 'message' => 'test message', 'data' => 12345}
      end
    end
  end
end
