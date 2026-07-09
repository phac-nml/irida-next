# frozen_string_literal: true

# Guards controller actions that accept a list of selected record ids.
module SelectionLimitEnforcement
  extend ActiveSupport::Concern

  private

  def selection_limit_exceeded_for?(count)
    Irida::SelectionLimits.exceeded?(count)
  end

  def selection_limit_error_message
    Irida::SelectionLimits.error_message
  end
end
