# frozen_string_literal: true

require 'application_system_test_case'

class ProjectsTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'can create a project' do
    new_project_name = 'Project 1'
    visit new_project_path

    assert_selector 'h1', text: I18n.t(:'projects.new.title'), count: 1

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: new_project_name
      click_on I18n.t(:'projects.new.submit')
    end

    assert_text I18n.t(:'projects.create.success', project_name: new_project_name)
    assert_selector 'h1', text: new_project_name
  end

  test 'show error when creating a project with a short name' do
    new_project_name = 'a'
    visit new_project_path

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: new_project_name
      click_on I18n.t(:'projects.new.submit')
    end

    error_message = find_field('Path')[:title]
    assert_equal error_message, I18n.t(:'projects.new.help')
    assert_current_path new_project_path
  end

  test 'can update project name and description' do
    project_name = 'New Project'
    project_description = 'New Project Description'

    visit project_edit_path(projects(:project1))
    assert_text I18n.t(:'projects.edit.general.title')

    fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
    fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
    click_on I18n.t(:'projects.edit.general.submit')
    assert_selector 'h1', text: project_name
    assert_text project_description
  end

  test 'can view project' do
    visit namespace_project_url(groups(:group_one), projects(:project1))

    assert_selector 'h1', text: 'Project 1'
  end

  test 'can not view project' do
    login_as users(:david_doe)

    group = groups(:group_one)
    project = projects(:project1)
    visit namespace_project_url(group, project)

    assert_text I18n.t(:'action_policy.policy.project.read?', name: project.name)
  end

  test 'can access edit project' do
    visit project_edit_path(projects(:project1))

    assert_text I18n.t(:'projects.edit.general.title')
  end

  test 'cannot access edit project' do
    login_as users(:david_doe)

    project = projects(:project1)
    visit project_edit_path(project)

    assert_text I18n.t(:'action_policy.policy.project.edit?', name: project.name)
  end

  test 'can delete a project' do
    project = projects(:project1)
    visit project_edit_path(project)
    assert_selector 'a', text: I18n.t(:'projects.edit.advanced.destroy.submit'), count: 1
    click_link I18n.t(:'projects.edit.advanced.destroy.submit')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_text I18n.t(:'projects.destroy.success', project_name: project.name)
  end

  test 'can edit a project path' do
    project = projects(:project1)
    visit project_edit_path(project)

    within all('form[action="/group-1/project-1"]')[1] do
      fill_in 'project_namespace_attributes_path', with: 'project-1-edited'

      click_on I18n.t(:'projects.edit.advanced.path.submit')
    end

    assert_text I18n.t('projects.update.success', project_name: project.name)
    assert_current_path '/group-1/project-1-edited'
  end

  test 'show error when editing a project path to an existing namespace' do
    project = projects(:project1)
    visit project_edit_path(project)

    within all('form[action="/group-1/project-1"]')[1] do
      fill_in 'project_namespace_attributes_path', with: 'project-2'

      click_on I18n.t(:'projects.edit.advanced.path.submit')
    end

    assert_text I18n.t('activerecord.errors.models.namespace.attributes.name.taken').downcase
    assert_current_path '/group-1/project-1/-/edit'
  end
end
