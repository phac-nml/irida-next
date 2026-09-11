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
    assert_changes -> { @project.namespace.reload.parent }, from: @old_namespace, to: @namespace do
      post namespace_project_transfer_path(@old_namespace, @project),
           params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream
    end

    assert_response :redirect
    assert_equal I18n.t('projects.transfer.success', project_name: @project.name), flash[:success]
    assert_redirected_to namespace_project_path(@namespace, @project)
  end

  test 'should not transfer a project to unowned namespace' do
    sign_in users(:david_doe)

    assert_no_changes -> { @project.namespace.reload.parent } do
      post namespace_project_transfer_path(@old_namespace, @project),
           params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream
    end

    assert_response :unauthorized
    assert_select "div[data-viral--flash-type-value='error']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.error')}: #{I18n.t(
                      'action_policy.policy.project.transfer?',
                      name: @project.name
                    )}"
    end
  end

  test 'should render unprocessable_content when transfer fails' do
    assert_no_changes -> { @project.namespace.reload.parent } do
      post namespace_project_transfer_path(@old_namespace, @project),
           params: { projects_transfer_form: { new_namespace_id: 'invalid-id' } }, as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: Projects::TransferForm.human_attribute_name(:new_namespace_id),
                   message: I18n.t(:'activemodel.errors.models.projects/transfer_form.attributes.new_namespace_id.not_found')) # rubocop:disable Layout/LineLength
    assert_select "div[class='form-field invalid']"
  end

  test 'should render unprocessable_content when transfer to namespace with same project name' do
    project2 = projects(:project2)
    assert_no_changes -> { @project.namespace.reload.parent } do
      post namespace_project_transfer_path(project2.namespace.parent, project2),
           params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
        I18n.t(:'errors.format',
               attribute: Projects::TransferForm.human_attribute_name(:new_namespace_id),
               message: I18n.t(:'activemodel.errors.models.projects/transfer_form.attributes.new_namespace_id.project_exists')) # rubocop:disable Layout/LineLength
    assert_select "div[class='form-field invalid']"
  end
end
