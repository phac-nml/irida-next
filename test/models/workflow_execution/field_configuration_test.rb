# frozen_string_literal: true

require 'test_helper'

class WorkflowExecution
  class FieldConfigurationTest < ActiveSupport::TestCase
    # Mock pipeline for testing
    MockPipeline = Struct.new(:pipeline_id, :name, :version)

    def setup
      @pipelines = [
        MockPipeline.new('phac-nml/iridanext-example', 'IRIDA Next Example', '1.0.0'),
        MockPipeline.new('phac-nml/gasclustering', 'GAS Clustering', '2.0.0'),
        MockPipeline.new('phac-nml/unnamed', nil, '1.5.0')
      ]
      @config = WorkflowExecution::FieldConfiguration.new(pipelines: @pipelines)
    end

    # #fields tests
    test 'fields returns all searchable fields' do
      fields = @config.fields
      assert_includes fields, 'id'
      assert_includes fields, 'name'
      assert_includes fields, 'run_id'
      assert_includes fields, 'state'
      assert_includes fields, 'created_at'
      assert_includes fields, 'updated_at'
      assert_includes fields, 'metadata.pipeline_id'
      assert_includes fields, 'metadata.workflow_version'
    end

    test 'fields returns a duplicate not the original constant' do
      fields1 = @config.fields
      fields2 = @config.fields
      assert_not_same fields1, fields2
      assert_not_same fields1, WorkflowExecution::FieldConfiguration::SEARCHABLE_FIELDS
    end

    # #enum_fields tests
    test 'enum_fields returns hash with state field' do
      enum_fields = @config.enum_fields
      assert enum_fields.key?('state')
    end

    test 'enum_fields returns hash with pipeline_id field' do
      enum_fields = @config.enum_fields
      assert enum_fields.key?('metadata.pipeline_id')
    end

    test 'enum_fields returns hash with workflow_version field' do
      enum_fields = @config.enum_fields
      assert enum_fields.key?('metadata.workflow_version')
    end

    # state_config tests
    test 'state config includes all workflow execution states' do
      state_config = @config.enum_fields['state']
      WorkflowExecution.states.each_key do |state|
        assert_includes state_config[:values], state
      end
    end

    test 'state config has correct translation key' do
      state_config = @config.enum_fields['state']
      assert_equal 'workflow_executions.state', state_config[:translation_key]
    end

    # pipeline_id_config tests
    test 'pipeline_id config uses pipeline names as labels' do
      pipeline_config = @config.enum_fields['metadata.pipeline_id']
      assert_equal 'IRIDA Next Example', pipeline_config[:labels]['phac-nml/iridanext-example']
      assert_equal 'GAS Clustering', pipeline_config[:labels]['phac-nml/gasclustering']
    end

    test 'pipeline_id config falls back to pipeline_id when name is blank' do
      pipeline_config = @config.enum_fields['metadata.pipeline_id']
      assert_equal 'phac-nml/unnamed', pipeline_config[:labels]['phac-nml/unnamed']
    end

    test 'pipeline_id config includes all pipeline ids in values' do
      pipeline_config = @config.enum_fields['metadata.pipeline_id']
      assert_includes pipeline_config[:values], 'phac-nml/iridanext-example'
      assert_includes pipeline_config[:values], 'phac-nml/gasclustering'
      assert_includes pipeline_config[:values], 'phac-nml/unnamed'
    end

    test 'pipeline_id config skips pipelines with blank pipeline_id' do
      pipelines_with_blank = [
        MockPipeline.new('', 'Empty ID', '1.0.0'),
        MockPipeline.new(nil, 'Nil ID', '1.0.0'),
        MockPipeline.new('valid/id', 'Valid', '1.0.0')
      ]
      config = WorkflowExecution::FieldConfiguration.new(pipelines: pipelines_with_blank)
      pipeline_config = config.enum_fields['metadata.pipeline_id']

      assert_equal ['valid/id'], pipeline_config[:values]
      assert_equal({ 'valid/id' => 'Valid' }, pipeline_config[:labels])
    end

    # workflow_version_config tests
    test 'workflow_version config includes all versions' do
      version_config = @config.enum_fields['metadata.workflow_version']
      assert_includes version_config[:values], '1.0.0'
      assert_includes version_config[:values], '2.0.0'
      assert_includes version_config[:values], '1.5.0'
    end

    test 'workflow_version config uses version as label' do
      version_config = @config.enum_fields['metadata.workflow_version']
      assert_equal '1.0.0', version_config[:labels]['1.0.0']
      assert_equal '2.0.0', version_config[:labels]['2.0.0']
    end

    test 'workflow_version config skips blank versions' do
      pipelines_with_blank_version = [
        MockPipeline.new('p1', 'P1', ''),
        MockPipeline.new('p2', 'P2', nil),
        MockPipeline.new('p3', 'P3', '3.0.0')
      ]
      config = WorkflowExecution::FieldConfiguration.new(pipelines: pipelines_with_blank_version)
      version_config = config.enum_fields['metadata.workflow_version']

      assert_equal ['3.0.0'], version_config[:values]
    end

    test 'workflow_version config deduplicates versions' do
      pipelines_with_dups = [
        MockPipeline.new('p1', 'P1', '1.0.0'),
        MockPipeline.new('p2', 'P2', '1.0.0'),
        MockPipeline.new('p3', 'P3', '2.0.0')
      ]
      config = WorkflowExecution::FieldConfiguration.new(pipelines: pipelines_with_dups)
      version_config = config.enum_fields['metadata.workflow_version']

      assert_equal 2, version_config[:values].length
      assert_includes version_config[:values], '1.0.0'
      assert_includes version_config[:values], '2.0.0'
    end

    # Empty pipelines edge case
    test 'handles empty pipelines list gracefully' do
      config = WorkflowExecution::FieldConfiguration.new(pipelines: [])

      pipeline_config = config.enum_fields['metadata.pipeline_id']
      assert_equal [], pipeline_config[:values]
      assert_equal({}, pipeline_config[:labels])

      version_config = config.enum_fields['metadata.workflow_version']
      assert_equal [], version_config[:values]
      assert_equal({}, version_config[:labels])
    end
  end
end
