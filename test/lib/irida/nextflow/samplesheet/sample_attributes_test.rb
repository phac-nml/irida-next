# frozen_string_literal: true

require 'test_helper'

module Irida
  module Nextflow
    module Samplesheet
      class SampleAttributesTest < ActiveSupport::TestCase
        class FakeSample
          attr_reader :id, :puid, :name, :metadata

          def initialize(id:, puid:, name:, metadata:, other_file:, single_fastq_file:, fastq_files:) # rubocop:disable Metrics/ParameterLists
            @id = id
            @puid = puid
            @name = name
            @metadata = metadata
            @other_file = other_file
            @single_fastq_file = single_fastq_file
            @fastq_files = fastq_files
          end

          def most_recent_other_file(_autopopulate, _pattern)
            @other_file
          end

          def most_recent_single_fastq_file(_name)
            @single_fastq_file
          end

          def most_recent_fastq_files(_pe_only)
            @fastq_files
          end
        end

        test 'builds workflow execution attributes and file attributes without fastq_2' do
          sample = FakeSample.new(
            id: 1,
            puid: 'PUID-1',
            name: 'Sample 1',
            metadata: { 'field' => 'value' },
            other_file: { filename: 'test.fastq', id: 42, global_id: 'gid://test' },
            single_fastq_file: { 'fastq_1' => { filename: 'single.fastq', id: 43, global_id: 'gid://single' } },
            fastq_files: { 'fastq_1' => { filename: 'single.fastq', id: 43, global_id: 'gid://single' } }
          )

          properties = {
            'sample_cell' => { 'cell_type' => 'sample_cell' },
            'sample_name_cell' => { 'cell_type' => 'sample_name_cell' },
            'metadata_cell' => { 'cell_type' => 'metadata_cell', 'x-irida-next-selected' => 'field' },
            'file_cell' => { 'cell_type' => 'file_cell', 'autopopulate' => true, 'pattern' => '*.fastq' },
            'fastq_cell' => { 'cell_type' => 'fastq_cell' }
          }

          builder = Irida::Nextflow::Samplesheet::SampleAttributes.new(
            samples: [sample],
            properties: properties
          )

          result = builder.samples_workflow_executions_attributes[1]

          assert_equal 1, result['sample_id']
          assert_equal 'PUID-1', result['samplesheet_params']['sample_cell']
          assert_equal 'Sample 1', result['samplesheet_params']['sample_name_cell']
          assert_equal 'value', result['samplesheet_params']['metadata_cell']
          assert_equal 'gid://test', result['samplesheet_params']['file_cell']
          assert_equal({ 'fastq_1' => 'gid://single' }, result['samplesheet_params']['fastq_cell'])

          assert_equal(
            {
              1 => {
                'file_cell' => { filename: 'test.fastq', attachment_id: 42 },
                'fastq_1' => { filename: 'single.fastq', attachment_id: 43 }
              }
            },
            builder.file_attributes
          )
        end

        test 'merges fastq_1 and fastq_2 when fastq_2 is present' do
          sample = FakeSample.new(
            id: 2,
            puid: 'PUID-2',
            name: 'Sample 2',
            metadata: {},
            other_file: {},
            single_fastq_file: {},
            fastq_files: {
              'fastq_1' => { filename: 'fwd.fastq', id: 51, global_id: 'gid://fwd' },
              'fastq_2' => { filename: 'rev.fastq', id: 52, global_id: 'gid://rev' }
            }
          )

          properties = {
            'fastq_1' => { 'cell_type' => 'fastq_cell', 'pe_only' => true },
            'fastq_2' => { 'cell_type' => 'fastq_cell' }
          }

          builder = Irida::Nextflow::Samplesheet::SampleAttributes.new(
            samples: [sample],
            properties: properties
          )

          result = builder.samples_workflow_executions_attributes[2]

          assert_equal 'gid://fwd', result['samplesheet_params']['fastq_1']
          assert_equal 'gid://rev', result['samplesheet_params']['fastq_2']
          assert_equal(
            {
              2 => {
                'fastq_1' => { filename: 'fwd.fastq', attachment_id: 51 },
                'fastq_2' => { filename: 'rev.fastq', attachment_id: 52 }
              }
            },
            builder.file_attributes
          )
        end
      end
    end
  end
end
