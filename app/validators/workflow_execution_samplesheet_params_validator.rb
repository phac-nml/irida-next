# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator # rubocop:disable Metrics/ClassLength
  def validate(record) # rubocop:disable Metrics/AbcSize
    return unless record.workflow_execution.state == 'initial' # only validate on creation

    workflow = Irida::Pipelines.instance.find_pipeline_by(record.workflow_execution.metadata['pipeline_id'],
                                                          record.workflow_execution.metadata['workflow_version'],
                                                          'available')

    return if workflow.blank?

    workflow_params = workflow.workflow_params
    samplesheet_schema = workflow_params[:input_output_options][:properties][:input][:schema]
    @required_properties = samplesheet_schema['items']['required']
    @properties = extract_properties(samplesheet_schema)

    validate_samplesheet_params(record)
  end

  private

  def extract_properties(schema)
    properties = schema['items']['properties']
    properties.each do |property, entry|
      properties[property]['required'] = schema['items']['required'].include?(property)
      properties[property]['cell_type'] = identify_cell_type(property, entry)
    end

    if @required_properties.include?('fastq_1') && @required_properties.include?('fastq_2')
      properties['fastq_1']['pe_only'] = true
    end

    properties
  end

  def identify_cell_type(property, entry)
    return 'sample_cell' if property == 'sample'

    return 'sample_name_cell' if property == 'sample_name'

    return 'fastq_cell' if property.match(/fastq_\d+/)

    return 'file_cell' if check_for_file(entry)

    return 'metadata_cell' if entry['meta'].present?

    return 'dropdown_cell' if entry['enum'].present?

    'input_cell'
  end

  def check_for_file(entry)
    entry['format'] == 'file-path' || (entry.key?('anyOf') && entry['anyOf'].any? do |e|
      e['format'] == 'file-path'
    end)
  end

  def validate_samplesheet_params(record)
    @properties.each do |property, entry|
      value = record.samplesheet_params[property]
      case entry['cell_type']
      when 'sample_cell'
        validate_sample_cell(record, value, property)
      when 'sample_name_cell'
        validate_sample_name_cell(record, value, property)
      when 'fastq_cell'
        validate_fastq_cell(record, value, property, entry)
      when 'file_cell'
        validate_file_cell(record, value, property, entry)
      end
    end
  end

  def validate_sample_cell(record, value, property)
    validate_required(record, value, property) if @required_properties.include?(property)

    return if value.blank?

    return unless value != (record.sample&.puid)

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_puid_error',
                             property:)

    false
  end

  def validate_sample_name_cell(record, value, property)
    validate_required(record, value, property) if @required_properties.include?(property)

    return if value.blank?

    return unless value != (record.sample&.name)

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_name_error', property:)

    false
  end

  def validate_fastq_cell(record, value, property, entry)
    validate_file_cell(record, value, property, entry)
  end

  def validate_file_cell(record, value, property, entry)
    validate_required(record, value, property) if @required_properties.include?(property)

    return if value.blank?

    validate_attachment(record, value, property, entry)
  end

  def validate_required(record, value, property)
    return if value.present?

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.blank_error', property:)
  end

  def validate_attachment(record, value, property, entry)
    gid = validate_attachment_gid(record, value, property)

    return if gid.blank?

    attachment = GlobalID.find(gid)
    return unless validate_sample_attachment(record, attachment, property)

    validate_attachment_format(record, attachment, property, entry)
  end

  def validate_attachment_gid(record, value, property)
    gid = GlobalID.parse(value)
    return gid if gid && gid.model_class == Attachment

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_gid_error',
                             property:)
    nil
  end

  def validate_sample_attachment(record, attachment, property)
    return true if attachment.attachable == record.sample

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_attachment_error',
                             property:)

    false
  end

  def validate_attachment_format(record, attachment, property, entry) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
    valid = true
    expected_pattern = if entry.key?('pattern')
                         entry['pattern']
                       elsif entry.key?('anyOf')
                         entry['anyOf'].select do |condition|
                           condition.key?('pattern')
                         end.pluck('pattern').join('|')
                       end

    case entry['cell_type']
    when 'fastq_cell'
      valid = attachment.fastq?
    when 'file_cell'
      valid = attachment.filename.to_s.match?(expected_pattern) if expected_pattern
    end

    return if valid

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
                             property:, file_format: expected_pattern)
  end
end
