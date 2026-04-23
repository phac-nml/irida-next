# frozen_string_literal: true

require 'view_component_test_case'

module DataImports
  module LinelistImportDialog
    module V2
      class ComponentTest < ViewComponentTestCase
        test 'default' do
          broadcast_target = "metadata_import_#{SecureRandom.uuid}"

          render_inline(
            Component.new(
              broadcast_target: broadcast_target,
              open: true
            )
          )

          assert_selector 'h1', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
          assert_selector "form[action='#'][method='get']" do
            assert_selector "input[type='hidden'][name='broadcast_target'][value='#{broadcast_target}']", visible: false
            assert_selector "input[type='file'][name='file_import[file]']"
            assert_selector "select[name='file_import[sample_id_column]']"
            assert_selector "input[type='checkbox'][name='file_import[ignore_empty_values]']"
            assert_selector "input[type='submit'][disabled][value='#{I18n.t('shared.samples.metadata.file_imports.form_fields.submit_button')}']" # rubocop:disable Layout/LineLength
          end
        end
      end
    end
  end
end
