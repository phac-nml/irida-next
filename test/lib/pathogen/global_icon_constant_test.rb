# frozen_string_literal: true

require 'test_helper'

class GlobalIconConstantTest < ActiveSupport::TestCase
  test 'ICON constant should reference ICON' do
    assert_equal ICON, ICON
    assert_equal ICON::ARROW_UP, ICON::ARROW_UP
    assert_equal ICON::CLIPBOARD, ICON::CLIPBOARD
  end

  test 'ICON constants should be accessible without Pathogen namespace' do
    assert_equal 'arrow-up', ICON::ARROW_UP[:name]
    assert_equal 'clipboard-text', ICON::CLIPBOARD[:name]
    assert_equal :beaker, ICON::BEAKER[:name]
  end

  test 'ICON lookup methods should work the same' do
    assert_equal ICON[:arrow_up], ICON[:arrow_up]
    assert_equal ICON::DEFINITIONS, ICON::DEFINITIONS
  end
end
