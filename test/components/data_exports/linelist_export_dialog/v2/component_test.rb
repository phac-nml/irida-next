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

          assert_selector "[data-controller='linelist-export']"
          assert_selector "[data-linelist-export-graphql-url-value='#{graphql_path}']"
          assert_selector "[data-linelist-export-sample-graphql-id-prefix-value='gid://#{GlobalID.app}/Sample/']"
        end

        test 'renders metadata sortable lists' do
          project = projects(:project1)

          render_inline(
            Component.new(
              open: true,
              namespace_id: project.namespace.id,
              namespace: project.namespace,
              templates: []
            )
          )

          assert_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
          assert_selector 'ul#available-list li', text: 'metadatafield1'
          assert_selector 'ul#available-list li', text: 'metadatafield2'
          assert_selector 'ul#selected-list'
          assert_no_selector "input[type='checkbox'][name='data_export[export_parameters][metadata_fields][]']"
        end

        test 'renders enabled xlsx format option' do
          project = projects(:project1)

          render_inline(
            Component.new(
              open: true,
              namespace_id: project.namespace.id,
              namespace: project.namespace,
              templates: []
            )
          )

          assert_selector "input#linelist-format-xlsx[type='radio'][value='xlsx']"
          assert_no_selector 'input#linelist-format-xlsx[disabled]'
        end
      end
    end
  end
end
