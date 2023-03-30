# frozen_string_literal: true

require 'test_helper'

class ViewHelperTest < ActionView::TestCase
  include ViewHelper

  test 'should add assigned classes' do
    source = heroicons_source('bars_3', 'w-6 h-6')
    assert source.include? 'class="w-6 h-6"'
    assert source.include? 'focusable="false"'
    assert source.include? 'aria-hidden="true"'
  end
end
