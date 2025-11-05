# frozen_string_literal: true

require 'test_helper'

class SamplesWorkflowExecutionsTest < ActiveSupport::TestCase
  def setup
    @samples_workflow_executions_valid =
      samples_workflow_executions(:samples_workflow_executions_valid)
    @samples_workflow_executions_mismatch_file_id =
      samples_workflow_executions(:samples_workflow_executions_mismatch_file_id)
  end

  test 'valid samples workflow executions' do
    assert @samples_workflow_executions_valid.valid?
  end

  test 'invalid mismatch puid' do
    samples_workflow_executions_invalid_mismatch_sample_puid = SamplesWorkflowExecution.new(
      sample_id: samples(:sample1).id,
      workflow_execution_id: workflow_executions(:workflow_execution_valid).id,
      samplesheet_params: {
        sample: 'INXT_SAM_AAAAAAAAAB',
        fastq_1: attachments(:attachment1).id # rubocop:disable Naming/VariableNumber
      }
    )

    assert_not samples_workflow_executions_invalid_mismatch_sample_puid.valid?
    assert_not_nil samples_workflow_executions_invalid_mismatch_sample_puid.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_puid_error',
                                   property: 'sample')}"
    assert_equal expected_error, samples_workflow_executions_invalid_mismatch_sample_puid.errors.full_messages[0]
  end

  test 'invalid no sample puid' do
    samples_workflow_executions_invalid_no_sample_puid = SamplesWorkflowExecution.new(
      sample_id: samples(:sample1).id,
      workflow_execution_id: workflow_executions(:workflow_execution_valid).id,
      samplesheet_params: {
        sample: '',
        fastq_1: attachments(:attachment1).id # rubocop:disable Naming/VariableNumber
      }
    )

    assert_not samples_workflow_executions_invalid_no_sample_puid.valid?
    assert_not_nil samples_workflow_executions_invalid_no_sample_puid.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.blank_error',
                                   property: 'sample')}"
    assert_equal expected_error, samples_workflow_executions_invalid_no_sample_puid.errors.full_messages[0]
  end

  test 'invalid file id' do
    samples_workflow_executions_invalid_file_id = SamplesWorkflowExecution.new(
      sample_id: samples(:sample1).id,
      workflow_execution_id: workflow_executions(:workflow_execution_valid).id,
      samplesheet_params: {
        sample: 'INXT_SAM_AAAAAAAAAA',
        fastq_1: 12_345 # rubocop:disable Naming/VariableNumber
      }
    )

    assert_not samples_workflow_executions_invalid_file_id.valid?
    assert_not_nil samples_workflow_executions_invalid_file_id.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_gid_error',
                                   property: 'fastq_1')}"
    assert_equal(
      expected_error,
      samples_workflow_executions_invalid_file_id.errors.full_messages[0]
    )
  end

  test 'invalid file format for fastq cell' do
    samples_workflow_executions_invalid_file_format = SamplesWorkflowExecution.new(
      sample_id: samples(:sample3).id,
      workflow_execution_id: workflow_executions(:workflow_execution_valid).id,
      samplesheet_params: {
        sample: 'INXT_SAM_AAAAAAAAAA',
        fastq_2: attachments(:attachment3).to_global_id.to_s # rubocop:disable Naming/VariableNumber
      }
    )

    assert_not samples_workflow_executions_invalid_file_format.valid?
    assert_not_nil samples_workflow_executions_invalid_file_format.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
                                   property: 'fastq_2', file_format: '^\\S+\\.f(ast)?q(\\.gz)?$')}"
    assert_includes samples_workflow_executions_invalid_file_format.errors.full_messages,
                    expected_error
  end

  test 'invalid file format for file cell' do
    samples_workflow_executions_invalid_file_format_non_fastq = SamplesWorkflowExecution.new(
      sample_id: samples(:sample3).id,
      workflow_execution_id: workflow_executions(:workflow_execution_gasclustering).id,
      samplesheet_params: {
        sample: 'INXT_SAM_AAAAAAAAAA',
        mlst_alleles: attachments(:attachment3).to_global_id.to_s
      }
    )

    assert_not samples_workflow_executions_invalid_file_format_non_fastq.valid?
    assert_not_nil samples_workflow_executions_invalid_file_format_non_fastq.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
                                   property: 'mlst_alleles',
                                   file_format: '^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$')}"
    assert_includes samples_workflow_executions_invalid_file_format_non_fastq.errors.full_messages,
                    expected_error
  end

  test 'mismatch file id' do
    assert_not @samples_workflow_executions_mismatch_file_id.valid?
    assert_not_nil @samples_workflow_executions_mismatch_file_id.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_attachment_error',
                                   property: 'fastq_1')}"
    assert_equal(
      expected_error,
      @samples_workflow_executions_mismatch_file_id.errors.full_messages[0]
    )
  end
end
