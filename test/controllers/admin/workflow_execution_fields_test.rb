# frozen_string_literal: true

require 'test_helper'

module Admin
  class WorkflowExecutionFieldsTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:system_user)
      ApplicationSetting.delete_all
      ApplicationSetting.create_from_defaults
    end

    test 'system user can view the workflow execution fields page' do
      get admin_workflow_execution_fields_path

      assert_response :success
      assert_includes response.body, I18n.t('active_admin.workflow_execution_fields.title')
      assert_includes response.body, I18n.t('active_admin.workflow_execution_fields.field_label')
      assert_select 'textarea#workflow_execution_fields'
      assert_no_match(/translation missing/i, response.body)
    end

    test 'saving valid JSON persists the workflow execution fields' do
      definition = {
        'compute_queue' => {
          'type' => 'string',
          'title' => 'Compute queue',
          'enum' => %w[onprem azure],
          'default' => 'onprem',
          'required' => true
        }
      }

      patch admin_workflow_execution_fields_update_path,
            params: { workflow_execution_fields: definition.to_json }

      assert_redirected_to admin_workflow_execution_fields_path
      assert_equal I18n.t('active_admin.workflow_execution_fields.flash.success'), flash[:notice]
      assert_equal definition, ApplicationSetting.current.workflow_execution_fields
    end

    test 'saving invalid JSON shows a parse error and does not persist' do
      patch admin_workflow_execution_fields_update_path,
            params: { workflow_execution_fields: '{ not json }' }

      assert_redirected_to admin_workflow_execution_fields_path
      assert_equal I18n.t('active_admin.workflow_execution_fields.flash.error'), flash[:alert]
      assert_equal({}, ApplicationSetting.current.workflow_execution_fields)

      follow_redirect!
      assert_includes response.body, I18n.t('active_admin.workflow_execution_fields.errors_title')
    end

    test 'saving a schema-invalid definition shows errors and does not persist' do
      patch admin_workflow_execution_fields_update_path,
            params: { workflow_execution_fields: { 'compute_queue' => { 'type' => 'object' } }.to_json }

      assert_redirected_to admin_workflow_execution_fields_path
      assert_equal I18n.t('active_admin.workflow_execution_fields.flash.error'), flash[:alert]
      assert_equal({}, ApplicationSetting.current.workflow_execution_fields)
    end

    test 'saving a reserved key shows errors and does not persist' do
      patch admin_workflow_execution_fields_update_path,
            params: { workflow_execution_fields: { 'createdBy' => { 'type' => 'string' } }.to_json }

      assert_redirected_to admin_workflow_execution_fields_path
      assert_equal I18n.t('active_admin.workflow_execution_fields.flash.error'), flash[:alert]
      assert_equal({}, ApplicationSetting.current.workflow_execution_fields)
    end
  end
end
