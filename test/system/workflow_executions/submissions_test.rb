# frozen_string_literal: true

require 'application_system_test_case'

class SubmissionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @project = projects(:project1)
    @namespace = groups(:group_one)
  end

  test 'should display a pipeline selection modal' do
    visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

    find("input[type='checkbox'][value='#{@sample1.id}']").click
    find("input[type='checkbox'][value='#{@sample2.id}']").click

    click_on I18n.t(:'projects.samples.index.workflows.button_sr')
    assert_selector 'dialog' do
      assert_selector '.dialog--header', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_selector 'button', text: 'phac-nml/iridanextexample', count: 3
      first('button', text: 'phac-nml/iridanextexample').click
    end

    assert_selector 'dialog.dialog--size-xl' do
      assert_selector 'div.sample-sheet' do
        assert_selector 'table' do
          assert_selector 'tr[data-controller="nextflow--samplesheet"]', count: 2
          assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample1.puid, count: 1
          assert_selector 'tr[data-controller="nextflow--samplesheet"]', text: @sample2.puid, count: 1
        end
      end
    end
  end
end
