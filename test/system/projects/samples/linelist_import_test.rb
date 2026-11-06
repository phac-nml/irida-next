# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class LinelistImportTest < ApplicationSystemTestCase
      test 'client import broadcasts a refresh with the updated metadata summary' do
        user = users(:john_doe)
        project = projects(:project1)
        sample = samples(:sample1)
        Flipper.enable(:client_linelist_imports_v1)
        login_as user

        visit namespace_project_samples_url(groups(:group_one), project)
        assert_selector "tr[id='#{dom_id(sample)}']"
        click_button I18n.t('shared.samples.metadata_templates.label')
        click_button I18n.t('shared.samples.metadata_templates.fields.all')
        assert_selector 'table thead th', text: 'METADATAFIELD1'
        assert_no_selector 'table thead th', text: 'METADATAFIELD3'
        assert_no_selector '[data-refresh-target="notice"]'

        click_button I18n.t('shared.samples.actions_dropdown.label')
        click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
        assert_selector '[data-controller~="linelist-import"]'
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_blank_rows.csv')
        assert_selector "ul[aria-labelledby='selected-list-list-label'] li", count: 3

        perform_enqueued_jobs only: Turbo::Streams::BroadcastStreamJob do
          click_button I18n.t('shared.samples.metadata.file_imports.form_fields.submit_button')
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          assert_selector '[data-refresh-target="notice"]'
        end

        assert_equal 2, project.namespace.reload.metadata_summary['metadatafield3']
        within '[data-refresh-target="notice"]' do
          click_button I18n.t('components.refresh_notice.default_link_text')
        end
        assert_selector 'table thead th', text: 'METADATAFIELD3'
        assert_selector "tr[id='#{dom_id(sample)}'] td", text: '30', exact_text: true
      ensure
        Flipper.disable(:client_linelist_imports_v1)
      end
    end
  end
end
