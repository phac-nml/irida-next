# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class ProjectsTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @project = projects(:project1)
    end

    test 'can see the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20
      assert_text @project.human_name
      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_text 'Displaying items 21-38 of 38 in total'
      assert_selector 'tr', count: 18
      click_on I18n.t(:'components.pagination.previous')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20

      click_link @project.human_name
      assert_current_path(namespace_project_samples_path(@project.parent, @project))
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title')
    end

    test 'can see the list of projects in user\'s groups and namespace group links' do
      login_as users(:david_doe)
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 22 in total'
      assert_selector 'tr', count: 20
      assert_text @project.human_name
      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_text 'Displaying items 21-22 of 22 in total'
      assert_selector 'tr', count: 2
      click_on I18n.t(:'components.pagination.previous')
      assert_text 'Displaying items 1-20 of 22 in total'
      assert_selector 'tr', count: 20

      click_link @project.human_name
      assert_current_path(namespace_project_samples_path(@project.parent, @project))
      assert_selector 'h1', text: I18n.t(:'projects.samples.index.title')
    end

    test 'can filter the list of projects to only see personal ones' do
      visit dashboard_projects_url

      click_on I18n.t(:'dashboard.projects.index.personal')

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying 4 items'
      assert_selector 'tr', count: 4
      assert_text projects(:john_doe_project2).human_name
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')
    end

    test 'can search the list of projects by name' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name

      assert_selector 'tr', count: 12
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')
    end

    test 'can sort the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20
      within first('tr') do
        assert_text @project.human_name
      end

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_selector 'tr', count: 20
      within first('tr') do
        assert_text projects(:projectHotel).human_name
      end
    end

    test 'can filter and then sort the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20
      within first('tr') do
        assert_text @project.human_name
      end
      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name

      assert_text 'Displaying 12 items'
      assert_selector 'tr', count: 12
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_selector 'tr', count: 12
      within first('tr') do
        assert_text projects(:project19).human_name
      end
    end

    test 'can sort and then filter the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20
      within first('tr') do
        assert_text @project.human_name
      end

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_text 'Displaying items 1-20 of 38 in total'
      assert_selector 'tr', count: 20
      within first('tr') do
        assert_text projects(:projectHotel).human_name
      end

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name

      assert_text 'Displaying 12 items'
      assert_selector 'tr', count: 12
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      within first('tr') do
        assert_text projects(:project19).human_name
      end
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
    end

    test 'can create a project from index page' do
      project_name = 'New Project'
      project_description = 'New Project Description'

      visit dashboard_projects_url

      click_on I18n.t(:'dashboard.projects.index.create_project_button')

      assert_selector 'h1', text: I18n.t(:'projects.new.title')

      within %(div[data-controller="slugify"][data-controller-connected="true"]) do
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.name'), with: project_name
        assert_equal 'new-project',
                     find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).value
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
        click_on I18n.t(:'projects.new.submit')
      end

      assert_selector 'h1', text: project_name
      assert_text project_description
    end

    test 'can see projects that the user has been added to as a member' do
      login_as users(:jean_doe)

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_text 'Displaying 1 item'
      assert_selector 'tr', count: 1
      assert_text projects(:john_doe_project2).human_name
    end
  end
end
