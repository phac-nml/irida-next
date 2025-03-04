# frozen_string_literal: true

require 'test_helper'

class ViewHelperTest < ActionView::TestCase
  include ViewHelper

  setup do
    %w[developer saml entra_id].each do |provider|
      Rails.configuration.auth_config["#{provider}_icon"] = '../../../test/fixtures/files/tyrell.svg'
    end
  end

  teardown do
    %w[developer saml entra_id].each do |provider|
      Rails.configuration.auth_config["#{provider}_icon"] = nil
    end
  end

  test 'should add assigned classes' do
    source = viral_icon_source('bars_3')
    assert source.include? 'focusable="false"'
    assert source.include? 'aria-hidden="true"'
  end

  test 'should load override icons' do
    %w[developer saml entra_id].each do |provider|
      source = viral_icon_source("#{provider}_icon")
      assert source.include? %(class="viral-icon__Svg icon-#{provider}_icon")
      assert source.include? 'viewbox="0 0 1140 1012"'
    end
  end
end
