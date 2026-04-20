# frozen_string_literal: true

require 'test_helper'

module Irida
  module Nextflow
    module Samplesheet
      class SampleAttributesTest < ActiveSupport::TestCase
        class FakeSample
          attr_reader :id, :puid, :name, :metadata

          def initialize(id:, puid:, name:, metadata:)
            @id = id
            @puid = puid
            @name = name
            @metadata = metadata
          end
        end

        class FakeAttachment < Hash
          def initialize(id:, filename:, global_id:)
            super()
            self[:id] = id
            self[:filename] = filename
            @global_id = global_id
          end

          def to_global_id
            @global_id
          end
        end

        test 'builds workflow execution attributes and file attributes without fastq_2' do
          sample = FakeSample.new(
            id: 1,
            puid: 'PUID-1',
            name: 'Sample 1',
            metadata: { 'field' => 'value' }
          )

          properties = {
            'sample_cell' => { 'cell_type' => 'sample_cell' },
            'sample_name_cell' => { 'cell_type' => 'sample_name_cell' },
            'metadata_cell' => { 'cell_type' => 'metadata_cell', 'x-irida-next-selected' => 'field' },
            'file_cell' => { 'cell_type' => 'file_cell', 'autopopulate' => true, 'pattern' => '*.fastq' },
            'fastq_1' => { 'cell_type' => 'fastq_cell' }
          }

          builder = Irida::Nextflow::Samplesheet::SampleAttributes.new(
            samples: [sample],
            properties: properties
          )

          # Mock the attachments
          fake_file_attachment = FakeAttachment.new(id: 42, filename: 'test.fastq', global_id: 'gid://test')
          fake_fastq_attachment = FakeAttachment.new(id: 43, filename: 'single.fastq', global_id: 'gid://single')
          builder.stubs(:samples_attachments).returns({
                                                        'file_cell' => { 1 => fake_file_attachment },
                                                        'fastq_1' => { 1 => fake_fastq_attachment }
                                                      })

          result = builder.samples_workflow_executions_attributes[1]

          assert_equal 1, result['sample_id']
          assert_equal 'PUID-1', result['samplesheet_params']['sample_cell']
          assert_equal 'Sample 1', result['samplesheet_params']['sample_name_cell']
          assert_equal 'value', result['samplesheet_params']['metadata_cell']
          assert_equal 'gid://test', result['samplesheet_params']['file_cell']
          assert_equal 'gid://single', result['samplesheet_params']['fastq_1']

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
            metadata: {}
          )

          properties = {
            'fastq_1' => { 'cell_type' => 'fastq_cell', 'pe_only' => true },
            'fastq_2' => { 'cell_type' => 'fastq_cell' }
          }

          builder = Irida::Nextflow::Samplesheet::SampleAttributes.new(
            samples: [sample],
            properties: properties
          )

          # Mock the attachments
          fake_fwd_attachment = FakeAttachment.new(id: 51, filename: 'fwd.fastq', global_id: 'gid://fwd')
          fake_rev_attachment = FakeAttachment.new(id: 52, filename: 'rev.fastq', global_id: 'gid://rev')
          builder.stubs(:samples_attachments).returns({
                                                        'fastq_1' => { 2 => fake_fwd_attachment },
                                                        'fastq_2' => { 2 => fake_rev_attachment }
                                                      })

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
