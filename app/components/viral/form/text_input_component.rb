# frozen_string_literal: true

module Viral
  module Form
    class TextInputComponent < Viral::Component
      attr_reader :help, :helper_id, :label, :name, :tag, :type, :input_attributes

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, label:, type: 'string', help: nil, pattern: nil, required: false)
        @label = label
        @help = help
        @tag = 'input'
        @helper_id = "help-#{SecureRandom.hex(10)}" if help.present?
        @type = input_type(type)
        @input_attributes = {
          pattern:,
          name:,
          required:,
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
        else
          'text'
        end
      end
    end
  end
end
