# frozen_string_literal: true

require 'application_system_test_case'

module System
  class TimeAgoComponentTest < ApplicationSystemTestCase
    test 'default tooltip' do
      freeze_time
      visit('/rails/view_components/viral_time_ago_component/default')
      assert_text '15 days ago'
      within('.Viral-Preview [data-controller-connected="true"]') do
        assert_selector '[data-viral--tooltip-target="target"]', visible: false
        find('span', text: '15 days ago').hover
        assert_text (DateTime.now - 15.days).strftime('%B %d, %Y %H:%M')
        assert_selector '[data-viral--tooltip-target="target"]', visible: true
      end
    end

    test 'current time input tooltip' do
      freeze_time
      visit('/rails/view_components/viral_time_ago_component/current_time_input')
      assert_text '5 days ago'
      within('.Viral-Preview [data-controller-connected="true"]') do
        assert_selector '[data-viral--tooltip-target="target"]', visible: false
        find('span', text: '5 days ago').hover
        assert_text (DateTime.now - 15.days).strftime('%B %d, %Y %H:%M')
        assert_selector '[data-viral--tooltip-target="target"]', visible: true
      end
    end
  end
end
