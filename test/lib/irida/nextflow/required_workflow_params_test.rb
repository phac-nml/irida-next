# frozen_string_literal: true

require 'test_helper'

module Irida
  module Nextflow
    class RequiredWorkflowParamsTest < ActiveSupport::TestCase
      def setup
        @required_params = RequiredWorkflowParams.new(
          input_output_options: { properties: {
            input: { type: 'string', format: 'file-path', required: true }
          } },
          options: { properties: {
            project_name: { type: 'string', required: true },
            count: { type: 'integer', required: true },
            enabled: { type: 'boolean', required: true },
            platform: { type: 'string', required: true, default: 'illumina' },
            optional: { type: 'string', required: false }
          } }
        )
      end

      test 'returns required params that are missing or blank' do
        assert_equal %i[project_name count enabled], @required_params.missing({ 'project_name' => '   ' })
      end

      test 'accepts zero and false as values' do
        assert_empty @required_params.missing({ project_name: 'test', count: 0, enabled: false })
      end

      test 'treats an omitted param with a schema default as present' do
        missing = @required_params.missing({ project_name: 'test', count: 1, enabled: true })

        assert_not_includes missing, :platform
        assert_includes @required_params.missing({ platform: '' }), :platform
      end

      test 'ignores the generated samplesheet input param' do
        assert_not_includes @required_params.missing({}), :input
      end
    end
  end
end
