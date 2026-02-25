# frozen_string_literal: true

require 'test_helper'

module Groups
  class AttachmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @namespace = groups(:group_one)
      @attachment1 = attachments(:group1Attachment1)
      @attachment2 = attachments(:group1Attachment2)
      @attachment1.update!(updated_at: 3.hours.ago)
      @attachment2.update!(updated_at: 2.hours.ago)
    end

    test 'should get index' do
      get group_attachments_url(@namespace)
      assert_response :success

      w3c_validate 'Group Files Page'
    end

    test 'should not get index without proper access' do
      sign_in users(:ryan_doe)
      get group_attachments_url(@namespace)
      assert_response :unauthorized
    end

    test 'should get new' do
      get new_group_attachment_url(@namespace)
      assert_response :success
    end

    test 'should not get new without proper access' do
      sign_in users(:ryan_doe)
      get new_group_attachment_url(@namespace)
      assert_response :unauthorized
    end

    test 'should create attachment' do
      assert_difference('Attachment.count') do
        post group_attachments_url(@namespace),
             params: { attachment: {
               files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
             } },
             as: :turbo_stream
      end
    end

    test 'should get new_destroy' do
      get group_attachment_new_destroy_path(@namespace, @attachment1)
      assert_response :success
    end

    test 'should not get new_destroy without proper access' do
      sign_in users(:ryan_doe)
      get group_attachment_new_destroy_path(@namespace, @attachment1)
      assert_response :unauthorized
    end

    test 'should destroy attachment' do
      assert_difference -> { Attachment.count } => -1 do
        delete group_attachment_url(@namespace, @attachment1),
               as: :turbo_stream
      end
      assert_response :success
    end

    test 'should not destroy attachment that does not belong to project' do
      attachment = attachments(:attachmentA)
      delete group_attachment_url(@namespace, attachment),
             as: :turbo_stream
      assert_response :unprocessable_content
    end

    test 'should not destroy attachment without proper access' do
      sign_in users(:ryan_doe)
      delete group_attachment_url(@namespace, @attachment1),
             as: :turbo_stream
      assert_response :unauthorized
    end

    test 'should apply default sorting and sort attachments by supported columns' do
      get group_attachments_url(@namespace)
      assert_response :success
      assert_first_rows_include(@attachment2.puid, @attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'puid asc' } })
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@attachment1.puid, @attachment2.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'puid desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@attachment2.puid, @attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'file_blob_filename asc' } })
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_first_rows_include(@attachment2.puid, @attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'metadata_format asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(@attachment2.puid, @attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'file_blob_byte_size asc' } })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(@attachment2.puid, @attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_url(@namespace, params: { q: { s: 'updated_at asc' } })
      assert_response :success
      assert_first_rows_include(@attachment1.puid, @attachment2.puid, row_scope: '#attachments-table-body')
    end

    test 'accessing attachments index on invalid page causes pagy overflow redirect at group level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get group_attachments_path(@namespace, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
