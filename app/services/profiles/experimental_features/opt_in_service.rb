# frozen_string_literal: true

module Profiles
  module ExperimentalFeatures
    # Service used to toggle user-managed experimental feature opt-ins.
    class OptInService < BaseService
      attr_reader :opt_in_form

      def initialize(user, opt_in_form = nil)
        super(user)

        @opt_in_form = opt_in_form
      end

      def execute
        return false unless opt_in_form&.valid?

        update_actor_gate
        true
      rescue Flipper::Error => e
        Rails.logger.error("Unable to update experimental feature opt-in: #{e.message}")
        opt_in_form.errors.add(:base, :flipper_error)
        false
      end

      private

      def update_actor_gate
        if opt_in_form.enabled?
          Flipper.enable_actor(opt_in_form.feature, current_user)
        else
          Flipper.disable_actor(opt_in_form.feature, current_user)
        end
      end
    end
  end
end
