# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:john_doe)
    @project = projects(:project1)
    @namespace = namespaces_user_namespaces(:john_doe_namespace)
    @old_namespace = groups(:group_one)
  end

  test 'should redirect with success flash when transfer succeeds' do
    post namespace_project_transfer_path(@old_namespace, @project),
         params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream

    assert_response :redirect
    assert_equal I18n.t('projects.transfer.success', project_name: @project.name), flash[:success]
    assert_redirected_to namespace_project_path(@namespace, @project)
  end

  test 'should not transfer a project to unowned namespace' do
    sign_in users(:david_doe)

    post namespace_project_transfer_path(@old_namespace, @project),
         params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream

    assert_response :unauthorized
  end

  test 'should render unprocessable_content when transfer fails' do
    post namespace_project_transfer_path(@old_namespace, @project),
         params: { projects_transfer_form: { new_namespace_id: 'invalid-id' } }, as: :turbo_stream

    assert_response :unprocessable_content
  end
end
