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
    new_project = Project.last
    assert_current_path(namespace_project_samples_path(new_project.parent, new_project))
    assert_selector 'h1', text: I18n.t(:'projects.samples.index.title')
  end

  test 'show error when creating a project with a short name' do
    project_name = 'a'
    project_path = 'new-project'
    visit new_project_path

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: project_name
      fill_in 'Path', with: project_path
      click_on I18n.t(:'projects.new.submit')
    end

    assert_text 'Name is too short'
    assert_current_path new_project_path
  end

  test 'show error when creating a project with a same name' do
    project2 = projects(:project2)
    visit new_project_path

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: project2.name
      click_on I18n.t(:'projects.new.submit')
    end

    assert_text 'Project Name has already been taken'
    assert_current_path new_project_path
  end

  test 'show error when creating a project with a long description' do
    project_name = 'New Project'
    project_description = 'a' * 256
    visit new_project_path

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: project_name
      fill_in 'Description', with: project_description
      click_on I18n.t(:'projects.new.submit')
    end

    assert_text 'Description is too long'
    assert_current_path new_project_path
  end

  test 'show error when creating a project with an invalid path' do
    project_name = 'New Project'
    project_path = 'a'
    visit new_project_path

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in 'Name', with: project_name
      fill_in 'Path', with: project_path
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
    assert_text I18n.t('projects.update.success', project_name:)

    assert_field I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
    assert_field I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description

    within '#sidebar_project_name' do
      assert_text project_name
    end

    within '#breadcrumb' do
      assert_text project_name
    end
  end

  test 'can view project' do
    visit namespace_project_url(groups(:group_one), projects(:project1))

    assert_selector 'h1', text: 'Project 1'
  end

  test 'can not view project' do
    login_as users(:user_no_access)

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

    assert_text I18n.t('projects.edit.advanced.destroy.confirm')
    assert_button I18n.t('components.confirmation.confirm')
    click_button I18n.t('components.confirmation.confirm')

    assert_text I18n.t(:'projects.destroy.success', project_name: project.name)
  end

  test 'can edit a project path' do
    project = projects(:project1)
    visit project_edit_path(project)

    fill_in 'Path', with: 'project-1-edited'
    click_on I18n.t(:'projects.edit.advanced.path.submit')

    within '#sidebar' do
      assert_text project.name
    end

    within '#breadcrumb' do
      assert_text project.name
    end

    assert_text I18n.t('projects.update.success', project_name: project.name)
    assert_current_path '/group-1/project-1-edited/-/edit'
  end

  test 'show error when editing a project path to an existing namespace' do
    project = projects(:project1)
    visit project_edit_path(project)

    fill_in 'Path', with: 'project-2'
    click_on I18n.t(:'projects.edit.advanced.path.submit')

    within '#sidebar' do
      assert_text project.name
    end

    within '#breadcrumb' do
      assert_text project.name
    end

    assert_text I18n.t('activerecord.errors.models.namespace.attributes.name.taken').downcase
    assert_current_path '/group-1/project-1/-/edit'
  end

  test 'show error when editing a project with a short name' do
    project_name = 'a'
    project = projects(:project1)
    visit project_edit_path(project)

    fill_in 'Name', with: project_name
    click_on I18n.t('projects.edit.general.submit')

    within '#sidebar' do
      assert_text project.name
    end

    within '#breadcrumb' do
      assert_text project.name
    end

    assert_text 'Name is too short'
    assert_current_path '/group-1/project-1/-/edit'
  end

  test 'show error when editing a project with a same name' do
    project1 = projects(:project1)
    project2 = projects(:project2)
    visit project_edit_path(project1)

    fill_in 'Name', with: project2.name
    click_on I18n.t('projects.edit.general.submit')

    within '#sidebar' do
      assert_text project1.name
    end

    within '#breadcrumb' do
      assert_text project1.name
    end

    assert_text 'Project Name has already been taken'
    assert_current_path '/group-1/project-1/-/edit'
  end

  test 'show error when editing a project with a long description' do
    project_description = 'a' * 256
    project = projects(:project1)
    visit project_edit_path(project)

    fill_in 'Description', with: project_description
    click_on I18n.t('projects.edit.general.submit')

    within '#sidebar' do
      assert_text project.name
    end

    within '#breadcrumb' do
      assert_text project.name
    end

    assert_text 'Description is too long'
    assert_current_path '/group-1/project-1/-/edit'
  end
end
