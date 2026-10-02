# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionSamplesheetParamsValidatorTest < ActiveSupport::TestCase
  SAMPLE_CELL = { 'cell_type' => 'sample_cell' }.freeze
  SAMPLE_NAME_CELL = { 'cell_type' => 'sample_name_cell' }.freeze
  FASTQ_CELL = {
    'cell_type' => 'fastq_cell',
    'pattern' => '^\\S+\\.f(ast)?q(\\.gz)?$'
  }.freeze
  FILE_CELL = {
    'cell_type' => 'file_cell',
    'pattern' => '^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$'
  }.freeze

  setup do
    @sample = samples(:sample1)
    @validator = WorkflowExecutionSamplesheetParamsValidator.new
  end

  test 'skips validation for non-initial workflow executions' do
    record = build_record(
      state: 'prepared',
      properties: { 'sample' => SAMPLE_CELL },
      required_properties: ['sample'],
      samplesheet_params: { 'sample' => 'wrong-sample' }
    )

    validate(record)

    assert_empty record.errors
  end

  test 'skips validation for unknown workflows' do
    record = build_record(
      unknown: true,
      properties: { 'sample' => SAMPLE_CELL },
      required_properties: ['sample'],
      samplesheet_params: { 'sample' => 'wrong-sample' }
    )

    validate(record)

    assert_empty record.errors
  end

  test 'requires values for required sample, sample name, and file cells' do
    record = build_record(
      properties: {
        'sample' => SAMPLE_CELL,
        'sample_name' => SAMPLE_NAME_CELL,
        'fastq_1' => FASTQ_CELL,
        'input_file' => FILE_CELL
      },
      required_properties: %w[sample sample_name fastq_1 input_file],
      samplesheet_params: {}
    )

    validate(record)

    assert_equal 4, record.errors.count
    assert_includes record.errors.full_messages.join, 'is required and cannot be blank'
  end

  test 'rejects a sample and sample name that do not identify the record sample' do
    record = build_record(
      properties: {
        'sample' => SAMPLE_CELL,
        'sample_name' => SAMPLE_NAME_CELL
      },
      samplesheet_params: {
        'sample' => 'wrong-sample',
        'sample_name' => 'wrong-name'
      }
    )

    validate(record)

    assert_equal 2, record.errors.count
    assert_includes record.errors.full_messages.join, 'must match Sample'
  end

  test 'accepts a matching sample and optional blank file cells' do
    record = build_record(
      properties: {
        'sample' => SAMPLE_CELL,
        'sample_name' => SAMPLE_NAME_CELL,
        'fastq_1' => FASTQ_CELL,
        'fastq_2' => FASTQ_CELL,
        'metadata_1' => { 'cell_type' => 'metadata_cell' }
      },
      required_properties: %w[sample fastq_1],
      samplesheet_params: {
        'sample' => @sample.puid,
        'sample_name' => @sample.name,
        'fastq_1' => attachments(:attachment1).to_global_id.to_s,
        'fastq_2' => '',
        'metadata_1' => 'value'
      }
    )

    validate(record)

    assert_empty record.errors
  end

  test 'rejects attachment values that are not Attachment global IDs' do
    record = build_record(
      properties: { 'fastq_1' => FASTQ_CELL },
      samplesheet_params: { 'fastq_1' => samples(:sample1).to_global_id.to_s }
    )

    validate(record)

    assert_equal 1, record.errors.count
    assert_includes record.errors.full_messages.join, 'must be a valid Attachment GID'
  end

  test 'rejects attachments belonging to another sample' do
    record = build_record(
      properties: { 'fastq_1' => FASTQ_CELL },
      samplesheet_params: { 'fastq_1' => attachments(:attachment3).to_global_id.to_s }
    )

    validate(record)

    assert_equal 1, record.errors.count
    assert_includes record.errors.full_messages.join, 'must belong to the Sample'
  end

  test 'validates FastQ and file attachment formats' do
    record = build_record(
      sample: samples(:sample3),
      properties: { 'fastq_1' => FASTQ_CELL },
      samplesheet_params: { 'fastq_1' => attachments(:attachment3).to_global_id.to_s }
    )

    validate(record)

    assert_equal 1, record.errors.count
    assert_includes record.errors.full_messages.join, 'must match the expected file format'
  end

  test 'accepts an attachment matching one of the anyOf patterns' do
    attachment = attachments(:gasclusteringAttachment)
    record = build_record(
      sample: attachment.attachable,
      properties: {
        'input_file' => {
          'cell_type' => 'file_cell',
          'anyOf' => [
            { 'type' => 'string' },
            { 'pattern' => '^\\S+\\.txt$' },
            { 'pattern' => '^\\S+\\.mlst\\.json$' }
          ]
        }
      },
      samplesheet_params: { 'input_file' => attachment.to_global_id.to_s }
    )

    validate(record)

    assert_empty record.errors
  end

  test 'accepts a file attachment when no filename pattern is specified' do
    record = build_record(
      properties: { 'input_file' => { 'cell_type' => 'file_cell' } },
      samplesheet_params: { 'input_file' => attachments(:attachment1).to_global_id.to_s }
    )

    validate(record)

    assert_empty record.errors
  end

  private

  def build_record(properties:, samplesheet_params:, sample: @sample, **workflow_options)
    state = workflow_options.fetch(:state, 'initial')
    unknown = workflow_options.fetch(:unknown, false)
    required_properties = workflow_options.fetch(:required_properties, [])
    workflow_execution = build_workflow_execution(state, unknown, properties, required_properties)

    SamplesWorkflowExecution.new(
      sample:,
      sample_id: sample.id,
      samplesheet_params:
    ).tap do |record|
      record.define_singleton_method(:workflow_execution) { workflow_execution }
    end
  end

  def build_workflow_execution(state, unknown, properties, required_properties)
    workflow = Struct.new(:unknown?).new(unknown)
    samplesheet_properties = Struct.new(:required_properties, :properties).new(
      required_properties,
      properties
    )
    Struct.new(:state, :workflow, :samplesheet_properties).new(
      state,
      workflow,
      samplesheet_properties
    )
  end

  def validate(record)
    @validator.validate(record)
  end
end
