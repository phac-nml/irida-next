# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for FormTagHelper module functionality
  class FormTagHelperTest < ActionView::TestCase
    include Pathogen::FormTagHelper

    test 'check_box_tag applies base pathogen styling classes' do
      html = check_box_tag('test_checkbox')
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should include size-6 class')
      assert_match(/class="[^"]*bg-white[^"]*"/, html, 'Should include bg-white class')
      assert_match(/class="[^"]*rounded-sm[^"]*"/, html, 'Should include rounded-sm class')
      assert_match(/class="[^"]*cursor-pointer[^"]*"/, html, 'Should include cursor-pointer class')
    end

    test 'check_box_tag applies table context styling when data table is true' do
      html = check_box_tag('test_checkbox', '1', false, { data: { table: true } })

      # Should include base classes
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should include size-6 class')

      # Should include table-specific classes
      assert_match(/class="[^"]*-mt-0\.5[^"]*"/, html, 'Should include -mt-0.5 class for table context')
      assert_match(/class="[^"]*mb-0[^"]*"/, html, 'Should include mb-0 class for table context')
      assert_match(/class="[^"]*flex-shrink-0[^"]*"/, html, 'Should include flex-shrink-0 class for table context')
      assert_match(/class="[^"]*self-center[^"]*"/, html, 'Should include self-center class for table context')
    end

    test 'check_box_tag removes data-table attribute from final HTML' do
      html = check_box_tag('test_checkbox', '1', false, { data: { table: true } })

      # Should NOT include data-table in the output
      assert_no_match(/data-table/, html, 'Should not include data-table attribute in HTML output')
    end

    test 'check_box_tag preserves other data attributes when removing table marker' do
      html = check_box_tag('test_checkbox', '1', false, {
                             data: {
                               table: true,
                               action: 'click->test#action',
                               controller: 'test'
                             }
                           })

      # Should preserve other data attributes
      assert_match(/data-action="click-&gt;test#action"/, html, 'Should preserve data-action attribute')
      assert_match(/data-controller="test"/, html, 'Should preserve data-controller attribute')

      # Should NOT include data-table
      assert_no_match(/data-table/, html, 'Should not include data-table attribute')
    end

    test 'check_box_tag merges custom classes with pathogen classes' do
      html = check_box_tag('test_checkbox', '1', false, { class: 'custom-class' })

      # Should include both pathogen and custom classes
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should include pathogen class')
      assert_match(/class="[^"]*custom-class[^"]*"/, html, 'Should include custom class')
    end

    test 'check_box_tag merges custom classes array with pathogen classes' do
      html = check_box_tag('test_checkbox', '1', false, { class: %w[custom-1 custom-2] })

      # Should include both pathogen and custom classes
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should include pathogen class')
      assert_match(/class="[^"]*custom-1[^"]*"/, html, 'Should include first custom class')
      assert_match(/class="[^"]*custom-2[^"]*"/, html, 'Should include second custom class')
    end

    test 'check_box_tag with table context and custom classes' do
      html = check_box_tag('test_checkbox', '1', false, {
                             data: { table: true },
                             class: 'my-checkbox'
                           })

      # Should include base classes
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should include base class')

      # Should include table classes
      assert_match(/class="[^"]*-mt-0\.5[^"]*"/, html, 'Should include table class')

      # Should include custom class
      assert_match(/class="[^"]*my-checkbox[^"]*"/, html, 'Should include custom class')
    end

    test 'check_box_tag preserves aria attributes' do
      html = check_box_tag('test_checkbox', '1', false, {
                             aria: { label: 'Test Label' }
                           })

      assert_match(/aria-label="Test Label"/, html, 'Should preserve aria-label attribute')
    end

    test 'check_box_tag with all options combined' do
      html = check_box_tag('sample_ids[]', 'sample-123', false, {
                             id: 'checkbox_sample_123',
                             aria: { label: 'Sample 123' },
                             data: {
                               table: true,
                               action: 'input->selection#toggle',
                               selection_target: 'rowSelection'
                             },
                             class: 'additional-class'
                           })

      # Verify ID
      assert_match(/id="checkbox_sample_123"/, html, 'Should have correct ID')

      # Verify name and value
      assert_match(/name="sample_ids\[\]"/, html, 'Should have correct name')
      assert_match(/value="sample-123"/, html, 'Should have correct value')

      # Verify aria
      assert_match(/aria-label="Sample 123"/, html, 'Should have aria-label')

      # Verify data attributes (table should be removed)
      assert_match(/data-action="input-&gt;selection#toggle"/, html, 'Should have data-action')
      assert_match(/data-selection-target="rowSelection"/, html, 'Should have data-selection-target')
      assert_no_match(/data-table/, html, 'Should NOT have data-table')

      # Verify classes (pathogen + table + custom)
      assert_match(/class="[^"]*size-6[^"]*"/, html, 'Should have pathogen class')
      assert_match(/class="[^"]*-mt-0\.5[^"]*"/, html, 'Should have table class')
      assert_match(/class="[^"]*additional-class[^"]*"/, html, 'Should have custom class')
    end
  end
end
