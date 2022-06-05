# frozen_string_literal: true

require 'active_record'

RSpec.describe Logcraft::Rails::ActiveRecord::LogSubscriber do
  before do
    allow(::ActiveRecord::Base).to receive(:logger).and_return Logcraft.logger('Application', :debug)
  end

  describe '#sql' do
    subject(:trigger_event) { described_class.new.sql event }
    let(:event) do
      instance_double ActiveSupport::Notifications::Event,
                      payload: {
                        name: 'User Load',
                        sql: 'SELECT * FROM users'
                      },
                      duration: 1.235
    end

    it 'logs the SQL query execution event at DEBUG level' do
      expect { trigger_event }.to log(message: 'SQL - User Load (1.235ms)',
                                      sql: 'SELECT * FROM users',
                                      duration: 1.235,
                                      duration_sec: 0.00124).at_level(:debug)
    end

    context 'when the payload has no name' do
      let(:event) do
        instance_double ActiveSupport::Notifications::Event,
                        payload: {
                          sql: 'SELECT 1'
                        },
                        duration: 1.235
      end

      it 'logs the event as a manual query' do
        expect { trigger_event }.to log message: 'SQL - Query (1.235ms)'
      end
    end

    context 'when the query has parameters' do
      let(:event) do
        instance_double ActiveSupport::Notifications::Event,
                        payload: {
                          name: 'User Load',
                          sql: 'SELECT * FROM users LIMIT $1',
                          binds: [ActiveRecord::Relation::QueryAttribute.new('LIMIT',
                                                                             1,
                                                                             instance_double(ActiveModel::Type::Value, binary?: false))],
                          type_casted_binds: [1]
                        },
                        duration: 1.235
      end

      it 'logs the query parameters' do
        expect { trigger_event }.to log(params: {LIMIT: 1}).at_level(:debug)
      end

      context 'when there are binary parameters' do
        let(:event) do
          instance_double ActiveSupport::Notifications::Event,
                          payload: {
                            name: 'User Load',
                            sql: 'SELECT * FROM users WHERE bytecode = $1',
                            binds: [ActiveRecord::Relation::QueryAttribute.new('bytecode',
                                                                               'some binary value',
                                                                               instance_double(ActiveModel::Type::Value, binary?: true))],
                            type_casted_binds: ['some binary value']
                          },
                          duration: 1.235
        end

        it "doesn't log the binary parameter's value" do
          expect { trigger_event }.to log(params: {bytecode: '-binary data-'}).at_level(:debug)
        end
      end

      context 'when param values are bound by a proc' do
        let(:event) do
          instance_double ActiveSupport::Notifications::Event,
                          payload: {
                            name: 'User Load',
                            sql: 'SELECT * FROM users LIMIT $1',
                            binds: [ActiveRecord::Relation::QueryAttribute.new('LIMIT',
                                                                               1,
                                                                               instance_double(ActiveModel::Type::Value, binary?: false))],
                            type_casted_binds: -> { [1] }
                          },
                          duration: 1.235
        end

        it 'logs the query parameter values correctly' do
          expect { trigger_event }.to log(params: {LIMIT: 1}).at_level(:debug)
        end
      end

      context 'when the parameter is an Array' do
        let(:event) do
          instance_double ActiveSupport::Notifications::Event,
                          payload: {
                            name: 'User Load',
                            sql: 'SELECT * FROM users WHERE users.id IN ($1, $2, $3, $4)',
                            binds: [1, 2, 3, 4],
                            type_casted_binds: [1, 2, 3, 4]
                          },
                          duration: 1.235
        end

        it 'logs the query parameter values correctly' do
          expect { trigger_event }.to log(params: [1, 2, 3, 4]).at_level(:debug)
        end
      end
    end
  end
end
