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

  test 'project index redirects to dashboard projects' do
    get projects_path

    assert_redirected_to dashboard_projects_path
  end

  test 'can show a project' do
    get namespace_project_path(@project.namespace.parent, @project)

    assert_response :success
    assert_select 'h1', text: @project.name
    assert_select 'p', text: @project.description
    assert_select 'span', text: @project.puid
    assert_select 'h2', text: I18n.t('components.project_dashboard.info_title')
    assert_select 'h2', text: I18n.t('components.project_dashboard.activity_title')
    assert_select 'h2', text: I18n.t('components.project_dashboard.samples_title')
  end

  test 'can view new project form' do
    get new_project_path

    assert_response :success
    assert_select 'h1', text: I18n.t('projects.new.title')
    assert_select 'form' do
      assert_select 'input[name="project[namespace_attributes][name]"]'
      assert_select "input[name=\"project[namespace_attributes][parent_id]\"][value=\"#{@namespace.id}\"]"
      assert_select 'input[name="project[namespace_attributes][path]"]'
      assert_select 'textarea[name="project[namespace_attributes][description]"]'
      assert_select 'input[type="submit"]', value: I18n.t('projects.new.submit')
    end
  end

  test 'includes the group in the new project page title' do
    group = groups(:group_one)

    get new_project_path(group_id: group.id)

    assert_response :success
    assert_select 'h1', text: I18n.t('projects.new.title')
    assert_select 'form' do
      assert_select 'input[name="project[namespace_attributes][name]"]'
      assert_select "input[name=\"project[namespace_attributes][parent_id]\"][value=\"#{group.id}\"]"
      assert_select 'input[name="project[namespace_attributes][path]"]'
      assert_select 'textarea[name="project[namespace_attributes][description]"]'
      assert_select 'input[type="submit"]', value: I18n.t('projects.new.submit')
    end
  end

  test 'can create a project' do
    project_name = 'New Project'

    assert_difference('Project.count', 1) do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: project_name,
                 path: 'new-project',
                 parent_id: @namespace.id
               }
             }
           }
    end

    project = Project.order(created_at: :desc).first
    assert_redirected_to namespace_project_path(project.namespace.parent, project)
    assert_equal I18n.t('projects.create.success', project_name:), flash[:success]
  end

  test 'renders the new project form when creation fails' do
    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'Invalid Project',
                 path: 'a wrong path',
                 parent_id: @namespace.id
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: Project.human_attribute_name(:path),
                   message: I18n.t('activerecord.errors.models.namespace.attributes.path.invalid_format'))
  end

  test 'can view edit project form' do
    get namespace_project_edit_path(@project.namespace.parent, @project)

    assert_response :success
    assert_select 'h1', text: I18n.t('projects.edit.general.title')
    assert_select 'form' do
      assert_select 'input[name="project[namespace_attributes][name]"]'
      assert_select 'textarea[name="project[namespace_attributes][description]"]'
      assert_select 'input[type="submit"]', value: I18n.t('projects.edit.general.submit')
    end
    assert_select 'h2', text: I18n.t('projects.edit.advanced.title')
    assert_select 'form' do
      assert_select 'input[name="project[namespace_attributes][path]"]'
      assert_select 'input[type="submit"]', value: I18n.t('projects.edit.advanced.path.submit')
    end
  end

  test 'can update a project' do
    project_name = 'Updated Integration Project'
    project_description = 'Updated integration project description'

    assert_changes -> { [@project.reload.name, @project.namespace.description] },
                   from: [@project.name, @project.namespace.description],
                   to: [project_name, project_description] do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: {
                  name: project_name,
                  description: project_description
                }
              },
              format: :turbo_stream
            }
    end

    assert_response :success
    assert_select "div[data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t(
                      'projects.update.success',
                      project_name:
                    )}"
    end
  end

  test 'can update a project path' do
    project_path = 'updated-integration-project-path'

    assert_changes -> { @project.reload.namespace.path }, from: @project.namespace.path, to: project_path do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { path: project_path }
              },
              format: :turbo_stream
            }
    end

    assert_redirected_to namespace_project_edit_path(@project.namespace.parent, @project)
    assert_equal I18n.t('projects.update.success', project_name: @project.name), flash[:success]
  end

  test 'renders the project edit form when update fails' do
    assert_no_changes -> { @project.reload.namespace.path } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { path: 'p1' }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
          /#{Regexp.escape(I18n.t(:'errors.format',
                                  attribute: Project.human_attribute_name(:path),
                                  message: I18n.t('errors.messages.too_short', count: 3)))}/
  end

  test 'can view project activity' do
    project = projects(:project2)

    get namespace_project_activity_path(project.namespace.parent, project)

    assert_response :success
    assert_select 'h1', text: I18n.t('projects.activity.title')
    assert_select 'ol#activities li', minimum: 1
  end

  test 'can destroy a project' do
    project = projects(:john_doe_project2)

    assert_difference('Project.count', -1) do
      delete namespace_project_path(project.namespace.parent, project)
    end

    assert_redirected_to dashboard_projects_path
    assert_equal I18n.t('projects.destroy.success', project_name: project.name), flash[:success]
  end

  test 'redirects to the project with an error when destruction fails' do
    destroy_service_mock = mock('destroy_service')
    destroy_service_mock.expects(:execute).once
    Projects::DestroyService.expects(:new).with(@project, users(:john_doe)).returns(destroy_service_mock)
    ProjectsController.any_instance.expects(:error_message).with(@project).once.returns('Project could not be deleted')

    assert_no_difference('Project.count') do
      delete namespace_project_path(@project.namespace.parent, @project)
    end

    assert_redirected_to namespace_project_path(@project.namespace.parent, @project)
    assert_equal 'Project could not be deleted', flash[:error]
  end

  test 'owner can see project transfer section in general settings' do
    get namespace_project_edit_path(@project.namespace.parent, @project)

    assert_response :success
    assert_select 'h2', text: I18n.t('projects.edit.advanced.transfer.title')
  end

  test 'maintainer cannot see project transfer section in general settings' do
    sign_in users(:joan_doe)
    get namespace_project_edit_path(@project.namespace.parent, @project)

    assert_response :success
    assert_equal Member::AccessLevel::MAINTAINER,
                 Member.find_by(user: users(:joan_doe), namespace: @project.namespace.parent).access_level
    assert_select 'h2', text: I18n.t('projects.edit.advanced.transfer.title'), count: 0
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

  test 'maintainer should not transfer a project' do
    sign_in users(:joan_doe)

    assert_no_changes -> { @project.namespace.reload.parent } do
      post namespace_project_transfer_path(@old_namespace, @project),
           params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream
    end

    assert_response :unauthorized
    assert_equal Member::AccessLevel::MAINTAINER,
                 Member.find_by(user: users(:joan_doe), namespace: @project.namespace.parent).access_level
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
