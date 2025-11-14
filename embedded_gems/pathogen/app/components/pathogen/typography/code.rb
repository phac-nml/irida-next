# frozen_string_literal: true

require_relative 'constants'

module Pathogen
  module Typography
    # Component for rendering inline code snippets
    #
    # Use for short code snippets, variable names, or technical terms within paragraphs.
    # Features monospace font, background color, and rounded corners.
    #
    # @example Inline code
    #   <%= render Pathogen::Typography::Code.new do %>
    #     variable_name
    #   <% end %>
    #
    # @example In paragraph
    #   <%= render Pathogen::Typography::Text.new do %>
    #     Use the <%= render Pathogen::Typography::Code.new do %>pathogen_heading<%% end %> component.
    #   <% end %>
    class Code < Component
      DEFAULT_TAG = :code

      attr_reader :tag

      # Initialize a new Code component
      #
      # @param tag [Symbol] HTML tag to use (default: :code)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(tag: DEFAULT_TAG, **system_arguments)
        @tag = tag
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          Constants::TYPOGRAPHY_SCALE[14],            # text-sm
          Constants::FONT_FAMILIES[:code],            # monospace font
          'text-slate-800 dark:text-slate-100',       # contrast in both modes
          'bg-slate-100 dark:bg-slate-800',           # themed background
          'border border-slate-200 dark:border-slate-700',
          'px-2 py-0.5 rounded-md',                   # comfortable padding
          'whitespace-nowrap align-middle',
          'inline-flex items-center gap-1'
        )
      end

      private

      def class_names(*classes)
        classes
          .flatten
          .compact
          .reject(&:empty?)
          .join(' ')
      end
    end
  end
end
