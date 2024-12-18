# frozen_string_literal: true

require 'test_helper'

class ProjectShareActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'project to group links index' do
    sign_in users(:john_doe)

    project_namespace = namespaces_project_namespaces(:project20_namespace)
    get namespace_project_group_links_path(project_namespace.parent, project_namespace.project, format: :turbo_stream)

    assert_response :success
    assert_equal 3, project_namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'project to group link' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    project = projects(:project22)
    project_namespace = project.namespace

    post namespace_project_group_links_path(project_namespace.parent, project,
                                            params: { namespace_group_link: {
                                              group_id: group.id,
                                              group_access_level: Member::AccessLevel::ANALYST
                                            }, format: :turbo_stream })

    assert_response :success
    assert_equal 2,
                 project_namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'project to group link destroy' do
    sign_in users(:john_doe)

    namespace_group_link = namespace_group_links(:namespace_group_link1)
    namespace = namespace_group_link.namespace

    assert_equal 3, namespace.shared_with_group_links.of_ancestors_and_self.count

    delete namespace_project_group_link_path(namespace.parent, namespace.project,
                                             namespace_group_link.id,
                                             format: :turbo_stream)

    assert_response :success

    assert_equal 2, namespace.shared_with_group_links.of_ancestors_and_self.count
  end

  test 'project to group link update' do
    sign_in users(:john_doe)

    namespace_group_link = namespace_group_links(:namespace_group_link1)
    project_namespace = namespace_group_link.namespace

    assert_equal namespace_group_link.group_access_level, Member::AccessLevel::MAINTAINER

    patch namespace_project_group_link_path(project_namespace.parent,
                                            project_namespace.project,
                                            namespace_group_link, params: {
                                              namespace_group_link: {
                                                group_access_level: Member::AccessLevel::GUEST
                                              }, format: :turbo_stream
                                            })

    assert_response :success

    assert_equal Member::AccessLevel::GUEST, namespace_group_link.reload.group_access_level
  end
end
