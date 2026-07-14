# frozen_string_literal: true

require 'test_helper'

module DataExports
  class ExportSourceSizeCalculatorTest < ActiveSupport::TestCase
    test 'sample export totals selected attachment formats only' do
      sample1 = samples(:sample1)
      sample3 = samples(:sample3)

      expected = sample1.attachments.sum { |attachment| attachment.file.byte_size }

      total_size = calculate('sample', 'ids' => [sample1.id, sample3.id], 'attachment_formats' => ['fastq'])

      assert_equal expected, total_size
    end

    test 'analysis export totals workflow and per-sample outputs' do
      workflow_execution = workflow_executions(:irida_next_example_completed_with_output)

      workflow_output_size = workflow_execution.outputs.sum { |output| output.file.byte_size }
      sample_output_size = workflow_execution.samples_workflow_executions.sum do |samples_workflow_execution|
        samples_workflow_execution.outputs.sum { |output| output.file.byte_size }
      end

      total_size = calculate('analysis', 'ids' => [workflow_execution.id])

      assert_equal workflow_output_size + sample_output_size, total_size
    end

    test 'returns zero when export has no source files' do
      workflow_execution = workflow_executions(:workflow_execution_valid)

      total_size = calculate('analysis', 'ids' => [workflow_execution.id])

      assert_equal 0, total_size
    end

    test 'linelist exports always return zero source bytes' do
      total_size = calculate('linelist', 'ids' => [samples(:sample1).id])

      assert_equal 0, total_size
    end

    test 'counts the same blob more than once when copied more than once' do
      source_blob = attachments(:attachment1).file.blob
      sample_one = sample_with_attached_blob('duplicate-source-size-one', source_blob)
      sample_two = sample_with_attached_blob('duplicate-source-size-two', source_blob)

      total_size = calculate(
        'sample',
        'ids' => [sample_one.id, sample_two.id],
        'attachment_formats' => ['fastq']
      )

      assert_equal source_blob.byte_size * 2, total_size
    end

    private

    def calculate(export_type, export_parameters)
      DataExports::ExportSourceSizeCalculator.new(
        export_type: export_type,
        export_parameters: export_parameters
      ).execute
    end

    def sample_with_attached_blob(name, blob)
      sample = Sample.create!(project: projects(:project1), name:)
      attachment = Attachment.new(attachable: sample, metadata: { 'compression' => 'none', 'format' => 'fastq' })
      attachment.file.attach(blob)
      attachment.save!
      sample
    end
  end
end
