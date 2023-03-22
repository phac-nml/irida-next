# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesTest < ApplicationSystemTestCase
    setup do
      login_as users(:john_doe)
      @sample = samples(:one)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'visiting the index' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      assert_selector 'h1', text: I18n.t('projects.samples.index.title')
    end

    test 'should create sample' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      click_on I18n.t('projects.samples.index.new_button')

      fill_in 'Description', with: @sample.description
      fill_in 'Name', with: 'New Name'
      click_on I18n.t('projects.samples.new.submit_button')

      assert_text I18n.t('projects.samples.create.success')
      click_on 'Back'
    end

    test 'should update Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      click_on I18n.t('projects.samples.show.edit_button'), match: :first

      fill_in 'Description', with: @sample.description
      fill_in 'Name', with: 'New Sample Name'
      click_on 'Update sample'

      assert_text I18n.t('projects.samples.update.success')
      click_on I18n.t('projects.samples.show.back_button')
    end

    test 'should destroy Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      accept_confirm do
        click_link I18n.t('projects.samples.index.remove_button'), match: :first
      end

      assert_text I18n.t('projects.samples.destroy.success', sample_name: @sample.name)
    end
  end
end
