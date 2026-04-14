# frozen_string_literal: true

# Validator for Workflow Execution Samplesheet Params
class WorkflowExecutionSamplesheetParamsValidator < ActiveModel::Validator
  def validate(record)
    return unless record.workflow_execution.state == 'initial' # only validate on creation

    workflow = record.workflow_execution.workflow

    return if workflow.unknown?

    samplesheet_properties = record.workflow_execution.samplesheet_properties
    @required_properties = samplesheet_properties.required_properties
    @properties = samplesheet_properties.properties

    validate_samplesheet_params(record)
  end

  private

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

    return unless value != record.sample&.puid

    record.errors.add :samplesheet_params,
                      I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_puid_error',
                             property:)

    false
  end

  def validate_sample_name_cell(record, value, property)
    validate_required(record, value, property) if @required_properties.include?(property)

    return if value.blank?

    return unless value != record.sample&.name

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

  def validate_sample_attachment(record, attachment, property) # rubocop:disable Naming/PredicateMethod
    return true if attachment.attachable_id == record.sample_id && attachment.attachable_type == 'Sample'

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
