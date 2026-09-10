# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class AttachmentsTest < ActionDispatch::IntegrationTest
    include ActionView::Helpers::NumberHelper
    include AdvancedSearchHelper

    setup do
      sign_in users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
      @summary_attachment = attachments(:workflow_execution_completed_output_attachment)
      @assembly_attachment = attachments(:samples_workflow_execution_completed_output_attachment)
    end

    test 'advanced search filters workflow execution attachments by format metadata field' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'metadata.format', operator: '=', value: @assembly_attachment.metadata['format'] }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 1
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}", count: 0
      end
    end

    test 'advanced search filters workflow execution attachments by compression metadata field' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'metadata.compression', operator: '=', value: @assembly_attachment.metadata['compression'] }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 1
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}", count: 0
      end
    end

    test 'advanced search filters workflow execution attachments by filename' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'filename', operator: 'contains',
                value: @assembly_attachment.file.filename.to_s.split('.').first }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 1
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}", count: 0
      end
    end

    test 'advanced search filters workflow execution attachments by puid' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'id', operator: '=', value: @assembly_attachment.puid }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 1
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}", count: 0
      end
    end

    test 'advanced search filters workflow execution attachments by byte size' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'byte_size', operator: '>', value: '0' }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 2
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}"
      end
    end

    test 'advanced search filters workflow execution attachments using multiple conditions in a group' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'metadata.format', operator: '=', value: @assembly_attachment.metadata['format'] },
              { field: 'metadata.compression', operator: '=', value: @assembly_attachment.metadata['compression'] }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 1
        assert_select "tr##{dom_id(@assembly_attachment)}"
        assert_select "tr##{dom_id(@summary_attachment)}", count: 0
      end
    end

    test 'advanced search with no results displays correctly' do
      get workflow_execution_path(@workflow_execution, tab: 'files'),
          params: attachments_advanced_search_params(
            [[{ field: 'metadata.format', operator: '=', value: 'nonexistent_format' }]]
          )

      assert_response :success
      assert_select '#attachments-table-body' do
        assert_select 'tr', count: 0
      end
    end
  end
end
