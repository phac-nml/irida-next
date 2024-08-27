# frozen_string_literal: true

require 'test_helper'

class DataExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:john_doe)
    @sample1 = samples(:sample1)
    @project1 = projects(:project1)
    @data_export1 = data_exports(:data_export_one)
    @namespace = namespaces_project_namespaces(:project1_namespace)
    @workflow1 = workflow_executions(:automated_workflow_execution)
    @workflow2 = workflow_executions(:automated_example_completed)
  end

  test 'should view exports' do
    get data_exports_path(@data_export1)
    assert_response :success
  end

  test 'should create new sample export with viable params' do
    params = { 'data_export' => {
                 'export_type' => 'sample',
                 'export_parameters' => { 'ids' => [@sample1.id], 'namespace_id' => @project1.namespace.id,
                                          'attachment_formats' =>
                                          Attachment::FORMAT_REGEX.keys }
               },
               format: :turbo_stream }
    assert_difference('DataExport.count', 1) do
      post data_exports_path(params)
    end
    assert_response :redirect
  end

  test 'should create new analysis export with viable params' do
    workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
    params = { 'data_export' => {
                 'export_type' => 'analysis',
                 'export_parameters' => { 'ids' => [workflow_execution.id], analysis_type: 'user' }
               },
               format: :turbo_stream }
    assert_difference('DataExport.count', 1) do
      post data_exports_path(params)
    end
    assert_response :redirect
  end

  test 'should create new linelist csv export with viable params' do
    params = { 'data_export' => {
                 'export_type' => 'linelist',
                 'export_parameters' => {
                   'ids' => [@sample1.id],
                   'namespace_id' => @project1.namespace.id,
                   'linelist_format' => 'csv',
                   'metadata_fields' => ['metadatafield1']
                 }
               },
               format: :turbo_stream }
    assert_difference('DataExport.count', 1) do
      post data_exports_path(params)
    end
    assert_response :redirect
  end

  test 'should create new linelist xlsx export with viable params' do
    params = { 'data_export' => {
                 'export_type' => 'linelist',
                 'export_parameters' => {
                   'ids' => [@sample1.id],
                   'namespace_id' => @project1.namespace.id,
                   'linelist_format' => 'xlsx',
                   'metadata_fields' => ['metadatafield1']
                 }
               },
               format: :turbo_stream }
    assert_difference('DataExport.count', 1) do
      post data_exports_path(params)
    end
    assert_response :redirect
  end

  test 'should delete export through destroy action' do
    assert_difference('DataExport.count', -1) do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :success
  end

  test 'should delete export and redirect through destroy action if redirect param present' do
    assert_difference('DataExport.count', -1) do
      delete data_export_path(@data_export1, redirect: true),
             as: :turbo_stream
    end
    assert_response :redirect
  end

  test 'should not delete export without valid authorization' do
    sign_in users(:jane_doe)
    assert_no_difference('DataExport.count') do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :unauthorized
  end

  test 'should view data export page' do
    get data_export_path(@data_export1)
    assert_response :success
  end

  test 'should not view data export page without proper authorization' do
    sign_in users(:jane_doe)
    get data_export_path(@data_export1)
    assert_response :unauthorized
  end

  test 'should view new export modal with export_type sample' do
    get new_data_export_path(export_type: 'sample', 'namespace_id' => @project1.namespace.id)
    assert_response :success
  end

  test 'should view new export modal with export_type analysis' do
    workflow_execution = workflow_executions(:workflow_execution_valid)
    get new_data_export_path(export_type: 'analysis', workflow_execution_id: workflow_execution.id)
    assert_response :success
  end

  test 'should view new export modal with export_type linelist and namespace.type project' do
    get new_data_export_path(export_type: 'linelist', 'namespace_id' => @project1.namespace.id)
    assert_response :success
  end

  test 'should view new export modal with export_type linelist and namespace.type group' do
    group = groups(:group_one)
    get new_data_export_path(export_type: 'linelist', 'namespace_id' => group.id)
    assert_response :success
  end

  test 'should create new export with only necessary params' do
    post data_exports_path, params: {
      data_export: {
        export_type: 'sample',
        export_parameters: { ids: [@sample1.id], 'namespace_id' => @project1.namespace.id,
                             'attachment_formats' => Attachment::FORMAT_REGEX.keys }
      }
    }
    assert_response :redirect
  end

  test 'should create new export with optional name and email params' do
    post data_exports_path, params: {
      data_export: {
        export_type: 'sample',
        export_parameters: { ids: [@sample1.id], 'namespace_id' => @project1.namespace.id,
                             'attachment_formats' => Attachment::FORMAT_REGEX.keys },
        email_notification: true,
        name: 'export name'
      }
    }
    assert_response :redirect
  end

  test 'should not create new export without export_type param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_parameters: { ids: [@sample1.id],
                                  'attachment_formats' => Attachment::FORMAT_REGEX.keys }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new export without export_parameters param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'sample'
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new export without export_parameters["ids"] param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'sample',
             export_parameters: { invalid_ids: ['not valid id'],
                                  'attachment_formats' => Attachment::FORMAT_REGEX.keys }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new linelist export without format param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'linelist',
             export_parameters: { 'ids' => [@sample1.id],
                                  'namespace_id' => @project1.namespace.id,
                                  'metadata_fields' => ['metadatafield1'] }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new linelist export with invalid linelist_format param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'linelist',
             export_parameters: { 'ids' => [@sample1.id],
                                  'namespace_id' => @project1.namespace.id,
                                  'linelist_format' => 'invalid_format',
                                  'metadata_fields' => ['metadatafield1'] }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new linelist export with missing namespace param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'linelist',
             export_parameters: { 'ids' => [@sample1.id],
                                  'linelist_format' => 'xlsx',
                                  'metadata_fields' => ['metadatafield1'] }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new linelist export with invalid namespace param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'linelist',
             export_parameters: { 'ids' => [@sample1.id],
                                  'namespace_id' => 'invalid_id',
                                  'linelist_format' => 'csv',
                                  'metadata_fields' => ['metadatafield1'] }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new linelist export with missing metadata_fields param' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'linelist',
             export_parameters: { 'ids' => [@sample1.id],
                                  'namespace_id' => 'invalid_id',
                                  'linelist_format' => 'csv' }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create sample export without attachment_formats param' do
    params = { 'data_export' => {
                 'export_type' => 'sample',
                 'export_parameters' => { 'ids' => [@sample1.id],
                                          'namespace_id' => @project1.namespace.id }
               },
               format: :turbo_stream }
    assert_no_difference('DataExport.count') do
      post data_exports_path(params)
    end
    assert_response :unprocessable_entity
  end

  test 'should redirect from project PUID' do
    get redirect_data_export_path(@data_export1, identifier: 'INXT_PRJ_AAAAAAAAAA')
    assert_response :redirect
  end

  test 'should redirect from sample PUID' do
    get redirect_data_export_path(@data_export1, identifier: 'INXT_SAM_AAAAAAAAAA')
    assert_response :redirect
  end

  test 'should list samples' do
    post list_data_exports_path(format: :turbo_stream), params: {
      page: 1,
      sample_ids: [@sample1.id],
      list_class: 'sample'
    }
    assert_response :success
  end

  test 'should create new analysis export with multiple ids' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'analysis',
             export_parameters: { 'ids' => [@workflow1.id, @workflow2.id],
                                  'namespace_id' => @namespace.id,
                                  'analysis_type' => 'project' }
           }
         }
    assert_response :redirect
  end

  test 'should not create new analysis export with missing analysis_type' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'analysis',
             export_parameters: { 'ids' => [@workflow1.id, @workflow2.id],
                                  'namespace_id' => @namespace.id }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new analysis export with invalid analysis_type' do
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'analysis',
             export_parameters: { 'ids' => [@workflow1.id, @workflow2.id],
                                  'namespace_id' => 'invalid_id' }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new analysis export with both user and project workflow ids and analysis_type project' do
    user_workflow = workflow_executions(:workflow_execution_valid)
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'analysis',
             export_parameters: { 'ids' => [@workflow1.id, @workflow2.id, user_workflow.id],
                                  'namespace_id' => @namespace.id,
                                  'analysis_type' => 'project' }
           }
         }
    assert_response :unprocessable_entity
  end

  test 'should not create new analysis export with both user and project workflow ids and analysis_type user' do
    user_workflow = workflow_executions(:workflow_execution_valid)
    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'analysis',
             export_parameters: { 'ids' => [@workflow1.id, @workflow2.id, user_workflow.id],
                                  'analysis_type' => 'user' }
           }
         }
    assert_response :unprocessable_entity
  end
end
