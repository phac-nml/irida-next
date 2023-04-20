# frozen_string_literal: true

require 'test_helper'

class ViewHelperTest < ActionView::TestCase
  include ViewHelper

  test 'should add assigned classes' do
    source = viral_icon_source('bars_3')
    assert source.include? 'focusable="false"'
    assert source.include? 'aria-hidden="true"'
  end
end
