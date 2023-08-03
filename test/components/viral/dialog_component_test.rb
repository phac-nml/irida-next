# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class DialogComponentTest < ViewComponentTestCase
    test 'confirmation dialog' do
      render_preview(:confirmation)
    end

    test 'default dialog' do
      render_preview(:default)
    end

    test 'small dialog' do
      render_preview(:small)
    end

    test 'large dialog' do
      render_preview(:large)
    end

    test 'extra_large dialog' do
      render_preview(:extra_large)
    end

    test 'with_action_buttons dialog' do
      render_preview(:with_action_buttons)
    end

    test 'with_trigger dialog' do
      render_preview(:with_trigger)
    end

    test 'with_multiple_sections dialog' do
      render_preview(:with_multiple_sections)
    end
  end
end
