# frozen_string_literal: true

module Viral
  module Form
    # Component to render form help text can be either default, success or error
    class HelpTextComponent < ViewComponent::Base
      attr_reader :icon

      STATE_MAPPINGS = {
        default: 'mt-2 text-sm text-slate-500 dark:text-slate-400',
        success: 'mt-2 text-sm text-green-600 dark:text-green-500',
        error: 'mt-2 text-sm text-red-600 dark:text-red-500'
      }.freeze

      ICON_MAPPINGS = {
        default: 'information_circle_solid',
        success: 'check_circle_solid',
        error: 'x_circle'
      }.freeze

      def initialize(state: :default, **system_arguments)
        @state = state
        @arguments = system_arguments
        @icon = ICON_MAPPINGS.key?(@state) ? ICON_MAPPINGS[@state] : ICON_MAPPINGS[:default]
      end

      def system_arguments
        @arguments.tap do |args|
          args[:tag] = 'p'
          args[:classes] = class_names(
            'flex items-start justify-start',
            STATE_MAPPINGS.key?(@state) ? STATE_MAPPINGS[@state] : STATE_MAPPINGS[:default],
            args[:classes]
          )
        end
      end
    end
  end
end
