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

    it 'returns a Logging logger with the specified name and the default INFO log level' do
      expect(logger).to be_a Logging::Logger
      expect(logger.name).to eq 'TestLogger'
      expect(logger.level).to eq Logging::LEVELS['info']
    end

    context 'when a log level is specified' do
      subject(:logger) { Logcraft.logger 'TestLogger', :debug }

      it 'returns a logger with the specified log level' do
        expect(logger.level).to eq Logging::LEVELS['debug']
      end
    end
  end
end
