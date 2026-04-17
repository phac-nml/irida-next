# frozen_string_literal: true

require 'view_component_test_case'

module DataExports
  module LinelistExportDialog
    module V2
      class ComponentTest < ViewComponentTestCase
        test 'renders graphql worker data attributes' do
          project = projects(:project1)

          render_inline(
            Component.new(
              open: true,
              namespace_id: project.namespace.id,
              namespace: project.namespace,
              templates: []
            )
          )

          graphql_path = Rails.application.routes.url_helpers.api_graphql_path
          data_exports_path = Rails.application.routes.url_helpers.data_exports_path

          assert_selector "[data-controller*='linelist-export']"
          assert_selector "[data-linelist-export-graphql-url-value='#{graphql_path}']"
          assert_selector "[data-linelist-export-save-to-server-url-value='#{data_exports_path}']"
          assert_selector "[data-linelist-export-sample-graphql-id-prefix-value='gid://#{GlobalID.app}/Sample/']"
          assert_selector "[data-linelist-export-save-result-visible-duration-ms-value='6000']"
          assert_selector 'input#linelist-format-xlsx:not([disabled])'
          assert_selector "input#linelist-delivery-download[type='radio'][checked]"
          assert_no_selector "input#linelist-delivery-save[type='radio'][checked]"
          assert_selector "fieldset[data-linelist-export-target='saveDetailsFieldset'][disabled]"
          assert_selector "input[name='data_export[name]']"
          assert_selector "input[name='data_export[email_notification]']"
          assert_selector 'ul#available-list'
          assert_selector 'ul#selected-list'
        end
      end
    end
  end
end
