# frozen_string_literal: true

require 'test_helper'

module Projects
  class GroupLinksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

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

      assert_response :unprocessable_entity
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

      assert_response :unprocessable_entity
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

      assert_response :unprocessable_entity
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
