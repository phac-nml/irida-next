# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class SampleActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'batch sample import actvity' do
      group = groups(:group_one)
      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.import_samples.create')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.import_samples.create_html'
      end

      render_inline Activities::Groups::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.import_samples.create_html',
               user: 'System',
               href: 2)
      )
      assert_selector 'span', text: 2
    end

    test 'multiple sample destroy activity' do
      group = groups(:group_one)
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)

      params = { sample_ids: [sample1.id, sample2.id] }
      Groups::Samples::DestroyService.new(group, @user, params).execute

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(2, activities.count do |activity|
        activity[:key].include?('group.samples.destroy')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.samples.destroy_html'
      end

      render_inline Activities::Groups::SampleActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.samples.destroy_html', user: @user.email,
                                                      href: 2)
      )
      assert_selector 'span', text: 2

      assert_selector 'a', text: I18n.t(:'components.activity.more_details')
    end
  end
end
