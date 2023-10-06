# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class TimeAgoComponentTest < ViewComponentTestCase
    test 'default' do
      render_inline(Viral::TimeAgoComponent.new(original_time: 10.days.ago))
      assert_text '10 days ago'
    end

    test 'current time input' do
      render_inline(Viral::TimeAgoComponent.new(current_time: 5.days.ago, original_time: 10.days.ago))
      assert_text '5 days ago'
    end
  end
end
