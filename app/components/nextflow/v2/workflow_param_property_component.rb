# frozen_string_literal: true

module Nextflow
  module V2
    # Render a single workflow parameter property input shared across nextflow form versions.
    class WorkflowParamPropertyComponent < Component
      include NextflowHelper

      attr_reader :fields, :name, :property, :instance, :namespace_id, :namespace_type

      def initialize(fields:, name:, property:, instance:, namespace_id:, namespace_type:) # rubocop:disable Metrics/ParameterLists
        @fields = fields
        @name = name
        @property = property
        @instance = instance
        @namespace_id = namespace_id
        @namespace_type = namespace_type

        setup_ids(@name)
      end

      private

      def setup_ids(name)
        @help_text_id = fields.field_id(name, 'help')
        @legend_id = fields.field_id(name, 'legend')
        @prefix_id = fields.field_id(name, 'prefix')
      end

      # Matches the asterisk indicator PathogenFormBuilder#label renders for data-required fields,
      # for use on legends which aren't passed through PathogenFormBuilder#label.
      def required_indicator
        tag.abbr(
          t('pathogen.label.required_indicator'),
          class: 'req',
          title: t('pathogen.label.title'),
          aria: { hidden: true }
        )
      end
    end
  end
end
