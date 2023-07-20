# frozen_string_literal: true

require 'test_helper'

module Projects
  class ShareControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should share project namespace with group' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project22)
      project_namespace = project.namespace

      post namespace_project_share_path(project_namespace.parent, project,
                                        params: { shared_group_id: namespace.id,
                                                  group_access_level: Member::AccessLevel::ANALYST })

      assert_redirected_to namespace_project_path(project_namespace.parent, project_namespace.project)
    end

    # test 'should not share project with group as group doesn\'t exist' do
    #   sign_in users(:john_doe)
    #   group_id = 1
    #   project_namespace = namespaces_project_namespaces(:project1_namespace)

    #   post namespace_project_share_path(project_namespace.parent, project_namespace.project,
    #                                     params: { shared_group_id: group_id,
    #                                               group_access_level: Member::AccessLevel::ANALYST })

    #   assert_response :unprocessable_entity
    # end

    test 'shouldn\'t share project namespace with group as user doesn\'t have correct permissions' do
      sign_in users(:micha_doe)
      group = groups(:group_one)
      project_namespace = namespaces_project_namespaces(:project23_namespace)

      post namespace_project_share_path(project_namespace.parent, project_namespace.project,
                                        params: { shared_group_id: group.id,
                                                  group_access_level: Member::AccessLevel::ANALYST })

      assert_response :unauthorized
    end

    # test 'project namespace already shared with group' do
    #   sign_in users(:john_doe)
    #   group = groups(:group_one)
    #   project_namespace = namespaces_project_namespaces(:project1_namespace)

    #   post namespace_project_share_path(project_namespace.parent, project_namespace.project,
    #                                     params: { shared_group_id: group.id,
    #                                               group_access_level: Member::AccessLevel::ANALYST })

    #   namespace_project_path(project_namespace.parent,
    #                          project_namespace.project)

    #   post namespace_project_share_path(project_namespace.parent, project_namespace.project,
    #                                     params: { shared_group_id: group.id,
    #                                               group_access_level: Member::AccessLevel::ANALYST })

    #   assert_response :conflict
    # end
  end
end
