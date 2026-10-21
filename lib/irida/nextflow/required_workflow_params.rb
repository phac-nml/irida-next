# frozen_string_literal: true

module Irida
  module Nextflow
    # Finds the required workflow params a submission is missing, given a pipeline's processed
    # workflow param definitions (see Irida::Pipeline#workflow_params).
    class RequiredWorkflowParams
      def initialize(definitions)
        @definitions = definitions
      end

      # @param workflow_params [Hash] submitted workflow params
      # @return [Array<Symbol>] names of required params that are blank and have no default
      def missing(workflow_params)
        params = (workflow_params || {}).to_h.with_indifferent_access

        @definitions.flat_map do |section, definition|
          definition[:properties].filter_map do |name, property|
            name if user_supplied?(section, name, property) && !value_present?(property, params[name])
          end
        end
      end

      private

      def user_supplied?(section, name, property)
        return false unless property[:required]

        # the samplesheet input is generated during preparation, not submitted by the user
        !(section == :input_output_options && name == :input)
      end

      def value_present?(property, value)
        # Nextflow applies the schema default when a param is omitted
        value = property[:default] if value.nil?
        value.present? || value == false
      end
    end
  end
end
