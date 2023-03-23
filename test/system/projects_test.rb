# frozen_string_literal: true

require 'application_system_test_case'

class ProjectsTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'can see the list of projects' do
    visit projects_url

    assert_selector 'h1', text: I18n.t(:'projects.index.title')
    assert_selector 'tr', count: projects.count
    assert_text projects(:project1).name
  end

  test 'can create a project from index page' do
    project_name = 'New Project'
    project_description = 'New Project Description'

    visit projects_url

    click_on I18n.t(:'projects.index.create_project_button')

    assert_selector 'h1', text: I18n.t(:'projects.new.title')

    within %(div[data-controller="groups-new"][data-controller-connected="true"]) do
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
      fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
      click_on I18n.t(:'projects.new.submit')
    end

    assert_selector 'h1', text: project_name
    assert_text project_description
  end
end
