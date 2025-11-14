# frozen_string_literal: true

require_relative 'constants'

module Pathogen
  module Typography
    # Component for rendering multi-line code blocks
    #
    # Perfect for multi-line code snippets. Features a dark background, monospace font,
    # and scrollable overflow for long code examples.
    #
    # @example Code block
    #   <%= render Pathogen::Typography::CodeBlock.new(language: "ruby") do %>
    #     def example
    #       puts "Hello"
    #     end
    #   <% end %>
    #
    # @example With language class
    #   <%= render Pathogen::Typography::CodeBlock.new(language: "javascript") do %>
    #     const example = () => {
    #       console.log("Hello");
    #     };
    #   <% end %>
    class CodeBlock < Component
      attr_reader :language

      # Initialize a new CodeBlock component
      #
      # @param language [String, Symbol, nil] Programming language for syntax highlighting class
      # @param system_arguments [Hash] Additional HTML attributes applied to the wrapper
      def initialize(language: nil, **system_arguments)
        @language = language

        @wrapper_classes = class_names(
          system_arguments[:class],
          'rounded-2xl',
          'bg-slate-900 dark:bg-slate-950',
          'text-slate-100',
          'ring-1 ring-slate-900/40 dark:ring-white/10',
          'shadow-inner',
          'overflow-hidden'
        )

        @pre_classes = class_names(
          Constants::FONT_FAMILIES[:code],
          Constants::TYPOGRAPHY_SCALE[14],
          'leading-relaxed',
          'text-inherit',
          'bg-transparent',
          'p-4 sm:p-5',
          'whitespace-pre-wrap',
          'overflow-x-auto'
        )

        @code_classes = class_names(
          'block',
          'min-w-full',
          'font-mono',
          'text-inherit',
          'bg-transparent',
          'tracking-tight',
          "language-#{language}"
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
