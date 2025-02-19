# frozen_string_literal: true

require 'view_component_test_case'

class MemberActivityComponentTest < ViewComponentTestCase
  include ActionView::Helpers::SanitizeHelper

  setup do
    @user = users(:john_doe)
    @member = members(:project_one_member_ryan_doe)
    @project_namespace = namespaces_project_namespaces(:project1_namespace)
    @group = groups(:group_one)
  end

  test 'add member to project activity' do
    activities = @project_namespace.human_readable_activity(@project_namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.create') && activity[:member] == @member
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.member.create_html' && a[:member] == @member
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.member.create_html',
             user: 'System',
             href: @member.user.email)
    )
    assert_selector 'a',
                    text: @member.user.email
  end

  test 'update member in project activity' do
    update_params = { access_level: Member::AccessLevel::UPLOADER }
    ::Members::UpdateService.new(@member, @project_namespace, @user, update_params).execute

    activities = @project_namespace.human_readable_activity(@project_namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.update')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.member.update_html'
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.member.update_html',
             user: @user.email,
             href: @member.user.email)
    )
    assert_selector 'a',
                    text: @member.user.email
  end

  test 'soft delete member in project activity' do
    ::Members::DestroyService.new(@member, @project_namespace, @user).execute

    activities = @project_namespace.human_readable_activity(@project_namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.destroy')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.member.destroy_html'
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.member.destroy_html',
             user: @user.email,
             href: @member.user.email)
    )
    assert_no_selector 'a',
                       text: @member.user.email
  end

  test 'create project member then really destroy activity' do
    @member.destroy
    Member.only_deleted.where(id: @member.id).first.destroy

    activities = @project_namespace.human_readable_activity(@project_namespace.retrieve_project_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.create') && activity[:member_email] == @member.user.email
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.member.create_html' && a[:member_email] == @member.user.email
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.namespaces_project_namespace.member.create_html',
             user: 'System',
             href: @member.user.email)
    )
    assert_no_selector 'a',
                       text: @member.user.email
  end

  test 'add member to group activity' do
    member = members(:group_one_member_james_doe)
    activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.create') && activity[:member] == member
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.group.member.create_html' && a[:member] == member
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.group.member.create_html',
             user: 'System',
             href: member.user.email)
    )
    assert_selector 'a',
                    text: member.user.email
  end

  test 'update member in group activity' do
    member = members(:group_one_member_james_doe)
    update_params = { access_level: Member::AccessLevel::UPLOADER }
    ::Members::UpdateService.new(member, @group, @user, update_params).execute

    activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.update')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.group.member.update_html'
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.group.member.update_html',
             user: @user.email,
             href: member.user.email)
    )
    assert_selector 'a',
                    text: member.user.email
  end

  test 'soft delete member in group activity' do
    member = members(:group_one_member_james_doe)
    ::Members::DestroyService.new(member, @group, @user).execute

    activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.destroy')
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.group.member.destroy_html'
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.group.member.destroy_html',
             user: @user.email,
             href: member.user.email)
    )
    assert_no_selector 'a',
                       text: member.user.email
  end

  test 'create group member then really destroy activity' do
    member = members(:group_one_member_james_doe)
    member.destroy
    Member.only_deleted.where(id: member.id).first.destroy

    activities = @group.human_readable_activity(@group.retrieve_group_activity).reverse

    assert_equal(1, activities.count do |activity|
      activity[:key].include?('member.create') && activity[:member_email] == member.user.email
    end)

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.group.member.create_html' && a[:member_email] == member.user.email
    end

    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)

    assert_text strip_tags(
      I18n.t('activity.group.member.create_html',
             user: 'System',
             href: member.user.email)
    )
    assert_no_selector 'a',
                       text: member.user.email
  end
end
