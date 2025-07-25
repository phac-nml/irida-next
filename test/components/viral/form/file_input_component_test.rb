# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class FileInputComponentTest < ViewComponentTestCase
      test 'default' do
        render_preview(:default)
        assert_selector "input[type='file']", count: 1
      end

      test 'with label' do
        render_preview(:with_label)
        assert_selector 'label', text: 'File Input', count: 1
        assert_selector "input[type='file']", count: 1
      end

      test 'with help text' do
        render_preview(:with_help_text)
        assert_selector 'label', text: 'File Input', count: 1
        assert_selector "input[type='file']", count: 1
        assert_selector 'span.text-sm', text: 'This is a help text', count: 1
      end
    end
  end
end
