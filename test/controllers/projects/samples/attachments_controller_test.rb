# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class AttachmentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @attachment1 = attachments(:attachment1)
        @sample1 = samples(:sample1)
        @project = projects(:project1)
        @namespace = groups(:group_one)
      end

      test 'user with role >= Maintainer can create an attachment for a sample' do
        assert_difference('Attachment.count') do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end
      end

      test 'user with role >= Maintainer cannot create a duplicate attachment for a sample' do
        assert_no_difference('Attachment.count') do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end
      end

      test 'user with role >= Maintainer can destroy an attachment of a sample' do
        assert_difference(-> { @sample1.attachments.count }, -1) do
          delete namespace_project_sample_attachment_url(@namespace, @project, @sample1, @attachment1),
                 as: :turbo_stream
        end
      end

      test 'user with role < Maintainer can not create an attachment for a sample' do
        sign_in users(:ryan_doe)
        assert_no_difference('Attachment.count') do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end
      end

      test 'user with role < Maintainer can not destroy an attachment of a sample' do
        sign_in users(:ryan_doe)
        assert_no_difference(-> { @sample1.attachments.count }) do
          delete namespace_project_sample_attachment_url(@namespace, @project, @sample1, @attachment1),
                 as: :turbo_stream
        end
      end

      test 'user with access can download the attachment' do
        get download_namespace_project_sample_attachment_url(@namespace, @project, @sample1, @attachment1)

        assert_response :success
      end

      test 'user without access cannot download the attachment' do
        sign_in users(:user_no_access)
        get download_namespace_project_sample_attachment_url(@namespace, @project, @sample1, @attachment1)

        assert_response :unauthorized
      end
    end
  end
end
