# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Footer action button (Apply/Cancel).
    class FooterAction < Pathogen::Component
      KIND_OPTIONS = %i[apply cancel].freeze

      def initialize(kind:, label:, **system_arguments)
        @kind = fetch_or_fallback(KIND_OPTIONS, kind, :apply)
        @label = label
        @system_arguments = system_arguments
      end

      # rubocop:disable Metrics/MethodLength
      def call
        action_name = @kind == :apply ? 'apply' : 'cancel'

        cancel_classes = [
          'bg-white text-slate-900 border border-slate-200 hover:bg-slate-100',
          'dark:bg-slate-800 dark:text-slate-100 dark:border-slate-700 dark:hover:bg-slate-700'
        ].join(' ')

        data = (@system_arguments[:data] || {}).dup
        existing_action = data[:action] || data['action']
        data[:action] = class_names(existing_action, "click->pathogen--dropdown-menu##{action_name}")
        data['pathogen--dropdown-menu-target'] ||= 'footerAction'

        content_tag(
          :button,
          @label,
          **@system_arguments, type: :button,
                               data: data,
                               class: class_names(
                                 'inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm font-medium',
                                 'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600',
                                 @system_arguments[:class],
                                 cancel_classes => @kind == :cancel,
                                 'bg-primary-700 text-white hover:bg-primary-800' => @kind == :apply
                               )
        )
      end

      # rubocop:enable Metrics/MethodLength
    end
  end
end
