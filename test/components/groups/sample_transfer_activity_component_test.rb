# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class SampleTransferActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:mary_doe)
    end

    test 'group sample transfer activity' do
      group = groups(:group_sample_transfer)

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.samples.transfer')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.samples.transfer_html'
      end

      render_inline Activities::Groups::SampleTransferActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t(
          'activity.group.samples.transfer_html',
          user: 'System',
          transferred_samples_count: activity_to_render[:transferred_samples_count]
        )
      )

      assert_selector 'a', text: I18n.t(:'components.activity.more_details')
    end
  end
end
