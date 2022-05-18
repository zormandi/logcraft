# frozen_string_literal: true

require 'json'

RSpec::Matchers.define :include_log_message do |expected|
  chain :at_level, :log_level

  match do |actual|
    actual.any? { |log_line| includes? log_line, expected_messages_from(expected) }
  end

  def includes?(log_line, messages)
    return false unless includes_log_level? log_line
    messages.all? { |message| log_line.include? message }
  end

  def includes_log_level?(log_line)
    return true if log_level.nil?
    log_line.include? log_level_string(log_level)
  end

  def log_level_string(log_level)
    return 'WARN' if log_level == :warning
    log_level.to_s.upcase
  end

  def expected_messages_from(object)
    @expected_messages ||= case object
                           when Hash
                             object.map { |k, v| JSON.dump(k => v)[1...-1] }
                           when String
                             [object]
                           else
                             raise NotImplementedError, 'log expectation must be Hash or String'
                           end
  end

  failure_message do |actual|
    error_message = "expected log output\n\t'#{actual.join('')}'\nto include log message\n\t'#{expected}'"
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
