# frozen_string_literal: true

# Guards controller actions that accept a list of selected record ids.
module SelectionLimitEnforcement
  extend ActiveSupport::Concern

  private

  def selection_limit_exceeded_for?(count)
    Irida::SelectionLimits.exceeded?(count)
  end

  def selection_limit_exceeded_for_scope?(scope)
    selection_limit_exceeded_for?(limited_scope_count(scope))
  end

  def limited_scope_count(scope)
    scope.reorder(nil).limit(Irida::SelectionLimits::MAX_COUNT + 1).count
  end

  def selection_limit_error_message
    Irida::SelectionLimits.error_message
  end
end
