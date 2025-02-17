# frozen_string_literal: true

require 'test_helper'

class SamplesWorkflowExecutionsTest < ActiveSupport::TestCase
  def setup
    @samples_workflow_executions_valid =
      samples_workflow_executions(:samples_workflow_executions_valid)
    @samples_workflow_executions_invalid_no_sample_puid =
      samples_workflow_executions(:samples_workflow_executions_invalid_no_sample_puid)
    @samples_workflow_executions_invalid_mismatch_sample_puid =
      samples_workflow_executions(:samples_workflow_executions_invalid_mismatch_sample_puid)
    @samples_workflow_executions_invalid_file_id =
      samples_workflow_executions(:samples_workflow_executions_invalid_file_id)
    @samples_workflow_executions_invalid_file_format =
      samples_workflow_executions(:samples_workflow_executions_invalid_file_format)
    @samples_workflow_executions_invalid_file_format_non_fastq =
      samples_workflow_executions(:samples_workflow_executions_invalid_file_format_non_fastq)
    @samples_workflow_executions_mismatch_file_id =
      samples_workflow_executions(:samples_workflow_executions_mismatch_file_id)
  end

  test 'valid samples workflow executions' do
    assert @samples_workflow_executions_valid.valid?
  end

  test 'invalid mismatch puid' do
    assert_not @samples_workflow_executions_invalid_mismatch_sample_puid.valid?
    assert_not_nil @samples_workflow_executions_invalid_mismatch_sample_puid.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_puid_error',
                                   property: 'sample')}"
    assert_equal expected_error, @samples_workflow_executions_invalid_mismatch_sample_puid.errors.full_messages[0]
  end

  test 'invalid no sample puid' do
    assert_not @samples_workflow_executions_invalid_no_sample_puid.valid?
    assert_not_nil @samples_workflow_executions_invalid_no_sample_puid.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.blank_error',
                                   property: 'sample')}"
    assert_equal expected_error, @samples_workflow_executions_invalid_no_sample_puid.errors.full_messages[0]
  end

  test 'invalid file id' do
    assert_not @samples_workflow_executions_invalid_file_id.valid?
    assert_not_nil @samples_workflow_executions_invalid_file_id.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_gid_error',
                                   property: 'fastq_1')}"
    assert_equal(
      expected_error,
      @samples_workflow_executions_invalid_file_id.errors.full_messages[0]
    )
  end

  test 'invalid file format for fastq cell' do
    assert_not @samples_workflow_executions_invalid_file_format.valid?
    assert_not_nil @samples_workflow_executions_invalid_file_format.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
                                   property: 'fastq_2', file_format: '^\\S+\\.f(ast)?q(\\.gz)?$')}"
    assert_includes @samples_workflow_executions_invalid_file_format.errors.full_messages,
                    expected_error
  end

  test 'invalid file format for file cell' do
    assert_not @samples_workflow_executions_invalid_file_format_non_fastq.valid?
    assert_not_nil @samples_workflow_executions_invalid_file_format_non_fastq.errors
    expected_error =
      "Samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
                                   property: 'mlst_alleles', file_format: '^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$')}"
    assert_includes @samples_workflow_executions_invalid_file_format_non_fastq.errors.full_messages,
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
