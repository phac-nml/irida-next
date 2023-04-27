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
    assert_selector 'tr', count: 1
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
      assert_selector %(input[data-slugify-target="path"]) do |input|
        assert_equal 'new-project', input['value']
      end
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
      click_on I18n.t(:'projects.new.submit')
    end

    assert_selector 'h1', text: project_name
    assert_text project_description
  end

  test 'can update a project' do
    project_name = 'Updated Project'

    visit project_edit_path(projects(:project1))
    assert_text I18n.t(:'projects.edit.general.title')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
      assert_selector %(input[data-slugify-target="path"]) do |input|
        assert_equal 'updated-project', input['value']
      end
      click_on I18n.t(:'projects.edit.general.submit')
    end
    assert_selector 'h1', text: project_name
  end
end
