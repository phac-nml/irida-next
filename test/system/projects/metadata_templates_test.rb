# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class MetadataTemplatesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup
      @user = users(:john_doe)
      login_as @user
    end

    test 'should display metadata templates associated with the project' do
      project = projects(:project1)
      metadata_template = metadata_templates(:project1_metadata_template0)
      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: I18n.t('projects.metadata_templates.index.title')
      assert_selector 'p', text: I18n.t('projects.metadata_templates.index.subtitle')

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')

      within('table tbody') do
        assert_selector 'tr', count: 2
      end

      assert_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/

      click_on I18n.t(:'components.pagination.previous')

      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      within('table tbody tr:first-child td:nth-child(1)') do
        assert_text metadata_template.name
      end
    end

    test 'should not display metadata templates listing table if no metadata templates associated with the project' do
      login_as users(:david_doe)
      project = projects(:project28)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: I18n.t('projects.metadata_templates.index.title')
      assert_selector 'p', text: I18n.t('projects.metadata_templates.index.subtitle')

      assert_no_selector 'table'

      assert_selector "div[class='empty_state_message']", count: 1

      assert_text I18n.t('metadata_templates.table.empty.title', namespace_type: project.namespace.type.downcase)
      assert_text I18n.t('metadata_templates.table.empty.description', namespace_type: project.namespace.type.downcase)
    end

    test 'should sort a list of metadata templates' do
      project = projects(:john_doe_project2)
      metadata_template1 = metadata_templates(:project2_metadata_template1)
      metadata_template2 = metadata_templates(:project2_metadata_template2)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 2))
      assert_selector 'table tbody tr', count: 2
      assert_selector 'table thead th:first-child svg.icon-arrow_up'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template1.name
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: metadata_template1.description
      end

      click_on I18n.t('metadata_templates.table_component.name')
      assert_selector 'table thead th:first-child svg.icon-arrow_down'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template2.name
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: metadata_template2.description
      end

      click_on I18n.t('metadata_templates.table_component.created_by_email')
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_up'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template2.name
        assert_selector 'tr:first-child td:nth-child(3)',
                        text: metadata_template2.created_by.email
      end

      click_on I18n.t('metadata_templates.table_component.created_by_email')
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template1.name
        assert_selector 'tr:first-child td:nth-child(3)',
                        text: metadata_template1.created_by.email
      end
    end

    test 'should destroy metadata template associated with the project' do
      project = projects(:project1)
      metadata_template = metadata_templates(:project1_metadata_template0)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      table_row = find(:table_row, [metadata_template.name])

      within table_row do
        assert_link I18n.t(:'metadata_templates.table_component.remove_button'), count: 1
        click_link I18n.t(:'metadata_templates.table_component.remove_button')
      end

      assert_text I18n.t(
        :'metadata_templates.table_component.remove_confirmation',
        template_name: metadata_template.name
      )

      click_button I18n.t(:'components.confirmation.confirm')

      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(
          :'concerns.metadata_template_actions.destroy.success',
          template_name: metadata_template.name
        )
      end
    end

    test 'maintainer or higher can access the metadata template page and create new template' do
      project = projects(:project1)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: 'Metadata Templates'
      assert_selector 'p', text: 'These are the metadata templates associated to the project'

      assert_selector 'a', text: 'New Template', count: 1

      click_on 'New Template'

      assert_selector '#dialog'

      within('span[data-controller-connected="true"] dialog') do
        assert_selector 'h1', text: 'New Metadata Template'
        assert_text "Select the metadata fields for new template by moving the metadata fields from the available list to the selected list. The template's fields ordering will be determined by the ordering of the selected list." # rubocop:disable Layout/LineLength

        within "ul[id='available']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        within "ul[id='selected']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end

        click_button I18n.t('viral.sortable_lists_component.add_all')
        find('input#metadata_template_name').fill_in with: 'Newest template'
        click_button I18n.t('metadata_templates.new_template_dialog.submit_button')
      end

      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(
          :'concerns.metadata_template_actions.create.success',
          template_name: 'Newest template'
        )
      end
    end

    test 'cannot create a template with no fields selected' do
      project = projects(:project1)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: 'Metadata Templates'
      assert_selector 'p', text: 'These are the metadata templates associated to the project'

      assert_selector 'a', text: 'New Template', count: 1

      click_on 'New Template'

      assert_selector '#dialog'

      within('span[data-controller-connected="true"] dialog') do
        assert_selector 'h1', text: 'New Metadata Template'
        assert_text "Select the metadata fields for new template by moving the metadata fields from the available list to the selected list. The template's fields ordering will be determined by the ordering of the selected list." # rubocop:disable Layout/LineLength

        within "ul[id='available']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        within "ul[id='selected']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end

        click_button I18n.t('viral.sortable_lists_component.add_all')

        click_button I18n.t('metadata_templates.new_template_dialog.submit_button')
      end

      assert_no_selector "div[data-controller='viral--flash']"
    end

    test 'cannot create a template with no template name entered' do
      project = projects(:project1)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: 'Metadata Templates'
      assert_selector 'p', text: 'These are the metadata templates associated to the project'

      assert_selector 'a', text: 'New Template', count: 1

      click_on 'New Template'

      assert_selector '#dialog'

      within('span[data-controller-connected="true"] dialog') do
        assert_accessible
        assert_selector 'h1', text: 'New Metadata Template'
        assert_text "Select the metadata fields for new template by moving the metadata fields from the available list to the selected list. The template's fields ordering will be determined by the ordering of the selected list." # rubocop:disable Layout/LineLength

        within "ul[id='available']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        within "ul[id='selected']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end

        find('input#metadata_template_name').fill_in with: 'Newest template'

        assert_selector "input[value='#{I18n.t('metadata_templates.new_template_dialog.submit_button')}']:disabled",
                        count: 1
      end

      assert_no_selector "div[data-controller='viral--flash']"
    end

    test 'move fields between available and selected lists' do
      project = projects(:project1)

      visit namespace_project_metadata_templates_url(project.namespace.parent, project)

      assert_selector 'h1', text: 'Metadata Templates'
      assert_selector 'p', text: 'These are the metadata templates associated to the project'

      assert_selector 'a', text: 'New Template', count: 1

      click_on 'New Template'

      assert_selector '#dialog'

      within('span[data-controller-connected="true"] dialog') do
        assert_selector 'h1', text: 'New Metadata Template'
        assert_text "Select the metadata fields for new template by moving the metadata fields from the available list to the selected list. The template's fields ordering will be determined by the ordering of the selected list." # rubocop:disable Layout/LineLength

        within "ul[id='available']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        within "ul[id='selected']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end

        click_button I18n.t('viral.sortable_lists_component.add_all')

        within "ul[id='available']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end

        within "ul[id='selected']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        click_button I18n.t('viral.sortable_lists_component.remove_all')

        within "ul[id='available']" do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_selector 'li', count: 2
        end

        within "ul[id='selected']" do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_selector 'li'
        end
      end
    end
  end
end
