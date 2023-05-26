# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    def setup
      @user = users(:john_doe)
      login_as @user
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'visiting the index' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_text @sample1.name
      assert_text @sample2.name

      assert_selector 'button.Viral-Dropdown--icon', count: 5
    end

    test 'cannot access project samples' do
      login_as users(:david_doe)

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
    end

    test 'should create sample' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      click_on I18n.t('projects.samples.index.new_button')

      fill_in I18n.t('activerecord.attributes.sample.description'), with: @sample1.description
      fill_in I18n.t('activerecord.attributes.sample.name'), with: 'New Name'
      click_on I18n.t('projects.samples.new.submit_button')

      assert_text I18n.t('projects.samples.create.success')
      click_on I18n.t('projects.samples.show.back_button')
    end

    test 'should update Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 1
      click_on I18n.t('projects.samples.show.edit_button'), match: :first

      fill_in 'Description', with: @sample1.description
      fill_in 'Name', with: 'New Sample Name'
      click_on I18n.t('projects.samples.edit.submit_button')

      assert_text I18n.t('projects.samples.update.success')
      click_on I18n.t('projects.samples.show.back_button')
    end

    test 'should destroy Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)
      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 1
      accept_confirm do
        click_link I18n.t('projects.samples.index.remove_button'), match: :first
      end

      assert_text I18n.t('projects.samples.destroy.success', sample_name: @sample1.name)
    end

    test 'user should not be able to see the edit button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)

      assert_selector 'a', text: I18n.t('projects.samples.show.edit_button'), count: 0
    end

    test 'user should not be able to see the remove button for the sample' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample1.id)

      assert_selector 'a', text: I18n.t('projects.samples.index.remove_button'), count: 0
    end

    test 'visiting the index should not allow the current user only edit action' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 1
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 2
      first('table#samples-table tr button.Viral-Dropdown--icon').click
      assert_selector 'a', text: 'Edit', count: 1
      assert_selector 'a', text: 'Remove', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end

    test 'visiting the index should not allow the current user any modification actions' do
      user = users(:ryan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_selector 'a', text: I18n.t('projects.samples.index.new_button'), count: 0
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
      assert_selector 'table#samples-table tr', count: 2
      assert_selector 'table#samples-table tr button.Viral-Dropdown--icon', text: '', count: 0
      assert_text @sample1.name
      assert_text @sample2.name
    end
  end
end
