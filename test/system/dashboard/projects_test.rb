# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class ProjectsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup
      @user = users(:john_doe)
      login_as @user
      @project = projects(:project1)
      @project2 = projects(:project2)
      @group1 = groups(:group_one)
      @sample1 = samples(:sample1)
    end

    test 'can see the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20
      assert_text @project.human_name
      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
      click_on I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_selector '.treegrid-row'
      click_on I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_selector '.treegrid-row', count: 20

      click_link @project.human_name
      assert_current_path(namespace_project_path(@project.parent, @project))
      assert_selector 'h1', text: @project.name
    end

    test 'can see the list of projects in user\'s groups and namespace group links' do
      login_as users(:david_doe)
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20
      assert_text @project.human_name
      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_selector '.treegrid-row'
      click_on I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_selector '.treegrid-row', count: 20

      click_link @project.human_name
      assert_current_path(namespace_project_path(@project.parent, @project))
      assert_selector 'h1', text: @project.name
    end

    test 'can filter the list of projects to only see personal ones' do
      visit dashboard_projects_url

      click_on I18n.t(:'dashboard.projects.index.personal')

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 4
      assert_text projects(:john_doe_project2).human_name
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
    end

    test 'can search the list of projects by name' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name
      click_button I18n.t('common.controls.search')

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 12, count: 12,
                                                                                      locale: @user.locale))
      assert_selector '.treegrid-row', count: 12
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')

      assert_selector %(input.t-search-component) do |input|
        assert_equal @project.name, input['value']
      end
    end

    test 'can search the list of projects by puid' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.puid
      click_button I18n.t('common.controls.search')

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      assert_selector '.treegrid-row', count: 1
      assert_text @project.puid
    end

    test 'can sort the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20

      # Check first item
      within('#groups_tree .treegrid-row:first-child') do
        assert_text @project.human_name
      end

      click_button I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_link I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_selector '.treegrid-row', count: 20
      within('#groups_tree .treegrid-row:first-child') do
        assert_text projects(:projectHotel).human_name
      end
    end

    test 'can filter and then sort the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20

      within('#groups_tree .treegrid-row:first-child') do
        assert_text @project.human_name
      end

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name
      find('input.t-search-component').send_keys(:return)
      assert_selector '.treegrid-row', count: 12
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_selector '.treegrid-row', count: 12
      within('#groups_tree .treegrid-row:first-child') do
        assert_text projects(:project19).human_name
      end
    end

    test 'can sort and then filter the list of projects' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_selector '.treegrid-row', count: 20

      within('#groups_tree .treegrid-row:first-child') do
        assert_text @project.human_name
      end

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')
      assert_no_text I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      assert_text I18n.t(:'dashboard.projects.index.sorting.namespace_name_desc')

      assert_selector '.treegrid-row', count: 20

      within('#groups_tree .treegrid-row:first-child') do
        assert_text projects(:projectHotel).human_name
      end

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.name
      find('input.t-search-component').send_keys(:return)

      assert_selector '.treegrid-row', count: 12
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')
      assert_no_selector 'a',
                         exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')

      within('#groups_tree .treegrid-row:first-child') do
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
        fill_in I18n.t('projects.new.select_namespace'), with: 'USR'
        find('ul li', text: 'INXT_USR_AAAAAAAAAA').click
        assert_equal 'new-project',
                     find_field(I18n.t(:'activerecord.attributes.namespaces/project_namespace.path')).value
        fill_in I18n.t(:'activerecord.attributes.namespaces/project_namespace.description'), with: project_description
        click_on I18n.t(:'projects.new.submit')
      end

      new_project = @user.namespace.project_namespaces.find_by(name: project_name).project
      assert_current_path(namespace_project_path(new_project.parent, new_project))
      assert_selector 'h1', text: new_project.name
    end

    test 'should have Project URL filled with user namespace, when creating a new project from the dashboard' do
      visit dashboard_projects_url

      click_on I18n.t(:'dashboard.projects.index.create_project_button')

      within %(div[data-controller="slugify"][data-controller-connected="true"]) do
        assert_selector %(input[data-viral--select2-target="input"]) do |input|
          assert_equal @user.namespace.full_path, input['value']
        end
      end
    end

    test 'can see projects that the user has been added to as a member' do
      login_as users(:jean_doe)

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      assert_selector '.treegrid-row', count: 1
      assert_text projects(:john_doe_project2).human_name
    end

    test 'should update samples count after a sample deletion' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      assert_equal 3, @project.samples.size

      # Look for the samples count display in the row contents
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      visit namespace_project_sample_url(@group1, @project, @sample1)
      click_button I18n.t('common.actions.remove')

      within('dialog[open]') do
        click_button I18n.t('common.actions.remove')
      end

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      click_on I18n.t(:'dashboard.projects.index.sorting.updated_at_desc')
      click_on I18n.t(:'dashboard.projects.index.sorting.namespace_name_asc'), match: :first

      assert_text @project.namespace.name
      assert_equal 2, @project.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end
    end

    test 'should update samples count after a sample creation' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      assert_equal 3, @project.samples.size

      # Look for the samples count display in the row contents
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      visit namespace_project_samples_url(@group1, @project)

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.new_sample')

      find('input#sample_name').fill_in with: 'Test Sample'
      click_button I18n.t('helpers.submit.sample.create', model: Sample.model_name.human,
                                                          default: :'helpers.submit.create')

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.namespace.name
      find('input.t-search-component').send_keys(:return)

      assert_text @project.namespace.name
      assert_equal 4, @project.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end
    end

    test 'should update samples count after a sample transfer' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      assert_equal 3, @project.samples.size

      # Look for the samples count display in the row contents
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      visit namespace_project_samples_url(@group1, @project)

      find("input[type='checkbox'][id='#{dom_id(@sample1, :checkbox)}']").click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      within('div[data-controller-connected="true"] dialog') do
        assert_text I18n.t('samples.transfers.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text @sample1.name
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::TransferJob]
        assert_performed_jobs 1
      end

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.namespace.name
      find('input.t-search-component').send_keys(:return)

      assert_text @project.namespace.name
      assert_no_text @project2.namespace.name
      assert_equal 2, @project.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project2.namespace.name
      find('input.t-search-component').send_keys(:return)

      assert_text @project2.namespace.name
      assert_no_text @project.namespace.name
      assert_equal 21, @project2.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project2)}") do
        assert_text @project2.samples.size.to_s
      end
    end

    test 'should update samples count after a sample clone' do
      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      assert_equal 3, @project.samples.size

      # Look for the samples count display in the row contents
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      visit namespace_project_samples_url(@group1, @project)

      find("input[type='checkbox'][id='#{dom_id(@sample1, :checkbox)}']").click
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      within('#dialog') do
        assert_text I18n.t('samples.clones.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text @sample1.name
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click

        click_on I18n.t('samples.clones.dialog.submit_button')
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::CloneJob]
        assert_performed_jobs 1
      end
      assert_text I18n.t('samples.clones.create.success')

      visit dashboard_projects_url

      assert_selector 'h1', text: I18n.t(:'dashboard.projects.index.title')

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project.namespace.name
      find('input.t-search-component').send_keys(:return)

      assert_text @project.namespace.name
      assert_no_text @project2.namespace.name
      assert_equal 3, @project.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project)}") do
        assert_text @project.samples.size.to_s
      end

      fill_in I18n.t(:'dashboard.projects.index.search.placeholder'), with: @project2.namespace.name
      find('input.t-search-component').send_keys(:return)

      assert_text @project2.namespace.name
      assert_no_text @project.namespace.name
      assert_equal 21, @project2.reload.samples.size

      # Look for the updated samples count
      within("##{dom_id(@project2)}") do
        assert_text @project2.samples.size.to_s
      end
    end

    test 'can skip to content' do
      visit dashboard_projects_url

      assert_css '#main-content-link', visible: false
      find('body').send_keys(:tab)
      assert_css '#main-content-link', visible: true
      find('#main-content-link').trigger('click')
      assert_css '#main-content', focused: true
    end
  end
end
