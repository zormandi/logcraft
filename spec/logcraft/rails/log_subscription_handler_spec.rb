# frozen_string_literal: true

RSpec.describe Logcraft::Rails::LogSubscriptionHandler do
  if ::Rails::VERSION::MAJOR == 5
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
  else
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
end
