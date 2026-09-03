# frozen_string_literal: true

require 'test_helper'

module Projects
  class HistoryTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      sign_in @user
      @namespace = groups(:group_one)
      @project = projects(:project1)

      @project.namespace.create_logidze_snapshot!
    end

    test 'can see the list of project change versions' do
      get namespace_project_history_path(@namespace, @project)
      assert_response :success

      assert_select 'h1', text: I18n.t(:'projects.history.index.title')

      get namespace_project_history_path(@namespace, @project, format: :turbo_stream)
      assert_response :success

      assert_select 'ol' do
        assert_select 'li' do
          assert_select 'span', text: I18n.t(:'components.history.link_text', version: 1)
          assert_select 'p', text: I18n.t(:'components.history.created_by', type: 'Project', user: 'System')
        end
      end
    end

    test 'can see modal with changes to project from previous version' do
      get namespace_project_view_history_path(@namespace, @project, version: 1, format: :turbo_stream)

      assert_response :success
      assert_select 'h1', text: I18n.t(:'components.history.link_text', version: 1)
      assert_select 'p', text: I18n.t(:'projects.history.project_history_modal_description.project_created',
                                      type: 'Project', user: 'System')

      assert_select 'span[data-test-item-selector="key"]', text: 'name'
      assert_select 'span[data-test-item-selector="key"]', text: 'path'
      assert_select 'span[data-test-item-selector="key"]', text: 'type'
      assert_select 'span[data-test-item-selector="key"]', text: 'owner_id'
      assert_select 'span[data-test-item-selector="key"]', text: 'parent_id'
      assert_select 'span[data-test-item-selector="key"]', text: 'description'
      assert_select 'span[data-test-item-selector="key"]', text: 'puid'

      assert_select 'span[data-test-item-selector="value"]', text: 'Project 1'
      assert_select 'span[data-test-item-selector="value"]', text: 'project-1'
      assert_select 'span[data-test-item-selector="value"]', text: 'Project'
      assert_select 'span[data-test-item-selector="value"]', text: @project.namespace.owner.id
      assert_select 'span[data-test-item-selector="value"]', text: @project.namespace.parent.id
      assert_select 'span[data-test-item-selector="value"]', text: 'Project 1 description'
      assert_select 'span[data-test-item-selector="value"]', text: @project.puid
    end

    test 'context_crumbs with non-index-new action skips breadcrumb' do
      get namespace_project_history_path(@namespace, @project)
      # Test the else branch on line 27 (implicit else of case statement)
      # When action_name is neither 'index' nor 'new', no extra breadcrumb is added
      controller = Projects::HistoryController.new
      controller.instance_variable_set(:@project, @project)
      controller.stubs(:route_to_context_crumbs).returns([{ name: 'Project', path: '/project' }])
      controller.stubs(:action_name).returns('show')

      controller.send(:context_crumbs)

      context_crumbs = controller.instance_variable_get(:@context_crumbs)
      # Verify the breadcrumb from route_to_context_crumbs is there, but no extra one was added
      assert_equal 1, context_crumbs.length
      assert_equal 'Project', context_crumbs[0][:name]
      # Ensure the history index breadcrumb was NOT added (else branch coverage)
      assert_nil(context_crumbs.find { |c| c[:name] == I18n.t('projects.history.index.title') })

      assert_response :success
    end
  end
end
