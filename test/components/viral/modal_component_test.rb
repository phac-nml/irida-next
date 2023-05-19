# frozen_string_literal: true

require 'test_helper'

module Viral
  class ModalComponentTest < ViewComponent::TestCase
    test 'with title' do
      title = 'Modal Title'
      render_inline(Viral::ModalComponent.new(title:))
      assert_text title
    end

    test 'with title and body' do
      title = 'Modal Title'
      body = 'Modal Body'
      render_inline(Viral::ModalComponent.new(title:)) do |modal|
        modal.with_body do
          body
        end
      end
      assert_selector '#Viral-Modal-Body' do
        assert_text body
      end
    end
  end
end
