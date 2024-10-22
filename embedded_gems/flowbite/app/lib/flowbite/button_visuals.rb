# frozen_string_literal: true

module Flowbite
  module ButtonVisuals
    # Default size for buttons
    DEFAULT_SIZE = :default

    # A hash of predefined button size mappings
    SIZE_MAPPINGS = {
      extra_small: 'px-3 py-2 text-xs',
      small: 'px-3 py-2 text-sm',
      default: 'px-5 py-2.5 text-sm',
      large: 'px-5 py-3 text-base',
      extra_large: 'px-6 py-3.5 text-base'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys

    # A hash of predefined icon size mappings
    ICON_SIZE_MAPPINGS = {
      extra_small: 'w-3 h-3',
      small: 'w-3 h-3',
      default: 'w-3.5 h-3.5',
      large: 'w-4 h-4',
      extra_large: 'w-4 h-4'
    }.freeze

    def self.included(base)
      base.renders_one :leading_visual, types: {
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
                                        ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size,
                                                                             DEFAULT_SIZE)],
                                        'me-2'
                                      ),
                                      **system_arguments)
        }
      }

      base.renders_one :trailing_visual, types: {
        icon: lambda { |**args|
          args[:class] =
            class_names(args[:class], ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size, DEFAULT_SIZE)],
                        'ms-2 min-w-4')
          Flowbite::Icon.new(**args)
        },
        svg: lambda { |**system_arguments|
          Flowbite::BaseComponent.new(tag: :span,
                                      classes: class_names(
                                        ICON_SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, @size,
                                                                             DEFAULT_SIZE)],
                                        'ms-2'
                                      ),
                                      **system_arguments)
        }
      }
    end
  end
end
