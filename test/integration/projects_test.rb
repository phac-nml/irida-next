# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:john_doe)
    sign_in @user
    @project = projects(:project1)
    @namespace = namespaces_user_namespaces(:john_doe_namespace)
    @old_namespace = groups(:group_one)
  end

  test 'project index redirects to dashboard projects' do
    get projects_path

    assert_redirected_to dashboard_projects_path
    follow_redirect!
    assert_response :success
    assert_select 'h1', text: I18n.t('dashboard.projects.index.title')
  end

  test 'can view a project' do
    get namespace_project_path(@project.namespace.parent, @project)

    assert_response :success
    assert_select 'h1', text: @project.name
    assert_select 'p', text: @project.description
    assert_select 'span', text: @project.puid
    assert_select 'h2', text: I18n.t('components.project_dashboard.info_title')
    assert_select 'h2', text: I18n.t('components.project_dashboard.activity_title')
    assert_select 'h2', text: I18n.t('components.project_dashboard.samples_title')
  end

  test 'cannot view project if uploader' do
    login_as users(:projectJeff_bot)
    project = projects(:projectJeff)

    get namespace_project_path(project.namespace.parent, project)

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.read?', name: project.name)
  end

  test 'cannot view project if member is expired' do
    project = projects(:project1)
    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save(validate: false)
    project_member = members(:project_one_member_john_doe)
    project_member.expires_at = 10.days.ago.to_date
    project_member.save(validate: false)

    get namespace_project_path(project.namespace.parent, project)

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.read?', name: project.name)
  end

  test 'cannot view the project if user has insufficient permissions' do
    project = projects(:project1)
    sign_in users(:micha_doe)

    get namespace_project_path(project.namespace.parent, project)

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.read?', name: project.name)
  end

  test "cannot view project that doesn't exist" do
    sign_in users(:john_doe)

    get namespace_project_path(project_id: 'does-not-exist', namespace_id: 'does-not-exist')

    assert_response :not_found
    assert_select 'h1', text: I18n.t('application.errors.resource_not_found')
    assert_select 'p', text: I18n.t('application.errors.not_found_on_server')
  end

  test 'can view new project forms and create a project' do
    project_name = 'New Project'
    project_description = 'New Project Description'
    group = groups(:group_one)

    form_cases = [
      { path: new_project_path, parent_id: @namespace.id },
      { path: new_project_path(group_id: group.id), parent_id: group.id }
    ]

    form_cases.each do |form_case|
      get form_case.fetch(:path)

      assert_response :success
      assert_select 'h1', text: I18n.t('projects.new.title')
      assert_select 'form' do
        assert_select 'input[name="project[namespace_attributes][name]"]'
        assert_select "input[name=\"project[namespace_attributes][parent_id]\"][value=
          \"#{form_case.fetch(:parent_id)}\"]"
        assert_select 'input[name="project[namespace_attributes][path]"]'
        assert_select 'textarea[name="project[namespace_attributes][description]"]'
        assert_select 'input[type="submit"]', value: I18n.t('projects.new.submit')
      end
    end

    assert_difference('Project.count', 1) do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: project_name,
                 path: 'new-project',
                 parent_id: @namespace.id,
                 description: project_description
               }
             }
           }
    end

    project = Project.order(created_at: :desc).first
    assert_redirected_to namespace_project_path(project.namespace.parent, project)
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div', "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.create.success', project_name:)}"
    end

    assert_select 'h1', text: project_name
    assert_select 'p', text: project_description
    assert_select 'nav#sidebar', text: /#{Regexp.escape(project_name)}/
    assert_select '#breadcrumb', text: /#{Regexp.escape(project_name)}/
  end

  test 'can view the new project form with v2 select2 controls' do
    Flipper.enable(:v2_prefixed_select2)

    get new_project_path

    assert_response :success
    assert_select 'form[data-controller="select2--v2"]', count: 1
  ensure
    Flipper.disable(:v2_prefixed_select2)
  end

  test "cannot create project under another user's namespace" do
    sign_in users(:david_doe)

    assert_no_difference('Project.count') do
      post projects_path,
           params: { project: { namespace_attributes: { name: 'My Personal Project', path: 'my-personal-project',
                                                        parent_id: @namespace.id } } }
    end

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.namespaces/user_namespace.create?', name: @namespace.name)
  end

  test 'cannot create project with invalid params' do
    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'a',
                 path: 'new-project',
                 parent_id: @namespace.id
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
             I18n.t(:'errors.format',
                    attribute: Namespaces::ProjectNamespace.human_attribute_name(:name),
                    message: I18n.t('errors.messages.too_short.other', count: 3))
    end

    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: projects(:john_doe_project2).name,
                 path: 'new-project',
                 parent_id: @namespace.id
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
             I18n.t(:'errors.format',
                    attribute: Namespaces::ProjectNamespace.human_attribute_name(:name),
                    message: I18n.t('errors.messages.taken'))
    end

    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'New Project',
                 path: 'new-project',
                 parent_id: @namespace.id,
                 description: 'a' * 256
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
             I18n.t(:'errors.format',
                    attribute: Namespaces::ProjectNamespace.human_attribute_name(:description),
                    message: I18n.t('errors.messages.too_long.other', count: 255))
    end

    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'New Project',
                 path: 'a wrong path',
                 parent_id: @namespace.id
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
              I18n.t(:'errors.format',
                     attribute: Namespaces::ProjectNamespace.human_attribute_name(:path),
                     message: I18n.t('activerecord.errors.models.namespace.attributes.path.invalid_format'))
    end

    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'New Project',
                 path: projects(:john_doe_project2).path,
                 parent_id: @namespace.id
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
             I18n.t(:'errors.format',
                    attribute: Namespaces::ProjectNamespace.human_attribute_name(:path),
                    message: I18n.t('errors.messages.taken'))
    end

    assert_no_difference('Project.count') do
      post projects_path,
           params: {
             project: {
               namespace_attributes: {
                 name: 'Project without namespace',
                 path: 'project-without-namespace',
                 parent_id: '',
                 description: 'Project description'
               }
             }
           }
    end

    assert_response :unprocessable_content
    assert_select 'div[data-controller="form-error-summary"]' do
      assert_select 'a', text:
             I18n.t(:'errors.format',
                    attribute: Namespaces::ProjectNamespace.human_attribute_name(:namespace),
                    message: I18n.t('services.projects.create.namespace_required'))
    end
  end

  test 'cannot view edit project form with insufficient permissions' do
    sign_in users(:david_doe)
    get namespace_project_edit_path(@project.namespace.parent, @project)

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.edit?', name: @project.name)
  end

  test 'can view edit project form and update project details as an authorized member' do
    project_name = 'Updated project name'
    project_description = 'Updated project description'
    project_path = 'updated-project-path'

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
    assert_select 'button', text: I18n.t('groups.edit.advanced.change_visibility.submit'), count: 0

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
                      project_name: project_name
                    )}"
    end
    assert_changes -> { @project.reload.path }, from: @project.namespace.path, to: project_path do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { path: project_path }
              },
              format: :turbo_stream
            }
    end

    assert_redirected_to namespace_project_edit_path(@project.namespace.parent, @project)
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.update.success',
                                                                    project_name: @project.name)}"
    end

    group_project = projects(:project2)

    assert_changes -> { [group_project.reload.name, group_project.path] },
                   from: [group_project.name, group_project.path],
                   to: ['Awesome Project 2', 'awesome-project-2'] do
      patch namespace_project_path(group_project.namespace.parent, group_project),
            params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } },
                      format: :turbo_stream }
    end

    assert_redirected_to namespace_project_edit_path(group_project.namespace.parent, group_project.reload)
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.update.success',
                                                                    project_name: group_project.name)}"
    end
  end

  test 'cannot update project with invalid params' do
    assert_no_changes -> { @project.reload.path } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { path: projects(:project2).namespace.path }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: Namespaces::ProjectNamespace.human_attribute_name(:path),
                      message: I18n.t('errors.messages.taken'))

    assert_no_changes -> { @project.reload.path } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { path: 'a wrong path' }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: Namespaces::ProjectNamespace.human_attribute_name(:path),
                      message: I18n.t('activerecord.errors.models.namespace.attributes.path.invalid_format'))

    assert_no_changes -> { @project.reload.name } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { name: 'a' }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: Namespaces::ProjectNamespace.human_attribute_name(:name),
                      message: I18n.t('errors.messages.too_short.other', count: 3))

    assert_no_changes -> { @project.reload.name } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { name: projects(:project2).name }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: Namespaces::ProjectNamespace.human_attribute_name(:name),
                      message: I18n.t('errors.messages.taken'))

    assert_no_changes -> { @project.reload.description } do
      patch namespace_project_path(@project.namespace.parent, @project),
            params: {
              project: {
                namespace_attributes: { description: 'a' * 256 }
              },
              format: :turbo_stream
            }
    end

    assert_response :unprocessable_content
    assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: Namespaces::ProjectNamespace.human_attribute_name(:description),
                      message: I18n.t('errors.messages.too_long', count: 255))
  end

  test "can update project which is under the user's namespace" do
    sign_in users(:john_doe)

    project = projects(:john_doe_project2)

    assert_changes -> { [project.reload.name, project.path] },
                   from: [project.name, project.path],
                   to: ['Awesome Project 2', 'awesome-project-2'] do
      patch namespace_project_path(project.namespace.parent, project),
            params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } },
                      format: :turbo_stream }
    end

    assert_redirected_to namespace_project_edit_path(project.namespace.parent, project.reload)
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.update.success',
                                                                    project_name: project.name)}"
    end
  end

  test "cannot update project which which is under another user's namespace" do
    sign_in users(:david_doe)

    project = projects(:john_doe_project2)

    assert_no_changes -> { [project.reload.name, project.reload.path] } do
      patch namespace_project_path(project.namespace.parent, project),
            params: { project: { namespace_attributes: { name: 'Awesome Project 2',
                                                         path: 'awesome-project-2' } } }
    end

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.namespaces/project_namespace.update?', name: project.name)
  end

  test 'can view project activity' do
    project = projects(:project2)

    get namespace_project_activity_path(project.namespace.parent, project)

    assert_response :success
    assert_select 'h1', text: I18n.t('projects.activity.title')
    assert_select 'ol#activities li', minimum: 1
  end

  test 'cannot view project activity' do
    sign_in users(:david_doe)
    project = projects(:john_doe_project2)

    get namespace_project_activity_path(project.namespace.parent, project)

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.activity?', name: project.name)
  end

  test 'can destroy a project' do
    project = projects(:john_doe_project2)

    assert_difference('Project.count', -1) do
      delete namespace_project_path(project.namespace.parent, project)
    end

    assert_redirected_to dashboard_projects_path
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.destroy.success',
                                                                    project_name: project.name)}"
    end
  end

  test 'cannot destroy project if user does not have sufficient permissions' do
    sign_in users(:joan_doe)

    project = projects(:john_doe_project2)

    assert_no_difference('Project.count') do
      delete namespace_project_path(namespace_id: @namespace.path, project_id: project.namespace.path)
    end

    assert_response :unauthorized
    assert_select 'h1', text: I18n.t('application.errors.access_denied')
    assert_select 'p', text: I18n.t('action_policy.policy.project.destroy?', name: project.name)
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
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='error']" do
      assert_select 'div', "#{I18n.t('common.statuses.error')}: Project could not be deleted"
    end
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

  test 'owner sees the transfer form with v2 select2 controls' do
    Flipper.enable(:v2_select2)

    get namespace_project_edit_path(@project.namespace.parent, @project)

    assert_response :success
    assert_select 'form#edit_advanced_transfer[data-controller="select2--v2"]' do
      assert_select '[data-select2--v2-target="submitButton"]', disabled: 'disabled', count: 1
    end
  ensure
    Flipper.disable(:v2_select2)
  end

  test 'should redirect with success flash when transfer succeeds' do
    assert_changes -> { @project.namespace.reload.parent }, from: @old_namespace, to: @namespace do
      post namespace_project_transfer_path(@old_namespace, @project),
           params: { projects_transfer_form: { new_namespace_id: @namespace.id } }, as: :turbo_stream
    end

    assert_response :redirect
    assert_redirected_to namespace_project_path(@namespace, @project)
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t('projects.transfer.success',
                                                                    project_name: @project.name)}"
    end
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
