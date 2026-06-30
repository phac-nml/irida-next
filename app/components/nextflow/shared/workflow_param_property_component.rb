# frozen_string_literal: true

module Nextflow
  module Shared
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
      end
    end
  end
end
