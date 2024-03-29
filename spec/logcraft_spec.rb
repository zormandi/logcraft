# frozen_string_literal: true

RSpec.describe Logcraft do
  it 'has a version number' do
    expect(Logcraft::VERSION).not_to be nil
  end

  it 'includes the LogContextHelper methods' do
    expect(Logcraft).to be_a Logcraft::LogContextHelper
  end

  describe '.logger' do
    subject(:logger) { Logcraft.logger 'TestLogger' }

    before(:all) { Logging.init unless Logging.initialized? }

    it 'returns a Logging logger with the specified name and the default log level' do
      default_log_level = Logging.logger.root.level
      expect(logger).to be_a Logging::Logger
      expect(logger.name).to eq 'TestLogger'
      expect(logger.level).to eq default_log_level
    end

    context 'when a log level is specified' do
      subject(:logger) { Logcraft.logger 'TestLogger', :fatal }

      it 'returns a logger with the specified log level' do
        expect(logger.level).to eq Logging::LEVELS['fatal']
      end

      it 'returns a logger which can be duplicated with the same log level' do
        logger_copy = logger.dup
        expect(logger_copy).to respond_to :debug
        expect(logger_copy.level).to eq logger.level
      end
    end

    it 'returns a logger which reports to ActiveSupport that it logs to STDOUT so ActiveRecord does not append a new console logger' do
      expect(ActiveSupport::Logger.logger_outputs_to?(logger, STDERR, STDOUT)).to be true
    end

    it 'returns a logger which can be duplicated' do
      logger_copy = logger.dup
      expect(logger_copy).to respond_to :debug
    end
  end
end
