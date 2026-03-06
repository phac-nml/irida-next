# frozen_string_literal: true

require 'test_helper'

module Projects
  class GroupLinksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should apply default sort and support sorting project group links' do
      sign_in users(:john_doe)

      project_namespace = namespaces_project_namespaces(:project25_namespace)
      project = projects(:project25)
      group_link2 = namespace_group_links(:namespace_group_link2)
      group_link5 = namespace_group_links(:namespace_group_link5)
      group_link14 = namespace_group_links(:namespace_group_link14)

      get namespace_project_group_links_path(project_namespace.parent, project, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(group_link2.group.name, group_link5.group.name)

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'group_name desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      group_names = Nokogiri::HTML(response.body).css('table tbody tr td:first-child').map { |node| node.text.squish }
      assert_equal group_link14.group.name, group_names.first
      assert_equal group_link2.group.name, group_names.last

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'group_access_level asc' })
      assert_response :success
      assert_sort_state(4, 'ascending')
      group_names = Nokogiri::HTML(response.body).css('table tbody tr td:first-child').map { |node| node.text.squish }
      assert_equal group_link5.group.name, group_names.first
      assert_equal group_link14.group.name, group_names.last

      get namespace_project_group_links_path(project_namespace.parent, project,
                                             format: :turbo_stream, group_links_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
    end

    test 'should share project namespace with group' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      project = projects(:project22)
      project_namespace = project.namespace

      post namespace_project_group_links_path(project_namespace.parent, project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :ok
    end

    test 'should not share project with group as group doesn\'t exist' do
      sign_in users(:john_doe)
      group_id = 1
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id:,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'shouldn\'t share project namespace with group as user doesn\'t have correct permissions' do
      sign_in users(:micha_doe)
      group = groups(:group_one)
      project_namespace = namespaces_project_namespaces(:project23_namespace)

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              } })

      assert_response :unauthorized
    end

    test 'project namespace already shared with group' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      project_namespace = namespaces_project_namespaces(:project1_namespace)

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :ok

      post namespace_project_group_links_path(project_namespace.parent, project_namespace.project,
                                              params: { namespace_group_link: {
                                                group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST
                                              }, format: :turbo_stream })

      assert_response :unprocessable_content
    end

    test 'unshare project' do
      sign_in users(:john_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link.namespace

      delete namespace_project_group_link_path(project_namespace.parent,
                                               project_namespace.project,
                                               namespace_group_link,
                                               format: :turbo_stream)

      assert_response :ok
    end

    test 'unshare project when link doesn\'t exist' do
      sign_in users(:john_doe)

      project_namespace = namespaces_project_namespaces(:project23_namespace)

      delete namespace_project_group_link_path(project_namespace.parent,
                                               project_namespace.project,
                                               1,
                                               format: :turbo_stream)

      assert_response :not_found
    end

    test 'should not unshare project with group as user doesn\'t have correct permissions' do
      sign_in users(:ryan_doe)
      namespace_group_link = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link.namespace

      delete namespace_project_group_link_path(project_namespace.parent,
                                               project_namespace.project,
                                               namespace_group_link)

      assert_response :unauthorized
    end

    test 'should update namespace group share' do
      sign_in users(:john_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link.namespace

      patch namespace_project_group_link_path(project_namespace.parent,
                                              project_namespace.project,
                                              namespace_group_link,
                                              params: {
                                                namespace_group_link: {
                                                  group_access_level: Member::AccessLevel::GUEST
                                                }, format: :turbo_stream
                                              })

      assert_response :ok
    end

    test 'should not update namespace group share due to invalid params' do
      sign_in users(:john_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link.namespace

      patch namespace_project_group_link_path(project_namespace.parent,
                                              project_namespace.project,
                                              namespace_group_link,
                                              params: {
                                                namespace_group_link: {
                                                  group_access_level: -1
                                                }, format: :turbo_stream
                                              })

      assert_response :unprocessable_content
    end

    test 'should not update namespace group share due to incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace_group_link = namespace_group_links(:namespace_group_link1)

      project_namespace = namespace_group_link.namespace

      patch namespace_project_group_link_path(project_namespace.parent,
                                              project_namespace.project,
                                              namespace_group_link,
                                              params: {
                                                namespace_group_link: {
                                                  group_access_level: Member::AccessLevel::GUEST
                                                }
                                              })
      assert_response :unauthorized
    end
  end
end
