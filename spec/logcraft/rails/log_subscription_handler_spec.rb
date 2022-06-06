# frozen_string_literal: true

RSpec.describe Logcraft::Rails::LogSubscriptionHandler do
  describe '.detach' do
    subject(:detach) { described_class.detach ActionController::LogSubscriber, :action_controller }

    before do
      ActionController::LogSubscriber.attach_to(:action_controller) if listeners_for("process_action.action_controller").count == 0
    end

    def self.subscription_actions
      ActionController::LogSubscriber.new
                                     .public_methods(false)
                                     .reject { |method| method == :logger }
    end

    subscription_actions.each do |event|
      it "removes subscribers of the given class from all #{event} events" do
        expect { detach }.to change { listeners_for("#{event}.action_controller").count }.from(1).to(0)
      end
    end

    def listeners_for(event)
      ActiveSupport::Notifications.notifier.listeners_for event
    end
  end
end
