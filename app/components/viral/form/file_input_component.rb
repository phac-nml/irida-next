# frozen_string_literal: true

module Viral
  module Form
    # Component to render form file inputs
    class FileInputComponent < Viral::Component
      attr_reader :label, :name, :help_text, :hidden

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label: nil, default: nil, required: nil, pattern: nil, help_text: nil,
                     hidden: false, **arguments)
        @name = name
        @label = label
        @default = default
        @required = required
        @pattern = pattern
        @help_text = help_text
        @hidden = hidden
        @arguments = arguments
      end

      # rubocop:enable Metrics/ParameterLists

      def system_arguments
        @arguments.tap do |args|
          args[:value] = @default
          args[:required] = @required if @required.present?
          args[:pattern] = @pattern if @pattern.present?
          args[:class] = class_names(
            'block w-full cursor-pointer rounded-[var(--pvc-radius-control)] border',
            'border-[var(--pvc-color-border-strong)] bg-slate-50 text-sm text-slate-900',
            'dark:text-slate-400 dark:bg-slate-700 dark:placeholder-slate-400',
            args[:class]
          )
        end
      end
    end
  end
end
