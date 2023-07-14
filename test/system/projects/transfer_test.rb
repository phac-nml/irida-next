# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class TransferTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      login_as @user
      @project = projects(:project1)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
    end

    test 'should transfer project' do
      visit project_edit_path(@project)
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']:disabled", count: 1
      find('#new_namespace_id').find("option[value='#{@namespace.id}']").select_option
      assert_selector "input[value='#{I18n.t(:'projects.edit.advanced.transfer.submit')}']", count: 1
      click_on I18n.t(:'projects.edit.advanced.transfer.submit')

      within('#turbo-confirm') do
        assert_text I18n.t(:'components.confirmation.title')
        find('input[type=text]').fill_in with: @project.name
        click_on I18n.t(:'components.confirmation.confirm')
      end

      assert_text I18n.t(:'projects.transfer.success', project_name: @project.name)
    end
  end
end
