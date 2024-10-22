# frozen_string_literal: true

module Flowbite
  # This file defines the Flowbite::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Flowbite
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Flowbite::Component
    DEFAULT_SCHEME = :light

    def self.generate_scheme(color, text_color, bg_shade, focus_shade, dark_bg_shade, border = false)
      classes = [
        "text-#{text_color}",
        "bg-#{color}-#{bg_shade}",
        "focus:ring-#{color}-#{focus_shade}",
        "dark:bg-#{color}-#{dark_bg_shade}",
        "dark:focus:ring-#{color}-#{focus_shade}",
        "enabled:hover:bg-#{color}-#{bg_shade.to_i + 100}",
        "dark:enabled:hover:bg-#{color}-#{dark_bg_shade.to_i - 100}"
      ]

      classes << "border border-#{color}-#{bg_shade}" if border
      classes << "dark:border-#{color}-600" if border

      classes.join(' ')
    end

    def self.generate_scheme_mappings
      {
        primary: generate_scheme('primary', 'slate-50', '700', '300', '800'),
        blue: generate_scheme('blue', 'white', '700', '300', '600'),
        alternative: generate_scheme('gray', 'gray-900', 'white', '100', '800', true),
        dark: generate_scheme('slate', 'white', '700', '300', '700'),
        light: generate_scheme('slate', 'slate-900', 'white', '100', '800', true),
        green: generate_scheme('green', 'white', '600', '300', '500'),
        red: generate_scheme('red', 'white', '600', '300', '500'),
        yellow: generate_scheme('yellow', 'slate-900', '300', '300', '300'),
        purple: generate_scheme('purple', 'white', '600', '300', '500')
      }.freeze
    end

    SCHEME_MAPPINGS = generate_scheme_mappings
    SCHEME_OPTIONS = SCHEME_MAPPINGS.keys

    DEFAULT_SIZE = :default
    SIZE_MAPPINGS = {
      extra_small: 'px-3 py-2 text-xs',
      small: 'px-3 py-2 text-sm',
      default: 'px-5 py-2.5 text-sm',
      large: 'px-5 py-3 text-base',
      extra_large: 'px-6 py-3.5 text-base'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys

    DEFAULT_ALIGN_CONTENT = :center
    ALIGN_CONTENT_MAPPINGS = {
      :start => 'Button-content--alignStart',
      :center => '',
      DEFAULT_ALIGN_CONTENT => ''
    }.freeze
    ALIGN_CONTENT_OPTIONS = ALIGN_CONTENT_MAPPINGS.keys

    ICON_SIZE_MAPPINGS = {
      extra_small: 'w-3 h-3',
      small: 'w-3 h-3',
      default: 'w-3.5 h-3.5',
      large: 'w-4 h-4',
      extra_large: 'w-4 h-4'
    }.freeze

    renders_one :leading_visual, types: {
      icon: lambda { |**args|
        args[:class] = class_names(
          args[:class],
          ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE)],
          'me-2'
        )
        Flowbite::Icon.new(**args)
      },
      svg: lambda { |**system_arguments|
        Flowbite::BaseComponent.new(tag: :span,
                                    classes: class_names(
                                      ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE)],
                                      'me-2'
                                    ),
                                    **system_arguments)
      }
    }

    renders_one :trailing_visual, types: {
      icon: lambda { |**args|
        args[:class] =
          class_names(args[:class], ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE)],
                      'ms-2 min-w-4')
        Flowbite::Icon.new(**args)
      },
      svg: lambda { |**system_arguments|
        Flowbite::BaseComponent.new(tag: :span,
                                    classes: class_names(
                                      ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE)],
                                      'ms-2'
                                    ),
                                    **system_arguments)
      }
    }

    def initialize(base_button_class: Flowbite::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE,
                   align_content: DEFAULT_ALIGN_CONTENT, disabled: false, label_wrap: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @label_wrap = label_wrap
      @size = size

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        SCHEME_MAPPINGS[fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)],
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        'rounded-lg font-medium focus:outline-none focus:ring-4 disabled:opacity-50 disabled:cursor-not-allowed'
      )
    end

    def before_render
      return unless leading_visual.present? || trailing_visual.present?

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'text-center inline-flex items-center'
      )
    end

    private

    # Trims the content by removing leading and trailing whitespace.
    # If the content is blank, returns nil.
    # If the content is marked as HTML safe, ensures the trimmed content remains HTML safe.
    #
    # @return [String, nil] The trimmed content, or nil if the content is blank.
    def trimmed_content
      return if content.blank?

      trimmed_content = content.strip

      return trimmed_content unless content.html_safe?

      # strip unsets `html_safe`, so we have to set it back again to guarantee that HTML blocks won't break
      trimmed_content.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
