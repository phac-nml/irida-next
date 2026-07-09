# frozen_string_literal: true

module Irida
  # Shared limits for client-side and server-side list selection.
  module SelectionLimits
    MAX_COUNT = 50_000

    module_function

    def exceeded?(count)
      count > MAX_COUNT
    end

    def error_message
      I18n.t('selection_limits.exceeded', max: MAX_COUNT)
    end
  end
end
