# frozen_string_literal: true

require 'json'

RSpec::Matchers.define :include_log_message do |expected_message|
  chain :at_level, :log_level

  match do |actual|
    actual.any? { |log_line| includes? log_line, expected_message }
  end

  def includes?(log_line, expected)
    actual = JSON.parse log_line, symbolize_names: true
    expected = normalize_expectation expected
    RSpec::Matchers::BuiltIn::Include.new(expected).matches? actual
  end

  def normalize_expectation(expected)
    result = case expected
             when String
               {message: expected}
             when Hash
               expected
             else
               raise ArgumentError, 'Log expectation must be either a String or a Hash'
             end
    result[:level] = log_level_string(log_level) unless log_level.nil?
    result
  end

  def log_level_string(log_level)
    return 'WARN' if log_level == :warning
    log_level.to_s.upcase
  end

  failure_message do |actual|
    error_message = "expected log output\n\t'#{actual.join('')}'\nto include log message\n\t'#{expected_message}'"
    error_message += " at #{log_level} level" if log_level
    error_message
  end
end

RSpec::Matchers.define :log do
  supports_block_expectations
  chain :at_level, :log_level

  failure_message do
    error_message = "expected operation to log '#{expected}'"
    error_message += " at #{log_level} level" if log_level
    "#{error_message}\n\nactual log output:\n#{log_output.join('')}"
  end

  match do |operation|
    raise 'log matcher only supports block expectations' unless operation.is_a? Proc
    log_output_is_expected.not_to include_log_message(expected)
    operation.call
    log_output_is_expected.to include_log_message(expected).at_level(log_level)
  end
end
