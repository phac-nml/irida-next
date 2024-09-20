# frozen_string_literal: true

require 'test_helper'

module Groups
  class AttachmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @namespace = groups(:group_one)
      @attachment1 = attachments(:group1Attachment1)
    end

    test 'should get index' do
      get group_attachments_url(@namespace)
      assert_response :success
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
  end
end
