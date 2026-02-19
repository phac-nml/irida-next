# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::FieldsTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  test 'for_samples returns options and grouped metadata fields' do
    fields = AdvancedSearch::Fields.for_samples(
      sample_fields: %w[name puid],
      metadata_fields: %w[country food]
    )

    assert_equal 2, fields[:options].count
    assert_equal [I18n.t('samples.table_component.name'), 'name'], fields[:options][0]
    assert_equal [I18n.t('samples.table_component.puid'), 'puid'], fields[:options][1]

    metadata_group_label = I18n.t('components.advanced_search_component.operation.metadata_fields')
    assert_equal [['country', 'metadata.country'], ['food', 'metadata.food']], fields[:groups][metadata_group_label]
  end

  test 'for_workflow_executions returns workflow labels and metadata grouping' do
    field_configuration = Struct.new(:fields).new(
      ['id', 'run_id', 'state', 'metadata.pipeline_id', 'metadata.workflow_version']
    )

    fields = AdvancedSearch::Fields.for_workflow_executions(field_configuration:)

    assert_includes fields[:options], [I18n.t('workflow_executions.table_component.id'), 'id']
    assert_includes fields[:options], [I18n.t('workflow_executions.table_component.run_id'), 'run_id']
    assert_includes fields[:options], [I18n.t('workflow_executions.table_component.state'), 'state']

    metadata_group_label = I18n.t('components.advanced_search_component.operation.metadata_fields')
    assert_includes fields[:groups][metadata_group_label],
                    [I18n.t('workflow_executions.table_component.workflow_name'), 'metadata.pipeline_id']
    assert_includes fields[:groups][metadata_group_label],
                    [I18n.t('workflow_executions.table_component.workflow_version'), 'metadata.workflow_version']
  end
end
