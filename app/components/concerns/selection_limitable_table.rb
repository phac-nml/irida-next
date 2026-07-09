# frozen_string_literal: true

# Shared selection-limit helpers for tables that use SelectionController.
module SelectionLimitableTable
  extend ActiveSupport::Concern

  SELECTION_LIMIT_ALERT_ID = 'selection-limit-alert'

  def selection_limit_data_attributes
    {
      'selection-max-selection-value': Irida::SelectionLimits::MAX_COUNT,
      'selection-limit-message-value': I18n.t(
        'components.selection.limit.selection_limit_reached',
        max: Irida::SelectionLimits::MAX_COUNT
      ),
      'selection-storage-limit-message-value': I18n.t(
        'components.selection.limit.storage_full',
        max: Irida::SelectionLimits::MAX_COUNT
      )
    }
  end

  def show_selection_limit_alert?
    selection_limit_exceeded?(@pagy.count)
  end

  def selection_limit_list_too_large_message
    I18n.t(
      'components.selection.limit.list_too_large',
      count: @pagy.count,
      max: Irida::SelectionLimits::MAX_COUNT
    )
  end

  private

  def selection_limit_exceeded?(count)
    Irida::SelectionLimits.exceeded?(count)
  end
end
