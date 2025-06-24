# frozen_string_literal: true

require 'test_helper'

module Viral
  class EmptyStateComponentTest < ViewComponent::TestCase
    def test_renders_with_title_and_description
      render_inline(
        Viral::EmptyStateComponent.new(
          icon_name: ICON::BANK,
          title: 'No files have been uploaded',
          description: 'Get started by uploading sequence data, assembly files, or other relevant documents.',
          action_text: 'Upload Files',
          action_path: '/upload',
          action_method: :get
        )
      )

      assert_text 'No files have been uploaded'
      assert_text 'Get started by uploading sequence data, assembly files, or other relevant documents.'
      assert_selector 'a', text: 'Upload Files'
      assert_selector 'svg.bank-icon'
    end

    def test_accessibility
      render_inline(
        Viral::EmptyStateComponent.new(
          icon_name: ICON::BANK,
          title: 'No files',
          description: 'Description',
          action_text: 'Action',
          action_path: '/action',
          action_method: :get
        )
      )
      assert_selector '[role="alert"]'
      assert_selector '[aria-labelledby]'
      assert_selector '[aria-describedby]'
    end
  end
end
