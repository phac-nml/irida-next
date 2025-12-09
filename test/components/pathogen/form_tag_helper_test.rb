# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for FormTagHelper module functionality
  class FormTagHelperTest < ActionView::TestCase
    include Pathogen::FormTagHelper

    test 'check_box_tag applies base pathogen styling classes' do
      html = check_box_tag('test_checkbox')
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      assert_not_nil checkbox
      classes = checkbox['class'].split
      assert_includes classes, 'size-6'
      assert_includes classes, 'bg-white'
      assert_includes classes, 'rounded-sm'
      assert_includes classes, 'cursor-pointer'
    end

    test 'check_box_tag applies table context styling when data table is true' do
      html = check_box_tag('test_checkbox', '1', false, { data: { table: true } })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      classes = checkbox['class'].split
      # Should include base classes
      assert_includes classes, 'size-6'

      # Should include table-specific classes
      assert_includes classes, '-mt-0.5'
      assert_includes classes, 'mb-0'
      assert_includes classes, 'flex-shrink-0'
      assert_includes classes, 'self-center'
    end

    test 'check_box_tag removes data-table attribute from final HTML' do
      html = check_box_tag('test_checkbox', '1', false, { data: { table: true } })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      # Should NOT include data-table in the output
      assert_nil checkbox['data-table']
    end

    test 'check_box_tag preserves other data attributes when removing table marker' do
      html = check_box_tag('test_checkbox', '1', false, {
                             data: {
                               table: true,
                               action: 'click->test#action',
                               controller: 'test'
                             }
                           })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      # Should preserve other data attributes
      assert_equal 'click->test#action', checkbox['data-action']
      assert_equal 'test', checkbox['data-controller']

      # Should NOT include data-table
      assert_nil checkbox['data-table']
    end

    test 'check_box_tag merges custom classes with pathogen classes' do
      html = check_box_tag('test_checkbox', '1', false, { class: 'custom-class' })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      # Should include both pathogen and custom classes
      classes = checkbox['class'].split
      assert_includes classes, 'size-6'
      assert_includes classes, 'custom-class'
    end

    test 'check_box_tag merges custom classes array with pathogen classes' do
      html = check_box_tag('test_checkbox', '1', false, { class: %w[custom-1 custom-2] })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      # Should include both pathogen and custom classes
      classes = checkbox['class'].split
      assert_includes classes, 'size-6'
      assert_includes classes, 'custom-1'
      assert_includes classes, 'custom-2'
    end

    test 'check_box_tag with table context and custom classes' do
      html = check_box_tag('test_checkbox', '1', false, {
                             data: { table: true },
                             class: 'my-checkbox'
                           })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      classes = checkbox['class'].split
      # Should include base classes
      assert_includes classes, 'size-6'

      # Should include table classes
      assert_includes classes, '-mt-0.5'

      # Should include custom class
      assert_includes classes, 'my-checkbox'
    end

    test 'check_box_tag preserves aria attributes' do
      html = check_box_tag('test_checkbox', '1', false, {
                             aria: { label: 'Test Label' }
                           })
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      assert_equal 'Test Label', checkbox['aria-label']
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
      doc = Nokogiri::HTML.fragment(html)
      checkbox = doc.at_css('input[type="checkbox"]')

      # Verify ID
      assert_equal 'checkbox_sample_123', checkbox['id']

      # Verify name and value
      assert_equal 'sample_ids[]', checkbox['name']
      assert_equal 'sample-123', checkbox['value']

      # Verify aria
      assert_equal 'Sample 123', checkbox['aria-label']

      # Verify data attributes (table should be removed)
      assert_equal 'input->selection#toggle', checkbox['data-action']
      assert_equal 'rowSelection', checkbox['data-selection-target']
      assert_nil checkbox['data-table']

      # Verify classes (pathogen + table + custom)
      classes = checkbox['class'].split
      assert_includes classes, 'size-6'
      assert_includes classes, '-mt-0.5'
      assert_includes classes, 'additional-class'
    end
  end
end
