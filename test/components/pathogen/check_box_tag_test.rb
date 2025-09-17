# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Form
    class CheckBoxTagTest < ViewComponent::TestCase
      # @!group Basic Standalone Field Tests

      def test_renders_basic_checkbox_tag_with_pathogen_styling
        render_inline(CheckBoxTag.new('sample_quality', 'approved'))

        assert_selector "input[type='checkbox']"
        assert_selector "input[name='sample_quality']"
        assert_selector "input[value='approved']"

        # Check for Pathogen styling classes
        assert_selector 'input.size-6'
        assert_selector 'input.text-primary-600'
        assert_selector 'input.bg-slate-100'
        assert_selector 'input.border-slate-300'
        assert_selector 'input.rounded-sm'
        assert_selector 'input.cursor-pointer'
        assert_selector 'input.dark\\:bg-slate-700'
        assert_selector 'input.dark\\:border-slate-600'
      end

      def test_renders_checkbox_tag_with_custom_values
        render_inline(CheckBoxTag.new('workflow_step', 'assembly'))

        assert_selector "input[type='checkbox'][value='assembly']"
        assert_selector "input[name='workflow_step']"
      end

      def test_renders_checkbox_tag_with_html_options
        render_inline(CheckBoxTag.new('sample_ids[]', '12345', false, {
                                        id: 'sample-12345',
                                        class: 'custom-class',
                                        data: { action: 'input->selection#toggle' }
                                      }))

        assert_selector 'input#sample-12345'
        assert_selector 'input.custom-class'
        assert_selector "input[data-action='input->selection#toggle']"

        # Custom classes should be merged with Pathogen classes
        assert_selector 'input.size-6.custom-class'
      end

      # @!endgroup

      # @!group Array Field Pattern Tests

      def test_handles_array_field_patterns
        render_inline(CheckBoxTag.new('sample_ids[]', '123'))

        assert_selector "input[name='sample_ids[]'][value='123']"
      end

      def test_handles_attachment_selection
        render_inline(CheckBoxTag.new('attachment_ids[]', 'attachment-789', false, {
                                        id: 'attachment-789-checkbox',
                                        data: {
                                          action: 'input->selection#toggle',
                                          attachment_type: 'sequencing_data'
                                        }
                                      }))

        assert_selector "input[name='attachment_ids[]'][value='attachment-789']"
        assert_selector "input[id='attachment-789-checkbox']"
        assert_selector "input[data-attachment-type='sequencing_data']"
      end

      # @!endgroup

      # @!group Special Field Name Patterns

      def test_handles_hyphenated_field_names
        render_inline(CheckBoxTag.new('select-page', '1'))

        assert_selector "input[name='select-page'][value='1']"
      end

      def test_handles_special_characters_in_values
        render_inline(CheckBoxTag.new('filename', 'Sample_001_R1.fastq.gz'))

        assert_selector "input[value='Sample_001_R1.fastq.gz']"
      end

      def test_handles_numeric_values
        render_inline(CheckBoxTag.new('coverage_threshold', '30'))

        assert_selector "input[value='30']"
      end

      # @!endgroup

      # @!group State Tests

      def test_renders_checked_checkbox
        render_inline(CheckBoxTag.new('analysis_complete', '1', true))

        assert_selector 'input[checked="checked"]'
      end

      def test_renders_unchecked_checkbox
        render_inline(CheckBoxTag.new('analysis_complete', '1', false))

        assert_no_selector 'input[checked]'
      end

      def test_renders_disabled_checkbox
        render_inline(CheckBoxTag.new('restricted_data', '1', false, { disabled: true }))

        assert_selector 'input[disabled]'
      end

      def test_renders_checked_and_disabled_checkbox
        render_inline(CheckBoxTag.new('locked_sample', '1', true, { disabled: true }))

        assert_selector 'input[checked="checked"][disabled]'
      end

      # @!endgroup

      # @!group HTML Attributes Tests

      def test_renders_checkbox_with_aria_label
        render_inline(CheckBoxTag.new('select_all_samples', '1', false, {
                                        'aria-label': 'Select all samples on this page'
                                      }))

        assert_selector "input[aria-label='Select all samples on this page']"
      end

      def test_renders_checkbox_with_aria_describedby
        render_inline(CheckBoxTag.new('data_sharing_consent', '1', false, {
                                        'aria-describedby': 'consent-help-text'
                                      }))

        assert_selector "input[aria-describedby='consent-help-text']"
      end

      def test_renders_checkbox_with_multiple_aria_attributes
        render_inline(CheckBoxTag.new('quality_control', '1', false, {
                                        'aria-label': 'Enable quality control analysis',
                                        'aria-describedby': 'qc-help',
                                        'aria-controls': 'qc-options-panel'
                                      }))

        assert_selector "input[aria-label='Enable quality control analysis']"
        assert_selector "input[aria-describedby='qc-help']"
        assert_selector "input[aria-controls='qc-options-panel']"
      end

      def test_renders_checkbox_with_data_attributes
        render_inline(CheckBoxTag.new('sample_selection', 'sample-001', false, {
                                        data: {
                                          action: 'input->selection#toggle',
                                          sample_type: 'genomic_dna',
                                          organism: 'escherichia_coli'
                                        }
                                      }))

        assert_selector "input[data-action='input->selection#toggle']"
        assert_selector "input[data-sample-type='genomic_dna']"
        assert_selector "input[data-organism='escherichia_coli']"
      end

      def test_renders_checkbox_with_stimulus_controller_data
        render_inline(CheckBoxTag.new('batch_operation', '1', false, {
                                        data: {
                                          controller: 'batch-processor',
                                          'batch-processor-target': 'checkbox',
                                          action: 'change->batch-processor#handleChange'
                                        }
                                      }))

        assert_selector "input[data-controller='batch-processor']"
        assert_selector "input[data-batch-processor-target='checkbox']"
        assert_selector "input[data-action='change->batch-processor#handleChange']"
      end

      # @!endgroup

      # @!group Integration Tests

      def test_sample_table_selection_pattern
        # Test the common pattern used in sample tables
        render_inline(CheckBoxTag.new('sample_ids[]', 'sample-123', false, {
                                        id: 'sample-123-checkbox',
                                        data: {
                                          action: 'input->selection#toggle',
                                          'selection-target': 'rowSelection'
                                        }
                                      }))

        assert_selector "input[name='sample_ids[]'][value='sample-123']"
        assert_selector 'input#sample-123-checkbox'
        assert_selector "input[data-action='input->selection#toggle']"
        assert_selector "input[data-selection-target='rowSelection']"
      end

      def test_select_all_page_pattern
        # Test the select-all pattern used in table headers
        render_inline(CheckBoxTag.new('select-page', '1', false, {
                                        id: 'select-page',
                                        data: {
                                          action: 'input->selection#togglePage',
                                          controller: 'filters',
                                          'selection-target': 'selectPage'
                                        }
                                      }))

        assert_selector "input[name='select-page'][value='1']"
        assert_selector 'input#select-page'
        assert_selector "input[data-controller='filters']"
        assert_selector "input[data-action='input->selection#togglePage']"
      end

      # @!endgroup

      # @!group Edge Cases Tests

      def test_excludes_include_hidden_option_from_html_attributes
        render_inline(CheckBoxTag.new('test_field', '1', false, { include_hidden: false }))

        # Should not render hidden field (CheckBoxTag never renders hidden fields)
        assert_no_selector "input[type='hidden']"
        # Should not have include_hidden as HTML attribute
        assert_no_selector 'input[include_hidden]'
        assert_no_selector 'input[include-hidden]'
      end

      def test_handles_empty_options_hash
        render_inline(CheckBoxTag.new('simple_test', '1', false, {}))

        assert_selector "input[type='checkbox']"
        assert_selector 'input.size-6' # Should still have Pathogen styling
      end

      def test_merges_custom_classes_with_pathogen_classes
        render_inline(CheckBoxTag.new('custom_field', '1', false, { class: 'border-red-500 focus:ring-red-300' }))

        # Should have both Pathogen and custom classes
        assert_selector 'input.size-6.border-red-500'
        assert_selector 'input.text-primary-600.focus\\:ring-red-300'
      end

      def test_handles_class_as_array
        render_inline(CheckBoxTag.new('multi_class', '1', false, { class: %w[custom-1 custom-2] }))

        assert_selector 'input.size-6'
        assert_selector 'input.custom-1'
        assert_selector 'input.custom-2'
      end

      # @!endgroup

      private

      def page
        Capybara::Node::Simple.new(@rendered_content)
      end
    end
  end
end
