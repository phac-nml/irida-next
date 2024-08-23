# frozen_string_literal: true

require 'application_system_test_case'

class PagyLimitComponentPreviewTest < ApplicationSystemTestCase
  test 'renders default' do
    visit('/rails/view_components/viral_pagy_limit_component/default')

    assert_text 'Displaying 1-20 of 100 items'
  end

  test 'renders with one item' do
    visit('/rails/view_components/viral_pagy_limit_component/with_one_item')

    assert_text 'Displaying 1 item'
  end
end
