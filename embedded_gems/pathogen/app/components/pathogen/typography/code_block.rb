# frozen_string_literal: true

require_relative 'constants'

module Pathogen
  module Typography
    # Component for rendering multi-line code blocks
    #
    # Perfect for multi-line code snippets. Features a dark background, monospace font,
    # and scrollable overflow for long code examples.
    #
    # **Note on syntax highlighting**: The `language` parameter adds a CSS class
    # (`language-{language}`) to the `<code>` element. To enable syntax highlighting,
    # you must integrate a syntax highlighting library like Prism.js or Highlight.js
    # that uses these classes. Without a highlighting library, the code will display
    # as plain text with consistent styling.
    #
    # @example Code block
    #   <%= render Pathogen::Typography::CodeBlock.new(language: "ruby") do %>
    #     def example
    #       puts "Hello"
    #     end
    #   <% end %>
    #
    # @example With language class for syntax highlighting
    #   <%= render Pathogen::Typography::CodeBlock.new(language: "javascript") do %>
    #     const example = () => {
    #       console.log("Hello");
    #     };
    #   <% end %>
    class CodeBlock < Component
      attr_reader :language

      # Initialize a new CodeBlock component
      #
      # @param language [String, Symbol, nil] Programming language identifier (e.g., "ruby", "javascript").
      #   Adds a `language-{language}` CSS class for syntax highlighting libraries.
      #   Requires Prism.js, Highlight.js, or similar library to be integrated for actual highlighting.
      # @param system_arguments [Hash] Additional HTML attributes applied to the wrapper
      def initialize(language: nil, **system_arguments)
        @language = language
        @system_arguments = system_arguments

        @wrapper_classes = build_wrapper_classes(system_arguments[:class])
        @pre_classes = build_pre_classes
        @code_classes = build_code_classes(language)
      end

      private

      def build_wrapper_classes(custom_class)
        class_names(
          custom_class,
          'rounded-2xl',
          'bg-slate-900 dark:bg-slate-950',
          'text-slate-100',
          'ring-1 ring-slate-900/40 dark:ring-white/10',
          'shadow-inner',
          'overflow-hidden'
        )
      end

      def build_pre_classes
        class_names(
          Constants::FONT_FAMILIES[:mono],
          Constants::TYPOGRAPHY_SCALE[14],
          'leading-relaxed',
          'text-inherit',
          'bg-transparent',
          'p-4 sm:p-5',
          'whitespace-pre-wrap',
          'overflow-x-auto'
        )
      end

      def build_code_classes(language)
        class_names(
          'block',
          'min-w-full',
          'font-mono',
          'text-inherit',
          'bg-transparent',
          'tracking-tight',
          language_class(language)
        )
      end

      def language_class(language)
        return if language.blank?

        "language-#{language}"
      end
    end
  end
end
