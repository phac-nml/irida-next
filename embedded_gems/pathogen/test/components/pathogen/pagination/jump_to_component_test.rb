# frozen_string_literal: true

require 'test_helper'
require_relative 'component_test_helper'

module Pathogen
  module Pagination
    class JumpToComponentTest < ViewComponent::TestCase
      include ComponentTestHelper

      test 'renders jump to page input' do
        pagy = mock_pagy(pages: 10, page: 5)
        request = mock_request
        
        render_inline(JumpToComponent.new(pagy: pagy, request: request))
        
        assert_selector('input#jump-to-page[type="number"]')
        assert_selector('input[name="page"][value="5"]')
        assert_selector('input[name="limit"][value="10"]', visible: :hidden)
        assert_text('of 10 pages')
      end

      test 'does not render when only one page exists' do
        pagy = mock_pagy(pages: 1, page: 1)
        request = mock_request
        
        render_inline(JumpToComponent.new(pagy: pagy, request: request))
        
        assert_no_selector('input#jump-to-page')
      end

      test 'applies correct classes to input elements' do
        component = JumpToComponent.new(
          pagy: mock_pagy,
          request: mock_request
        )
        
        assert_includes(component.send(:input_classes), 'w-20')
        assert_includes(component.send(:input_classes), 'rounded-lg')
        assert_includes(component.send(:input_classes), 'border')
        
        assert_includes(component.send(:info_text_classes), 'text-sm')
        assert_includes(component.send(:info_text_classes), 'text-slate-700')
        assert_includes(component.send(:info_text_classes), 'dark:text-slate-300')
      end
    end
  end
end
