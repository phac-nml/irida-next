# frozen_string_literal: true

require 'test_helper'

class ViewHelperTest < ActionView::TestCase
  include ViewHelper

  test 'should get heroicons source' do
    source = heroicons_source('arrow-right', 'w-6 h-6')
    assert_equal source,
                 '<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3"></path></svg>'
  end
end
