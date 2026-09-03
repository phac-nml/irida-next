# frozen_string_literal: true

require 'test_helper'

module Groups
  class HistoryTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      sign_in @user
      @group = groups(:group_one)

      @group.create_logidze_snapshot!
    end

    test 'can see the list of group change versions' do
      get group_history_path(@group)
      assert_response :success

      assert_select 'h1', text: I18n.t(:'groups.history.index.title')

      get group_history_path(@group, format: :turbo_stream)
      assert_response :success

      assert_select 'ol' do
        assert_select 'li' do
          assert_select 'span', text: I18n.t(:'components.history.link_text', version: 1)
          assert_select 'p', text: I18n.t(:'components.history.created_by', type: 'Group', user: 'System')
        end
      end
    end

    test 'can see group history version changes' do
      get group_view_history_path(@group, version: 1, format: :turbo_stream)
      assert_response :success

      assert_select 'h1', text: I18n.t(:'components.history.link_text', version: 1)
      assert_select 'p',
                    text: I18n.t(:'groups.history.group_history_modal_description.group_created', type: 'Group',
                                                                                                  user: 'System')

      assert_select 'span[data-test-item-selector="key"]', text: 'name'
      assert_select 'span[data-test-item-selector="key"]', text: 'path'
      assert_select 'span[data-test-item-selector="key"]', text: 'type'
      assert_select 'span[data-test-item-selector="key"]', text: 'owner_id'
      assert_select 'span[data-test-item-selector="key"]', text: 'description'

      assert_select 'span[data-test-item-selector="value"]', text: 'Group 1'
      assert_select 'span[data-test-item-selector="value"]', text: 'group-1'
      assert_select 'span[data-test-item-selector="value"]', text: 'Group'
      assert_select 'span[data-test-item-selector="value"]', text: @group.owner.id
      assert_select 'span[data-test-item-selector="value"]', text: 'Group 1 description'
    end

    test 'handles invalid group path gracefully' do
      # Test the @group.nil? ? [] branch on line 26
      # When @group cannot be found (invalid path), the controller should return 404
      get '/groups/-/groups/invalid-path-that-does-not-exist/-/history'
      assert_response :not_found
    end

    test 'index action includes history breadcrumb' do
      # Test the when 'index' branch on line 28-32
      # Verifies the breadcrumb is added for the index action
      get group_history_path(@group)
      assert_response :success

      # Verify breadcrumb component is rendered
      assert_select 'nav[aria-label="Breadcrumb navigation"]'
    end

    test 'context_crumbs with nil group initializes empty crumbs' do
      # Test the @group.nil? ? [] branch
      # Directly test the context_crumbs method with nil @group
      controller = Groups::HistoryController.new
      controller.instance_variable_set(:@group, nil)
      controller.stubs(:route_to_context_crumbs)

      controller.send(:context_crumbs)

      assert_equal [], controller.instance_variable_get(:@context_crumbs)
    end

    test 'context_crumbs with non-index-new action skips breadcrumb' do
      get group_history_path(@group)
      # When action_name is neither 'index' nor 'new', no extra breadcrumb is added
      controller = Groups::HistoryController.new
      controller.instance_variable_set(:@group, @group)
      controller.stubs(:route_to_context_crumbs).returns([{ name: 'Group', path: '/group' }])
      controller.stubs(:action_name).returns('show')

      controller.send(:context_crumbs)

      context_crumbs = controller.instance_variable_get(:@context_crumbs)
      # Verify the breadcrumb from route_to_context_crumbs is there, but no extra one was added
      assert_equal 1, context_crumbs.length
      assert_equal 'Group', context_crumbs[0][:name]
      # Ensure the history index breadcrumb was NOT added (else branch coverage)
      assert_nil(context_crumbs.find { |c| c[:name] == I18n.t('groups.history.index.title') })

      assert_response :success
    end
  end
end
