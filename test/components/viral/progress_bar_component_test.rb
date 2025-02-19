# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class ProgressBarComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_text I18n.t('viral.progress_bar_component.in_progress')
      assert_text '0%'
    end
  end
end
