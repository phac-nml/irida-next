# frozen_string_literal: true

require 'application_system_test_case'

module System
  class TimeAgoComponentTest < ApplicationSystemTestCase
    test 'default' do
      visit('/rails/view_components/viral_time_ago_component/default')
      assert_text '15 days ago'
    end

    test 'current time input' do
      visit('/rails/view_components/viral_time_ago_component/current_time_input')
      assert_text '5 days ago'
    end

    test 'default tooltip' do
      visit('/rails/view_components/viral_time_ago_component/default')
      assert_text '15 days ago'
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_selector '[data-viral--tooltip-target="target"]', visible: false
        find('span.text-sm', text: '15 days ago').hover
        assert_text (DateTime.now - 15.days).strftime('%B %d, %Y %H:%M')
        assert_selector '[data-viral--tooltip-target="target"]', visible: true
      end
    end

    test 'current time input tooltip' do
      visit('/rails/view_components/viral_time_ago_component/current_time_input')
      assert_text '5 days ago'
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_selector '[data-viral--tooltip-target="target"]', visible: false
        find('span.text-sm', text: '5 days ago').hover
        assert_text (DateTime.now - 15.days).strftime('%B %d, %Y %H:%M')
        assert_selector '[data-viral--tooltip-target="target"]', visible: true
      end
    end
  end
end
