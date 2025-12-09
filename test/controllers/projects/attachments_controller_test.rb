# frozen_string_literal: true

require 'test_helper'

module Projects
  class AttachmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @project1 = projects(:project1)
      @namespace = groups(:group_one)
      @attachment1 = attachments(:project1Attachment1)
    end

    test 'should get index' do
      get namespace_project_attachments_url(@namespace, @project1)
      assert_response :success

      w3c_validate 'Project Files Page'
    end

    test 'should not get index without proper access' do
      sign_in users(:ryan_doe)
      get namespace_project_attachments_url(@namespace, @project1)
      assert_response :unauthorized
    end

    test 'should get new' do
      get new_namespace_project_attachment_url(@namespace, @project1)
      assert_response :success
    end

    test 'should not get new without proper access' do
      sign_in users(:ryan_doe)
      get new_namespace_project_attachment_url(@namespace, @project1)
      assert_response :unauthorized
    end

    test 'should create attachment' do
      assert_difference('Attachment.count') do
        post namespace_project_attachments_url(@namespace, @project1),
             params: { attachment: {
               files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
             } },
             as: :turbo_stream
      end
    end

    test 'should get new_destroy' do
      get namespace_project_attachment_new_destroy_path(@namespace, @project1, @attachment1)
      assert_response :success
    end

    test 'should not get new_destroy without proper access' do
      sign_in users(:ryan_doe)
      get namespace_project_attachment_new_destroy_path(@namespace, @project1, @attachment1)
      assert_response :unauthorized
    end

    test 'should destroy attachment' do
      assert_difference -> { Attachment.count } => -1 do
        delete namespace_project_attachment_url(@namespace, @project1, @attachment1),
               as: :turbo_stream
      end
      assert_response :success
    end

    test 'should not destroy attachment that does not belong to project' do
      attachment = attachments(:attachmentA)
      delete namespace_project_attachment_url(@namespace, @project1, attachment),
             as: :turbo_stream
      assert_response :unprocessable_content
    end

    test 'should not destroy attachment without proper access' do
      sign_in users(:ryan_doe)
      delete namespace_project_attachment_url(@namespace, @project1, @attachment1),
             as: :turbo_stream
      assert_response :unauthorized
    end

    test 'accessing attachments index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 when only 2 pages exist should cause Pagy::OverflowError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_attachments_url(@namespace, @project1, page: 50)

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
