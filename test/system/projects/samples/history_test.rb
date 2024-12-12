# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class HistoryTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
        @sample1 = samples(:sample1)
        @project = projects(:project1)
        @namespace = groups(:group_one)
      end

      test 'can see the list of sample change versions' do
        @sample1.create_logidze_snapshot!
        visit namespace_project_sample_path(@namespace, @project, @sample1, tab: 'history')

        within('#table-listing') do
          assert_selector 'ol', count: 1
          assert_selector 'li', count: 1

          assert_selector 'h2', text: I18n.t(:'components.history.link_text', version: 1)

          assert_selector 'p', text: I18n.t(:'components.history.created_by', type: 'Sample', user: 'System')
        end
      end

      test 'can see sample history version changes' do
        @sample1.create_logidze_snapshot!
        visit namespace_project_sample_path(@namespace, @project, @sample1, tab: 'history')
        click_on 'Version 1'

        within('#sample_modal') do
          assert_selector 'h1', text: I18n.t(:'components.history.link_text', version: 1)
          assert_selector 'p', text: I18n.t(:'projects.samples.show.history.modal.created_by',
                                            user: 'System')

          assert_no_text I18n.t(:'components.history_version.previous_version')
          assert_text I18n.t(:'components.history_version.current_version', version: 1)

          assert_selector 'dt', text: 'name'
          assert_selector 'dt', text: 'description'
          assert_selector 'dt', text: 'puid'
          assert_selector 'dt', text: 'project_id'

          assert_selector 'dd', text: 'Project 1 Sample 1'
          assert_selector 'dd', text: 'Sample 1 description.'
          assert_selector 'dd', text: @sample1.puid
          assert_selector 'dd', text: @sample1.project.id
        end
      end
    end
  end
end
