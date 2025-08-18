# frozen_string_literal: true

RSpec.describe Logcraft::Rails::LogSubscriptionHandler do
  describe '.attach' do
    subject(:attach) { described_class.attach ActionController::LogSubscriber, :action_controller }

    it 'attaches the log subscriber to the namespace' do
      expect(ActionController::LogSubscriber).to receive(:attach_to).with :action_controller
      attach
    end
  end

  describe '.detach' do
    subject(:detach) { described_class.detach ActionController::LogSubscriber, :action_controller }

    it 'detaches the log subscriber from the namespace' do
      expect(ActionController::LogSubscriber).to receive(:detach_from).with :action_controller
      detach
    end
  end
end
