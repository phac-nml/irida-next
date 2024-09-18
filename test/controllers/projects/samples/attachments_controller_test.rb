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

      test 'should get new for a member with role >= maintainer' do
        get new_namespace_project_sample_attachment_path(@namespace, @project, @sample1,
                                                         format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new if not a member' do
        user = users(:micha_doe)
        login_as user

        get new_namespace_project_sample_attachment_path(@namespace, @project, @sample1,
                                                         format: :turbo_stream)
        assert_response :unauthorized
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

      test 'user with role >= Maintainer can create multiple attachments at once for a sample' do
        assert_difference('Attachment.count', 3) do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain'),
                         fixture_file_upload('test_file_3.fq', 'text/plain'),
                         fixture_file_upload('test_file_7.fa', 'text/plain')]
               } },
               as: :turbo_stream
        end
      end

      test 'user with role >= Maintainer can create multiple attachments but exclude duplicates at once for a sample' do
        assert_difference('Attachment.count') do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain'),
                         fixture_file_upload('test_file_A.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end
      end

      test 'user with role >= Maintainer cannot create a duplicate attachment for a sample' do
        assert_no_difference('Attachment.count') do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_A.fastq', 'text/plain')]
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

      test 'user with role >= Maintainer can upload and destroy paired attachments of a sample' do
        assert_difference('Attachment.count', 2) do
          post namespace_project_sample_attachments_url(@namespace, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('TestSample_S1_L001_R1_001.fastq', 'text/plain'),
                         fixture_file_upload('TestSample_S1_L001_R2_001.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end

        paired_attachment = @sample1.attachments[2]
        assert_difference('Attachment.count', -2) do
          delete namespace_project_sample_attachment_url(@namespace, @project, @sample1, paired_attachment),
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

      test 'new_destroy with proper authorization' do
        get namespace_project_sample_attachment_new_destroy_path(@namespace, @project, @sample1, @attachment1),
            as: :turbo_stream

        assert_response :success
      end

      test 'new_destroy without proper authorization' do
        sign_in users(:ryan_doe)
        get namespace_project_sample_attachment_new_destroy_path(@namespace, @project, @sample1, @attachment1),
            as: :turbo_stream

        assert_response :unauthorized
      end
    end
  end
end
