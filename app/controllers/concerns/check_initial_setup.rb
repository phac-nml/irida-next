# frozen_string_literal: true

# Checks if the application is in initial setup
module CheckInitialSetup
  extend ActiveSupport::Concern

  included do
    helper_method :in_initial_setup_state?
  end

  def in_initial_setup_state?
    # Count as much 2 to know if we have exactly one
    return false unless User.limit(2).count == 1

    true
  end
end
