# frozen_string_literal: true

module Viral
  module Form
    class HelpTextComponent < ViewComponent::Base
      attr_reader :system_arguments

      STATE_MAPPINGS = {
        default: 'mt-2 text-sm text-slate-500 dark:text-slate-400',
        success: 'mt-2 text-sm text-green-600 dark:text-green-500',
        error: 'mt-2 text-sm text-red-600 dark:text-red-500'
      }.freeze

      def initialize(state: :default, **system_arguments)
        @state = state
        @system_arguments = system_arguments
      end

      def system_arguments
        @system_arguments.tap do |args|
          args[:tag] = 'p'
          args[:classes] = STATE_MAPPINGS.key?(@state) ? STATE_MAPPINGS[@state] : STATE_MAPPINGS[:default]
        end
      end
    end
  end
end
