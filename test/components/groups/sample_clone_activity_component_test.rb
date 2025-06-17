# frozen_string_literal: true

require 'view_component_test_case'

module Groups
  class SampleCloneActivityComponentTest < ViewComponentTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @user = users(:john_doe)
    end

    test 'group sample clone source and target activities' do
      group = groups(:group_one)
      project_namespace = namespaces_project_namespaces(:project2_namespace)
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)
      Groups::Samples::CloneService.new(group, @user)
                                   .execute(
                                     project_namespace.project.id,
                                     [sample1.id, sample2.id],
                                     nil
                                   )

      activities = group.human_readable_activity(group.retrieve_group_activity).reverse

      assert_equal(1, activities.count do |activity|
        activity[:key].include?('group.samples.clone')
      end)

      activity_to_render = activities.find do |a|
        a[:key] == 'activity.group.samples.clone_html'
      end

      render_inline Activities::Groups::SampleCloneActivityComponent.new(activity: activity_to_render)

      assert_text strip_tags(
        I18n.t('activity.group.samples.clone_html', user: @user.email,
                                                    cloned_samples_count: activity_to_render[:cloned_samples_count])
      )
      assert_selector 'span', text: 2

      assert_selector 'button', text: I18n.t(:'components.activity.more_details')
    end
  end
end
