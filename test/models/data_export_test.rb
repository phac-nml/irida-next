# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
    @project1 = projects(:project1)
    @sample1 = samples(:sample1)
    @user = users(:john_doe)
    @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
  end

  test 'valid sample data export' do
    assert_equal 'sample', @export1.export_type
    assert @export1.valid?
  end

  test 'valid analysis data export' do
    export6 = data_exports(:data_export_six)
    assert_equal 'analysis', export6.export_type
    assert export6.valid?
  end

  test 'valid linelist project data export' do
    export8 = data_exports(:data_export_eight)
    assert_equal Namespaces::ProjectNamespace.sti_name, Namespace.find(export8.export_parameters['namespace_id']).type
    assert_equal 'linelist', export8.export_type
    assert export8.valid?
  end

  test 'valid linelist group data export' do
    export9 = data_exports(:data_export_nine)
    assert_equal Group.sti_name, Namespace.find(export9.export_parameters['namespace_id']).type
    assert_equal 'linelist', export9.export_type
    assert export9.valid?
  end

  test 'attach zip to export' do
    @export1.file.attach(io: Rails.root.join('test/fixtures/files/data_export_1.zip').open,
                         filename: 'data_export_1.zip')
    @export1.save
    assert_equal 'data_export_1.zip', @export1.file.filename.to_s
  end

  test 'data export with invalid status' do
    data_export = DataExport.new(user: @user, status: 'invalid status', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id], namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })
    assert_not data_export.valid?
    data_export.status = 'processing'
    assert data_export.valid?
  end

  test 'data export with invalid export_type' do
    data_export = DataExport.new(user: @user, status: 'ready', export_type: 'invalid type',
                                 export_parameters: { ids: [@workflow_execution.id], analysis_type: 'user' })
    assert_not data_export.valid?
    data_export.export_type = 'analysis'
    assert data_export.valid?
  end

  test '#destroy removes export' do
    assert_difference(-> { DataExport.count } => -1) do
      @export1.destroy
    end
  end

  test 'data export with missing export_type' do
    data_export = DataExport.new(user: @user, status: 'ready',
                                 export_parameters: { ids: [@sample1.id] })
    assert_not data_export.valid?
  end

  test 'data export with missing export_parameters' do
    data_export = DataExport.new(user: @user, status: 'ready', export_type: 'sample')
    assert_not data_export.valid?
  end

  test 'export with missing ids' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'analysis',
                                 export_parameters: { not_ids: [@workflow_execution.id], analysis_type: 'user' })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_ids'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing metadata fields' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], linelist_format: 'xlsx',
                                                      namespace_id: @project1.namespace.id })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_metadata_fields'),
                 data_export.errors[:export_parameters].first
  end

  test 'sample export with missing namespace_id' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_id'),
                 data_export.errors[:export_parameters].first
  end

  test 'sample export with invalid namespace_id' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id], namespace_id: 'invalid_namespace_id',
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing namespace_id' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], linelist_format: 'xlsx',
                                                      metadata_fields: ['a_metadata_field'] })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_id'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with invalid namespace_type' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], linelist_format: 'csv',
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_id: 'invalid_namespace_id' })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_id'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing linelist_format' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id],
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_id: @project1.namespace.id })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_file_format'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with invalid linelist_format' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], linelist_format: 'invalid_format',
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_id: @project1.namespace.id })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'),
                 data_export.errors[:export_parameters].first
  end

  test 'sample export with valid attachment_formats' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })

    assert data_export.valid?
  end

  test 'sample export with invalid formats' do
    invalid_formats = %w[invalid_format_a invalid_format_b]
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      attachment_formats: invalid_formats })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
                        invalid_formats: invalid_formats.join(', ')),
                 data_export.errors[:export_parameters].first
  end

  test 'sample export with valid and invalid formats' do
    formats = %w[fasta fastq invalid_format_a invalid_format_b]
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      attachment_formats: formats })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_attachment_format',
                        invalid_formats: (formats - Attachment::FORMAT_REGEX.keys).join(', ')),
                 data_export.errors[:export_parameters].first
  end

  test 'sample export without attachment_formats param' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id })
    assert_not data_export.valid?
    assert_equal I18n.t(
      'activerecord.errors.models.data_export.attributes.export_parameters.missing_attachment_formats'
    ), data_export.errors[:export_parameters].first
  end

  test 'analysis export without analysis_type param' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'analysis',
                                 export_parameters: { ids: [@workflow_execution.id] })
    assert_not data_export.valid?
    assert_equal I18n.t(
      'activerecord.errors.models.data_export.attributes.export_parameters.missing_analysis_type'
    ), data_export.errors[:export_parameters].first
  end

  test 'analysis export with invalid analysis_type param' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'analysis',
                                 export_parameters: { ids: [@workflow_execution.id], analysis_type: 'invalid_type' })
    assert_not data_export.valid?
    assert_equal I18n.t(
      'activerecord.errors.models.data_export.attributes.export_parameters.invalid_analysis_type'
    ), data_export.errors[:export_parameters].first
  end

  test 'turbo stream broadcasts' do
    user = users(:john_doe)
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id], namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })

    assert_no_turbo_stream_broadcasts [user, :data_exports]

    assert_turbo_stream_broadcasts [user, :data_exports], count: 1 do
      data_export.save
    end
  end
end
