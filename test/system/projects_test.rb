# frozen_string_literal: true

require 'application_system_test_case'

class ProjectsTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'can see the list of projects' do
    visit projects_url

    assert_selector 'h1', text: I18n.t(:'projects.index.title')
    assert_selector 'tr', count: 20
    assert_text projects(:project1).human_name
    assert_selector 'a', text: I18n.t(:'components.pagination.next')
    assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

    click_on I18n.t(:'components.pagination.next')
    assert_selector 'tr', count: 6
    click_on I18n.t(:'components.pagination.previous')
    assert_selector 'tr', count: 20

    click_link projects(:project1).human_name
    assert_selector 'h1', text: projects(:project1).name
  end

  test 'can create a project from index page' do
    project_name = 'New Project'
    project_description = 'New Project Description'

    visit projects_url

    click_on I18n.t(:'projects.index.create_project_button')

    assert_selector 'h1', text: I18n.t(:'projects.new.title')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
      assert_equal 'new-project', find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).value
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
      click_on I18n.t(:'projects.new.submit')
    end

    assert_selector 'h1', text: project_name
    assert_text project_description
  end

  test 'can update project name and description' do
    project_name = 'New Project'
    project_description = 'New Project Description'

    visit project_edit_path(projects(:project1))
    assert_text I18n.t(:'projects.edit.general.title')

    fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
    fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
    assert_equal 'updated-project',
                   find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).valueclick_on I18n.t(:'projects.edit.general.submit')
    assert_selector 'h1', text: project_name
    assert_text project_description
  end

  test 'can update a project path' do
    full_path = namespaces_user_namespaces(:john_doe_namespace).full_path

    visit project_edit_path(projects(:project1))
    assert_text I18n.t(:'projects.edit.general.title')

    select full_path,
           from: I18n.t(:'projects.edit.advanced.transfer.new_namespace_id')
    click_on I18n.t(:'projects.edit.advanced.transfer.submit')
    assert_selector 'h1', text: projects(:project1).name
    click_on I18n.t(:'projects.sidebar.settings')

    assert_selector 'select#new_namespace_id' do |input|
      assert_equal full_path, input.find('option[selected]').text
    end
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
end
