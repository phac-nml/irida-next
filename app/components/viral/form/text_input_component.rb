# frozen_string_literal: true

module Viral
  module Form
    class TextInputComponent < Viral::Component
      attr_reader :help, :helper_id, :label, :name, :tag, :type, :hidden, :input_attributes

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label:, type: 'string', default: nil, help: nil, pattern: nil, required: false,
                     hidden: false, **_options)
        @label = label
        @help = help
        @tag = 'input'
        @helper_id = "help-#{SecureRandom.hex(10)}" if help.present?
        @type = input_type(type)
        @hidden = hidden
        @input_attributes = {
          pattern:,
          name:,
          required:,
          value: default,
          aria: { describedby: help.present? ? 'error' : nil },
          data: {
            form_validation_target: 'input'
          }
        }
      end

      def input_type(type)
        case type
        when 'string'
          'text'
        when 'integer'
          'number'
        when 'boolean'
          'checkbox'
        when 'object'
          'select'
        else
          'help'
        end
      end
    end
  end
end
