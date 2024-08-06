# frozen_string_literal: true

require 'test_helper'

module DataExports
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @project1 = projects(:project1)
      @workflow_execution1 = workflow_executions(:workflow_execution_valid)
      @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    end

    test 'create data export with valid sample export params' do
      valid_params = { 'export_type' => 'sample',
                       'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                'namespace_id' => @project1.namespace.id } }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'cannot create data export with incorrect export_type param' do
      invalid_params = { 'export_type' => 'invalid',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_not data_export.valid?
      end
    end

    test 'cannot create data export with invalid sample id' do
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [99_999_999_999_999],
                                                  'namespace_id' => @project1.namespace.id } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_export_samples'),
                     data_export.errors.full_messages.first
      end
    end

    test 'cannot create data export with both valid and invalid sample ids' do
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id, 99_999_999_999_999],
                                                  'namespace_id' => @project1.namespace.id } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_export_samples'),
                     data_export.errors.full_messages.first
      end
    end

    test 'valid authorization to create sample export' do
      valid_params = { 'export_type' => 'sample',
                       'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                'namespace_id' => @project1.namespace.id } }

      assert_authorized_to(:export_sample_data?, @project1.namespace, with: Namespaces::ProjectNamespacePolicy,
                                                                      context: { user: @user }) do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'data export with valid parameters but unauthorized for sample project' do
      valid_params = { 'export_type' => 'sample',
                       'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                'namespace_id' => @project1.namespace.id } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        DataExports::CreateService.new(user, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :export_sample_data?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.export_sample_data?',
                          name: @project1.name),
                   exception.result.message
    end

    test 'create data export with valid workflow execution export params' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'cannot create data export with invalid workflow execution id' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [99_999_999_999_999] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_workflow_execution_id'),
                     data_export.errors.full_messages.first
      end
    end

    test 'cannot create data export with more than 1 id' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [@workflow_execution1.id, @workflow_execution2.id] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_workflow_execution_id_count'),
                     data_export.errors.full_messages.first
      end
    end

    test 'cannot create analysis export with no ids' do
      invalid_params = { 'export_type' => 'analysis',
                         'export_parameters' => { 'ids' => [] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_workflow_execution_id_count'),
                     data_export.errors.full_messages.first
      end
    end

    test 'valid authorization to create workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }

      assert_authorized_to(:export_workflow_execution_data?, @workflow_execution1, with: WorkflowExecutionPolicy,
                                                                                   context: { user: @user }) do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'analyst authorized to create workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }
      user = users(:james_doe)

      assert_authorized_to(:export_workflow_execution_data?, @workflow_execution1, with: WorkflowExecutionPolicy,
                                                                                   context: { user: }) do
        DataExports::CreateService.new(user, valid_params).execute
      end
    end

    test 'guest unauthorized to create workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }
      user = users(:ryan_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::CreateService.new(user, valid_params).execute }
    end

    test 'data export with valid parameters but unauthorized for workflow execution export' do
      valid_params = { 'export_type' => 'analysis',
                       'export_parameters' => { 'ids' => [@workflow_execution1.id] } }
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::CreateService.new(user, valid_params).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        DataExports::CreateService.new(user, valid_params).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :export_workflow_execution_data?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.export_workflow_execution_data?',
                          id: @workflow_execution1.id),
                   exception.result.message
    end

    test 'create valid csv linelist data export and namespace_type group' do
      sample32 = samples(:sample32)
      sample33 = samples(:sample33)
      group12 = groups(:group_twelve)

      valid_params = {
        'export_type' => 'linelist',
        'export_parameters' => {
          'ids' => [sample32.id, sample33.id],
          'linelist_format' => 'csv',
          'namespace_id' => group12.id,
          'metadata_fields' => %w[metadatafield1 metadatafield2]
        }
      }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create valid xlsx linelist data export and namespace_type project' do
      valid_params = {
        'export_type' => 'linelist',
        'export_parameters' => {
          'ids' => [@sample1.id, @sample2.id],
          'linelist_format' => 'xlsx',
          'namespace_id' => @project1.namespace.id,
          'metadata_fields' => %w[metadatafield1 metadatafield2]
        }
      }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'cannot create sample export using samples the user is not authorized to export via group links' do
      user = users(:david_doe)
      group4 = groups(:david_doe_group_four)
      invalid_params = {
        'export_type' => 'sample',
        'export_parameters' => {
          'ids' => [@sample1.id, @sample2.id],
          'namespace_id' => group4.id
        }
      }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_export_samples'),
                     data_export.errors.full_messages.first
      end
    end

    test 'cannot create linelist export using samples user is not authorized to export via group links' do
      user = users(:david_doe)
      group4 = groups(:david_doe_group_four)
      invalid_params = {
        'export_type' => 'linelist',
        'export_parameters' => {
          'ids' => [@sample1.id, @sample2.id],
          'namespace_id' => group4.id,
          'linelist_format' => 'xlsx',
          'metadata_fields' => %w[metadatafield1 metadatafield2]
        }
      }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(user, invalid_params).execute
        assert_equal I18n.t('services.data_exports.create.invalid_export_samples'),
                     data_export.errors.full_messages.first
      end
    end

    test 'create sample data export with valid attachment_formats' do
      valid_params = { 'export_type' => 'sample',
                       'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                'namespace_id' => @project1.namespace.id,
                                                'attachment_formats' => %w[fastq fasta text] } }

      assert_difference -> { DataExport.count } => 1 do
        DataExports::CreateService.new(@user, valid_params).execute
      end
    end

    test 'sample data export with missing namespace_id' do
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'attachment_formats' => %w[genbank tsv csv] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_id'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'sample data export with invalid namespace_id' do
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => 'invalid_id',
                                                  'attachment_formats' => %w[unknown json spreadsheet] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'linelist data export with missing namespace_id' do
      invalid_params = { 'export_type' => 'linelist',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'linelist_format' => 'csv',
                                                  'metadata_fields' => %w[metadatafield1 metadatafield2] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_id'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'linelist data export with invalid namespace_id' do
      invalid_params = { 'export_type' => 'linelist',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => 'invalid_id',
                                                  'linelist_format' => 'xlsx',
                                                  'metadata_fields' => %w[metadatafield1 metadatafield2] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'linelist data export with missing metadata_fields' do
      invalid_params = { 'export_type' => 'linelist',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id,
                                                  'linelist_format' => 'xlsx' } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.missing_metadata_fields'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'linelist data export with missing format' do
      invalid_params = { 'export_type' => 'linelist',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id,
                                                  'metadata_fields' => %w[metadatafield1 metadatafield2] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.missing_file_format'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'linelist data export with invalid format' do
      invalid_params = { 'export_type' => 'linelist',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id,
                                                  'linelist_format' => 'invalid_format',
                                                  'metadata_fields' => %w[metadatafield1 metadatafield2] } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'sample data export with invalid attachment_formats' do
      invalid_formats = %w[invalid_format_a invalid_format_b]
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id,
                                                  'attachment_formats' => invalid_formats } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
          invalid_formats: invalid_formats.join(', ')
        ), data_export.errors[:export_parameters].first
      end
    end

    test 'sample data export with valid and invalid attachment_formats' do
      formats = %w[invalid_format_a invalid_format_b text fasta fastq]
      invalid_params = { 'export_type' => 'sample',
                         'export_parameters' => { 'ids' => [@sample1.id, @sample2.id],
                                                  'namespace_id' => @project1.namespace.id,
                                                  'attachment_formats' => formats } }

      assert_no_difference -> { DataExport.count } do
        data_export = DataExports::CreateService.new(@user, invalid_params).execute
        assert_equal I18n.t(
          'activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
          invalid_formats: (formats - Attachment::FORMAT_REGEX.keys).join(', ')
        ), data_export.errors[:export_parameters].first
      end
    end
  end
end
