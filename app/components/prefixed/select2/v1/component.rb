# frozen_string_literal: true

module Prefixed
  module Select2
    module V1
      # Select2 component with a prefix
      class Component < ::Component
        attr_reader :form, :id, :name, :selected_value, :placeholder, :required, :path_separator, :aria

        renders_many :options, Select2::V1::OptionComponent
        renders_one :empty_state

        # rubocop:disable Metrics/ParameterLists
        def initialize(form:, id:, name:, selected_value: false, path_separator: true, **options)
          @form = form
          @name = name
          @id = id
          @selected_value = selected_value
          @placeholder = options[:placeholder]
          @required = options[:required]
          @path_separator = path_separator
          @aria = options[:aria]
          options.delete(:aria)
        end
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
