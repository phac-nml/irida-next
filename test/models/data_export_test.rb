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
    assert data_export.valid?
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

  test 'sample export below configured source size limit is valid' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })

    max_bytes = Irida::CurrentSettings.max_data_export_size_gigabytes.gigabytes
    data_export.stubs(:source_size_bytes).returns(max_bytes - 1)

    assert data_export.valid?
  end

  test 'sample export at configured source size limit is invalid' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })

    max_gigabytes = Irida::CurrentSettings.max_data_export_size_gigabytes
    data_export.stubs(:source_size_bytes).returns(max_gigabytes.gigabytes)

    assert_not data_export.valid?
    assert_includes data_export.errors.full_messages,
                    I18n.t('services.data_exports.create.max_data_export_size_exceeded',
                           max_size_gigabytes: max_gigabytes)
  end

  test 'linelist export does not perform source size validation on create' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id],
                                                      namespace_id: @project1.namespace.id,
                                                      linelist_format: 'csv' })
    data_export.expects(:source_size_bytes).never

    assert data_export.valid?
  end

  test 'source_size_bytes totals selected attachment formats only for sample exports' do
    sample22 = samples(:sample22)
    sample3 = samples(:sample3)

    expected = sample22.attachments.select { |attachment| attachment.metadata['format'] == 'fastq' }
                                   .sum { |attachment| attachment.file.byte_size }

    data_export = DataExport.new(
      export_type: 'sample',
      export_parameters: { 'ids' => [sample22.id, sample3.id], 'attachment_formats' => ['fastq'] }
    )

    assert_equal expected, data_export.source_size_bytes
  end

  test 'source_size_bytes totals all attachments when every format is selected' do
    sample22 = samples(:sample22)

    expected = sample22.attachments.sum { |attachment| attachment.file.byte_size }

    data_export = DataExport.new(
      export_type: 'sample',
      export_parameters: { 'ids' => [sample22.id], 'attachment_formats' => Attachment::FORMAT_REGEX.keys }
    )

    assert_equal expected, data_export.source_size_bytes
  end

  test 'source_size_bytes totals zero when no formats are selected' do
    data_export = DataExport.new(
      export_type: 'sample',
      export_parameters: { 'ids' => [@sample1.id], 'attachment_formats' => [] }
    )

    assert_equal 0, data_export.source_size_bytes
  end

  test 'source_size_bytes totals workflow and per-sample outputs for analysis exports' do
    workflow_output_size = @workflow_execution.outputs.sum { |output| output.file.byte_size }
    sample_output_size = @workflow_execution.samples_workflow_executions.sum do |samples_workflow_execution|
      samples_workflow_execution.outputs.sum { |output| output.file.byte_size }
    end

    data_export = DataExport.new(
      export_type: 'analysis',
      export_parameters: { 'ids' => [@workflow_execution.id] }
    )

    assert_equal workflow_output_size + sample_output_size, data_export.source_size_bytes
  end

  test 'source_size_bytes returns zero when export has no source files' do
    workflow_execution = workflow_executions(:workflow_execution_valid)

    data_export = DataExport.new(
      export_type: 'analysis',
      export_parameters: { 'ids' => [workflow_execution.id] }
    )

    assert_equal 0, data_export.source_size_bytes
  end

  test 'source_size_bytes returns zero for linelist exports' do
    data_export = DataExport.new(
      export_type: 'linelist',
      export_parameters: { 'ids' => [@sample1.id] }
    )

    assert_equal 0, data_export.source_size_bytes
  end

  test 'source_size_bytes counts the same blob more than once when copied more than once' do
    source_blob = attachments(:attachment1).file.blob
    sample_one = sample_with_attached_blob('duplicate-source-size-one', source_blob)
    sample_two = sample_with_attached_blob('duplicate-source-size-two', source_blob)

    data_export = DataExport.new(
      export_type: 'sample',
      export_parameters: {
        'ids' => [sample_one.id, sample_two.id],
        'attachment_formats' => ['fastq']
      }
    )

    assert_equal source_blob.byte_size * 2, data_export.source_size_bytes
  end

  test 'turbo stream broadcasts' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id], namespace_id: @project1.namespace.id,
                                                      attachment_formats: Attachment::FORMAT_REGEX.keys })

    assert_no_turbo_stream_broadcasts [@user, :data_exports]

    assert_turbo_stream_broadcasts [@user, :data_exports], count: 1 do
      data_export.save
    end
  end

  private

  def sample_with_attached_blob(name, blob)
    sample = Sample.create!(project: projects(:project1), name:)
    attachment = Attachment.new(attachable: sample, metadata: { 'compression' => 'none', 'format' => 'fastq' })
    attachment.file.attach(blob)
    attachment.save!
    sample
  end
end
