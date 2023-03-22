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
      assert_selector 'h1', text: 'Samples'
    end

    test 'should create sample' do
      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)
      click_on 'New sample'

      fill_in 'Description', with: @sample.description
      fill_in 'Name', with: 'New Name'
      click_on 'Create sample'

      assert_text 'Sample was successfully created'
      click_on 'Back'
    end

    test 'should update Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      click_on 'Edit this sample', match: :first

      fill_in 'Description', with: @sample.description
      fill_in 'Name', with: 'New Sample Name'
      click_on 'Update sample'

      assert_text 'Sample was successfully updated'
      click_on 'Back'
    end

    test 'should destroy Sample' do
      visit namespace_project_sample_url(namespace_id: @namespace.path, project_id: @project.path, id: @sample.id)
      accept_confirm do
        click_link 'Remove', match: :first
      end

      assert_text 'Sample Sample 1 was removed'
    end
  end
end
