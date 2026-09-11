# frozen_string_literal: true

require 'test_helper'

module Projects
  class MetadataTemplatesTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)
      @project = projects(:project1)
      @project_namespace = @project.namespace
      @project_metadata_template = metadata_templates(:valid_metadata_template)
      @sorted_project = projects(:john_doe_project2)
      @project_metadata_template1 = metadata_templates(:project2_metadata_template1)
      @project_metadata_template2 = metadata_templates(:project2_metadata_template2)
    end

    test 'project metadata templates index' do
      get namespace_project_metadata_templates_path(@project_namespace.parent, @project)

      assert_response :success

      assert_select 'h1', text: I18n.t('projects.metadata_templates.index.title')
      assert_select 'p', text: I18n.t('projects.metadata_templates.index.subtitle')

      assert_select 'table thead tr th', count: 6
      assert_select 'table tbody tr', count: @project.namespace.metadata_templates.count

      @project.namespace.metadata_templates.each do |metadata_template|
        assert_select 'table tbody tr td:nth-child(1)', text: metadata_template.name
      end
    end

    test 'project metadata templates new' do
      get new_namespace_project_metadata_template_path(@project_namespace.parent, @project, format: :turbo_stream)

      assert_response :success

      assert_select 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_select 'dialog h2', text: I18n.t('metadata_templates.form.details_heading')
      assert_select 'dialog h2', text: I18n.t('metadata_templates.form.metadata')

      available_label_id = 'available-list-list-label'
      selected_label_id = 'selected-list-list-label'
      assert_select "ul[aria-labelledby='#{available_label_id}'] li", count: @project.namespace.metadata_fields.count
      assert_select "ul[aria-labelledby='#{selected_label_id}'] li", count: 0
      @project.namespace.metadata_fields.each do |field|
        assert_select "ul[aria-labelledby='#{available_label_id}'] li", text: field
      end
    end

    test 'project metadata templates new unauthorized' do
      sign_in users(:ryan_doe)
      get new_namespace_project_metadata_template_path(@project_namespace.parent, @project, format: :turbo_stream)

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.error')}: #{I18n.t(
                        'action_policy.policy.namespaces/project_namespace.create_metadata_templates?',
                        name: @project.name
                      )}"
      end
    end

    test 'project metadata templates edit' do
      get edit_namespace_project_metadata_template_path(@project_namespace.parent,
                                                        @project, @project_metadata_template,
                                                        format: :turbo_stream)

      assert_response :success

      assert_select 'dialog h1', text: I18n.t('metadata_templates.edit_template_dialog.title')
      assert_select "input[value='#{@project_metadata_template.name}']"
      assert_select 'textarea', text: @project_metadata_template.description

      available_label_id = 'available-list-list-label'
      selected_label_id = 'selected-list-list-label'
      assert_select "ul[aria-labelledby='#{available_label_id}'] li",
                    count: @project.namespace.metadata_fields.count - @project_metadata_template.fields.count
      assert_select "ul[aria-labelledby='#{selected_label_id}'] li", count: @project_metadata_template.fields.count

      unselected_fields = @project.namespace.metadata_fields.reject do |field|
        @project_metadata_template.fields.include? field
      end
      unselected_fields.each do |field|
        assert_select "ul[aria-labelledby='#{available_label_id}'] li", text: field
      end
    end

    test 'project metadata templates edit unauthorized' do
      sign_in users(:ryan_doe)
      get edit_namespace_project_metadata_template_path(@project_namespace.parent,
                                                        @project, @project_metadata_template,
                                                        format: :turbo_stream)

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.error')}: #{I18n.t('action_policy.unauthorized')}"
      end
    end

    test 'project metadata templates create' do
      new_name = 'Newest template'
      metadata_template_params = { metadata_template: { name: new_name, fields: %w[field1 field5] } }
      assert_difference('MetadataTemplate.count', 1) do
        post namespace_project_metadata_templates_path(
          @project_namespace.parent,
          @project, format: :turbo_stream
        ), params: metadata_template_params
      end
      assert_response :success

      assert_select "div[data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.metadata_template_actions.create.success', template_name: new_name
                      )}"
      end

      get namespace_project_metadata_templates_path(@project_namespace.parent, @project)
      assert_response :success
      assert_select 'table tbody tr td:nth-child(1)', text: new_name
    end

    test 'project metadata templates create error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      assert_no_difference('MetadataTemplate.count') do
        post namespace_project_metadata_templates_path(
          @project_namespace.parent,
          @project, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:name),
                   message: I18n.t(:'errors.messages.blank'))
      assert_select "div[class='form-field invalid']"

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
      assert_no_difference('MetadataTemplate.count') do
        post namespace_project_metadata_templates_path(
          @project_namespace.parent,
          @project, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:fields),
                   message: I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_length', min: 1))
    end

    test 'project metadata templates create unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
      assert_no_difference('MetadataTemplate.count') do
        post namespace_project_metadata_templates_path(
          @project_namespace.parent,
          @project, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.error')}: #{I18n.t(
                        'action_policy.policy.namespaces/project_namespace.create_metadata_templates?',
                        name: @project.name
                      )}"
      end
    end

    test 'project metadata templates update' do
      new_name = 'This is the new template'
      metadata_template_params = { metadata_template: { name: new_name, fields: %w[field6 field10] } }
      assert_changes lambda {
        @project_metadata_template.reload.name
      }, from: @project_metadata_template.name, to: new_name do
        put namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :success

      assert_select "div[data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.metadata_template_actions.update.success',
                        template_name: new_name
                      )}"
      end
      assert_select "tr#metadata_template_#{@project_metadata_template.id}" do
        assert_select 'td', text: new_name
        assert_select 'button', text: I18n.t('common.actions.edit'), focused: true
      end
    end

    test 'project metadata templates update error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      assert_no_changes(@project_metadata_template.reload) do
        put namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:name),
                   message: I18n.t(:'errors.messages.blank'))
      assert_select "div[class='form-field invalid']"

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
      assert_no_changes(@project_metadata_template.reload) do
        put namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:fields),
                   message: I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_length', min: 1))
    end

    test 'project metadata templates update unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
      assert_no_changes(@project_metadata_template.reload) do
        put namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div', "#{I18n.t('common.statuses.error')}: #{I18n.t('action_policy.unauthorized')}"
      end
    end

    test 'project metadata templates update renders translated error when service fails with no model errors' do
      MetadataTemplates::UpdateService.any_instance.stubs(:execute).returns(false)

      metadata_template_params = { metadata_template: { name: 'Valid Name', fields: %w[field1] } }
      assert_no_changes(@project_metadata_template.reload) do
        put namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.error')}: #{I18n.t('concerns.metadata_template_actions.update.error',
                                                                    template_name: @project_metadata_template.name)}"
      end
    end

    test 'project metadata templates destroy' do
      template_id = @project_metadata_template.id
      template_name = @project_metadata_template.name

      assert_difference('MetadataTemplate.count', -1) do
        delete namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template,
          format: :turbo_stream
        )
      end

      assert_response :success

      assert_select "div[data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.metadata_template_actions.destroy.success', template_name: template_name
                      )}"
      end

      get namespace_project_metadata_templates_path(@project_namespace.parent, @project)
      assert_response :success
      assert_select "tr#metadata_template_#{template_id}", count: 0
    end

    test 'project metadata templates destroy unauthorized' do
      sign_in users(:ryan_doe)
      assert_no_difference('MetadataTemplate.count') do
        delete namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project, @project_metadata_template,
          format: :turbo_stream
        )
      end

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div', "#{I18n.t('common.statuses.error')}: #{I18n.t('action_policy.unauthorized')}"
      end
    end

    test 'project metadata templates destroy renders error from error_message when not deleted' do
      MetadataTemplates::DestroyService.any_instance.stubs(:execute).returns(nil)
      Projects::MetadataTemplatesController.any_instance.stubs(:error_message)
                                           .returns('Destroy failed from error_message')

      assert_no_difference('MetadataTemplate.count') do
        delete namespace_project_metadata_template_path(
          @project_namespace.parent,
          @project,
          @project_metadata_template,
          format: :turbo_stream
        )
      end

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']", text: /Destroy failed from error_message/
    end

    test 'project metadata templates list with none template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: 'none'
      )

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.none')
    end

    test 'project metadata templates list with all template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: 'all'
      )

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.all')
    end

    test 'project metadata templates list with specific template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: @project_metadata_template.id
      )

      assert_response :success
      assert_includes @response.body, @project_metadata_template.name
    end

    test 'project metadata templates index with pagination and sorting' do
      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@project_metadata_template1.name, @project_metadata_template2.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'name desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@project_metadata_template2.name, @project_metadata_template1.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'created_by_email asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(@project_metadata_template2.name, @project_metadata_template1.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'created_by_email desc' } })
      assert_response :success
      assert_sort_state(3, 'descending')
      assert_first_rows_include(@project_metadata_template1.name, @project_metadata_template2.name)
    end

    test 'accessing metadata templates index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_metadata_templates_path(@project_namespace.parent, @project_namespace.project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end

    test 'projects metadata templates controller metadata_templates_path delegates to project route helper' do
      controller = Projects::MetadataTemplatesController.new
      controller.stubs(:namespace_project_metadata_templates_path).returns('/projects/project-one/metadata_templates')

      assert_equal '/projects/project-one/metadata_templates', controller.send(:metadata_templates_path)
    end
  end
end
