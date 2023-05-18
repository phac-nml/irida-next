# frozen_string_literal: true

module Viral
  class ButtonComponent < Viral::Component
    attr_reader :primary, :tag, :url

    TYPE_DEFAULT = :default
    TYPE_MAPPINGS = {
      TYPE_DEFAULT => 'text-gray-900 bg-white border border-gray-300 focus:outline-none hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg dark:bg-gray-800 dark:text-white dark:border-gray-600 dark:hover:bg-gray-700 dark:hover:border-gray-600 dark:focus:ring-gray-700',
      :primary => 'text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg dark:bg-blue-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800',
      :destructive => 'focus:outline-none text-white bg-red-700 hover:bg-red-800 focus:ring-4 focus:ring-red-300 font-medium rounded-lg dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-900'
    }.freeze

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      :small => 'px-3 py-2 text-xs font-medium',
      SIZE_DEFAULT => 'px-3 py-2 text-sm font-medium',
      :large => 'text-sm px-5 py-2.5 font-medium'
    }.freeze

    def initialize(url: nil, type: TYPE_DEFAULT, size: SIZE_DEFAULT, full_width: false, **system_arguments)
      @tag = url.present? ? 'a' : 'button'
      @system_arguments = system_arguments

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        TYPE_MAPPINGS[type],
        SIZE_MAPPINGS[size],
        'w-full': full_width
      )
    end
  end
end
