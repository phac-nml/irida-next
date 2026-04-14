# frozen_string_literal: true

require 'test_helper'

module Irida
  module Nextflow
    class SamplesheetPropertiesTest < ActiveSupport::TestCase
      test 'builds properties with cell types, patterns, and autopopulate flags' do
        schema = {
          'items' => {
            'required' => %w[sample fastq_1 fastq_2],
            'properties' => {
              'sample' => { 'type' => 'string' },
              'sample_name' => { 'type' => 'string' },
              'fastq_1' => { 'type' => 'string' },
              'fastq_2' => { 'type' => 'string' },
              'attachment' => { 'format' => 'file-path' },
              'metadata' => { 'meta' => true },
              'choice' => { 'enum' => %w[a b] },
              'pattern_anyof' => { 'anyOf' => [{ 'pattern' => 'x' }, { 'pattern' => 'y' }] }
            }
          }
        }

        properties = Irida::Nextflow::Samplesheet::Properties.new(schema).properties

        assert_equal 'sample_cell', properties['sample']['cell_type']
        assert_equal 'sample_name_cell', properties['sample_name']['cell_type']
        assert_equal 'fastq_cell', properties['fastq_1']['cell_type']
        assert_equal 'fastq_cell', properties['fastq_2']['cell_type']
        assert_equal 'file_cell', properties['attachment']['cell_type']
        assert_equal 'metadata_cell', properties['metadata']['cell_type']
        assert_equal 'dropdown_cell', properties['choice']['cell_type']
        assert_equal 'x|y', properties['pattern_anyof']['pattern']
        assert_equal true, properties['fastq_1']['pe_only']
        assert_equal true, properties['fastq_1']['autopopulate']
        assert_equal true, properties['fastq_2']['autopopulate']
      end
    end
  end
end
