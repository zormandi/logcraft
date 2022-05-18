# frozen_string_literal: true

require 'rails/version'

if Rails::VERSION::MAJOR == 5
  RSpec.describe Logcraft::Rails::LogSubscriptionHandler do
    describe '.detach' do
      subject(:detach) { described_class.detach ActionController::LogSubscriber }

      after do
        ActionController::LogSubscriber.attach_to :action_controller
      end

      ActionController::LogSubscriber.new.public_methods(false).each do |event|
        it "removes subscribers of the given class from all #{event} events" do
          expect { detach }.to change { listeners_for("#{event}.action_controller").count }.from(1).to(0)
        end
      end

      def listeners_for(event)
        ActiveSupport::Notifications.notifier.listeners_for event
      end
    end
  end
end
