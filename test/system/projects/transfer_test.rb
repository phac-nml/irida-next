# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class TransferTest < ApplicationSystemTestCase
    setup do
      @unauthorized_namespace = namespaces_user_namespaces(:jane_doe_namespace)
      @user = users(:john_doe)
      @project = projects(:project1)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)

      login_as @user
    end

    test 'should transfer project' do
      visit project_edit_path(@project)
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']:disabled", count: 1
      find('input#select2-input').click
      find("button[data-viral--select2-primary-param='#{@namespace.full_path}']").click
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']", count: 1
      click_on I18n.t(:'projects.edit.advanced.transfer.submit')

      within('#turbo-confirm') do
        assert_text I18n.t(:'components.confirmation.title')
        fill_in I18n.t('components.confirmation.confirm_label'), with: @project.name
        click_on I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.transfer.success', project_name: @project.name)
    end

    test 'empty state of transfer group' do
      visit project_edit_path(@project)
      find('input#select2-input').fill_in with: 'invalid project name or puid'
      assert_text I18n.t(:'projects.edit.advanced.transfer.empty_state')
    end

    test 'should display error message when user attempts to transfer to namespace with same project name' do
      project2 = projects(:project2)

      visit project_edit_path(project2)
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']:disabled", count: 1
      find('input#select2-input').click
      find("button[data-viral--select2-primary-param='#{@namespace.full_path}']").click
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']", count: 1
      click_on I18n.t(:'projects.edit.advanced.transfer.submit')

      within('#turbo-confirm') do
        assert_text I18n.t(:'components.confirmation.title')
        fill_in I18n.t('components.confirmation.confirm_label'), with: project2.name
        click_on I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'services.projects.transfer.namespace_project_exists', project_name: project2.name)
    end
  end
end
