# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class AttachmentsTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project = projects(:project1)
        @namespace = groups(:group_one)
      end

      test 'user with role >= Maintainer should be able to see upload, concatenate and delete files buttons' do
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
        assert_selector 'button', text: I18n.t('projects.samples.show.concatenate_button'), count: 1
        assert_selector 'button', text: I18n.t('projects.samples.show.delete_files_button'), count: 1
      end

      test 'user with role < Maintainer should not be able to see upload, concatenate and delete files buttons' do
        user = users(:ryan_doe)
        login_as user
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 0
        assert_selector 'a', text: I18n.t('projects.samples.show.concatenate_button'), count: 0
        assert_selector 'a', text: I18n.t('projects.samples.show.delete_files_button'), count: 0
      end

      test 'user with role >= Maintainer should be able to attach a file to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
        within('#table-listing') do
          assert_text I18n.t('projects.samples.show.no_files')
          assert_text I18n.t('projects.samples.show.no_associated_files')
          assert_no_text 'test_file_2.fastq.gz'
        end
        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/data_export_1.zip')
          # check that button goes from being enabled to disabled when clicked
          assert_selector 'input[type=submit]:not(:disabled)'
          click_on I18n.t('projects.samples.show.upload')
          assert_selector 'input[type=submit]:disabled'
        end

        assert_text I18n.t('projects.samples.attachments.create.success', filename: 'data_export_1.zip')
        within('#table-listing') do
          assert_no_text I18n.t('projects.samples.show.no_files')
          assert_no_text I18n.t('projects.samples.show.no_associated_files')
          assert_text 'data_export_1.zip'
        end
      end

      test 'user with role >= Maintainer should not be able to attach a duplicate file to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file_2.fastq.gz')

        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog') do
          attach_file 'attachment[files][]', Rails.root.join('test/fixtures/files/test_file_2.fastq.gz')
          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.failure', filename: 'test_file_2.fastq.gz',
                                                                          errors: 'File checksum matches existing file')
      end

      test 'user with role >= Maintainer not be able to upload uncompressed files to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
        click_on I18n.t('projects.samples.show.upload_files')

        within('dialog') do
          attach_file 'attachment[files][]', [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz'),
                                              Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz'),
                                              Rails.root.join('test/fixtures/files/test_file.fastq')]
          assert_text I18n.t('projects.samples.show.files_ignored')
          assert_text 'test_file.fastq'

          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R1_001.fastq.gz')
        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R2_001.fastq.gz')
        assert_no_text I18n.t('projects.samples.attachments.create.success', filename: 'test_file.fastq')

        # View paired files
        within('#table-listing') do
          assert_text 'TestSample_S1_L001_R1_001.fastq.gz'
          assert_text 'TestSample_S1_L001_R2_001.fastq.gz'
        end
      end

      test 'user with role >= Maintainer should be able to delete a file from a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)

        within('#attachments-table-body') do
          assert_link text: I18n.t('projects.samples.attachments.attachment.delete'), count: 2
          click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
        end

        within('dialog') do
          assert_accessible
          assert_text I18n.t('projects.samples.attachments.delete_attachment_modal.description')
          click_button I18n.t('projects.samples.attachments.delete_attachment_modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'test_file_A.fastq')
        within('#table-listing') do
          assert_no_text 'test_file_A.fastq'
        end
      end

      test 'user with role >= Maintainer should be able to attach, view, and destroy paired files to a Sample' do
        visit namespace_project_sample_url(@namespace, @project, @sample2)
        # Initial View
        assert_selector 'a', text: I18n.t('projects.samples.show.new_attachment_button'), count: 1
        within('#table-listing') do
          assert_text I18n.t('projects.samples.show.no_files')
          assert_text I18n.t('projects.samples.show.no_associated_files')
          assert_selector 'button', text: I18n.t('projects.samples.attachments.attachment.delete'), count: 0
        end
        click_on I18n.t('projects.samples.show.upload_files')

        # Attach paired files
        within('dialog') do
          attach_file 'attachment[files][]',
                      [Rails.root.join('test/fixtures/files/TestSample_S1_L001_R1_001.fastq.gz'),
                       Rails.root.join('test/fixtures/files/TestSample_S1_L001_R2_001.fastq.gz')]
          click_on I18n.t('projects.samples.show.upload')
        end

        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R1_001.fastq.gz')
        assert_text I18n.t('projects.samples.attachments.create.success',
                           filename: 'TestSample_S1_L001_R2_001.fastq.gz')

        # View paired files
        within('#table-listing') do
          assert_text 'TestSample_S1_L001_R1_001.fastq.gz'
          assert_text 'TestSample_S1_L001_R2_001.fastq.gz'
          assert_link text: I18n.t('projects.samples.attachments.attachment.delete'), count: 1
        end

        # Destroy paired files
        within('#attachments-table-body') do
          click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
        end

        within('dialog') do
          click_button I18n.t('projects.samples.attachments.delete_attachment_modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.destroy.success',
                           filename: 'TestSample_S1_L001_R1_001.fastq.gz')
        assert_text I18n.t('projects.samples.attachments.destroy.success',
                           filename: 'TestSample_S1_L001_R2_001.fastq.gz')
        within('#table-listing') do
          assert_no_text 'TestSample_S1_L001_R1_001.fastq.gz'
          assert_no_text 'TestSample_S1_L001_R2_001.fastq.gz'
          assert_text I18n.t('projects.samples.show.no_files')
          assert_text I18n.t('projects.samples.show.no_associated_files')
        end
      end

      test 'user should not be able to see the upload file button for the sample' do
        user = users(:ryan_doe)
        login_as user

        visit namespace_project_sample_url(@namespace, @project, @sample1)

        assert_selector 'a', text: I18n.t('projects.samples.index.upload_file'), count: 0
      end

      test 'should concatenate single end attachment files and keep originals' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_A.fastq'
          assert_text 'test_file_B.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="table-listing"]) do
          assert_text 'concatenated_file'
          assert_selector 'table #attachments-table-body tr', count: 3
        end
      end

      test 'should concatenate paired end attachment files and keep originals' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="table-listing"]) do
          assert_text 'concatenated_file'
          assert_selector 'table #attachments-table-body tr', count: 7
        end
      end

      test 'should concatenate single end attachment files and remove originals' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_A.fastq'
          assert_text 'test_file_B.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          check 'Delete originals'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="table-listing"]) do
          assert_text 'concatenated_file'
          assert_selector 'table #attachments-table-body tr', count: 1
        end
      end

      test 'should concatenate paired end attachment files and remove originals' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          check 'Delete originals'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="table-listing"]) do
          assert_text 'concatenated_file_1.fastq'
          assert_text 'concatenated_file_2.fastq'
          assert_selector 'table #attachments-table-body tr', count: 4
        end
      end

      test 'should not concatenate single and paired end attachment files' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          assert_text 'test_file_D.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="concatenation-alert"]) do
          assert_text I18n.t('services.attachments.concatenation.incorrect_file_types')
        end
      end

      test 'should not concatenate compressed and uncompressed attachment files' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_2.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_D.fastq'
          assert_text 'test_file_2.fastq.gz'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="concatenation-alert"]) do
          assert_text I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
        end
      end

      test 'user with guest access should not be able to see the concatenate attachment files button' do
        user = users(:ryan_doe)
        login_as user

        visit namespace_project_sample_url(@namespace, @project, @sample1)

        assert_selector 'a', text: I18n.t('projects.samples.show.concatenate_button'), count: 0
      end

      test 'shouldn\'t concatenate files as the basename provided is not in the correct format' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated file'
          check 'Delete originals'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          !assert_html5_inputs_valid
        end
      end

      test 'should concatenate files as the basename provided is not in the correct format but fixed after error' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.concatenate_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated file'
          check 'Delete originals'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          fill_in I18n.t('projects.samples.attachments.concatenations.modal.basename'), with: 'concatenated_file'
          click_on I18n.t('projects.samples.attachments.concatenations.modal.submit_button')
          assert_html5_inputs_valid
        end
        within %(turbo-frame[id="table-listing"]) do
          assert_text 'concatenated_file_1.fastq'
          assert_text 'concatenated_file_2.fastq'
          assert_selector 'table #attachments-table-body tr', count: 4
        end
      end

      test 'should be able to delete multiple attachments' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          find('table #attachments-table-body tr', text: 'test_file_A.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_B.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.delete_files_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_A.fastq'
          assert_text 'test_file_B.fastq'
          click_on I18n.t('projects.samples.attachments.deletions.modal.submit_button')
          assert_html5_inputs_valid
        end
        assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 0
          assert_no_text 'test_file_A.fastq'
          assert_no_text 'test_file_B.fastq'
          assert_text I18n.t('projects.samples.show.no_files')
          assert_text I18n.t('projects.samples.show.no_associated_files')
        end
      end

      test 'should be able to delete multiple attachments including paired files' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          find('table #attachments-table-body tr', text: 'test_file_fwd_1.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_2.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_fwd_3.fastq').find('input').click
          find('table #attachments-table-body tr', text: 'test_file_D.fastq').find('input').click
        end
        click_button I18n.t('projects.samples.show.delete_files_button'), match: :first
        within('div[data-controller-connected="true"] dialog') do
          assert_text 'test_file_fwd_1.fastq'
          assert_text 'test_file_rev_1.fastq'
          assert_text 'test_file_fwd_2.fastq'
          assert_text 'test_file_rev_2.fastq'
          assert_text 'test_file_fwd_3.fastq'
          assert_text 'test_file_rev_3.fastq'
          assert_text 'test_file_D.fastq'
          click_on I18n.t('projects.samples.attachments.deletions.modal.submit_button')
        end
        assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          assert_no_text 'test_file_fwd_1.fastq'
          assert_no_text 'test_file_rev_1.fastq'
          assert_no_text 'test_file_fwd_2.fastq'
          assert_no_text 'test_file_rev_2.fastq'
          assert_no_text 'test_file_fwd_3.fastq'
          assert_no_text 'test_file_rev_3.fastq'
          assert_no_text 'test_file_D.fastq'
        end
      end

      test 'user can see delete buttons as owner' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_text I18n.t('projects.samples.show.delete_files_button'), count: 1
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          assert_text I18n.t('projects.samples.attachments.attachment.delete'), count: 2
        end
      end

      test 'user should not see sample attachment delete buttons if they are non-owner' do
        login_as users(:ryan_doe)
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        assert_text I18n.t('projects.samples.show.delete_files_button'), count: 0
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 2
          assert_text I18n.t('projects.samples.attachments.attachment.delete'), count: 0
        end
      end

      test 'user with role >= Maintainer can see attachment checkboxes' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body input[type=checkbox]', count: 2
        end
      end

      test 'user with role < Maintainer should not see checkboxes' do
        login_as users(:ryan_doe)
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body input[type=checkbox]', count: 0
        end
      end

      test 'initially checking off files and click files tab will still have same files checked' do
        login_as users(:jeff_doe)
        project = projects(:projectA)
        sample = samples(:sampleB)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        visit namespace_project_sample_url(namespace, project, sample)
        within %(turbo-frame[id="table-listing"]) do
          assert_selector 'table #attachments-table-body tr', count: 6
          all('input[type="checkbox"]')[0].click
          all('input[type="checkbox"]')[2].click
          all('input[type="checkbox"]')[4].click
        end

        click_on I18n.t('projects.samples.show.tabs.metadata')

        within %(#sample-tabs) do
          click_on I18n.t('projects.samples.show.tabs.files')
        end

        within %(turbo-frame[id="table-listing"]) do
          assert all('input[type="checkbox"]')[0].checked?
          assert all('input[type="checkbox"]')[2].checked?
          assert all('input[type="checkbox"]')[4].checked?
          assert_not all('input[type="checkbox"]')[1].checked?
          assert_not all('input[type="checkbox"]')[3].checked?
          assert_not all('input[type="checkbox"]')[5].checked?
        end
      end

      test 'delete single attachment with remove link while all attachments selected followed by multiple deletion' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)

        within('#attachments-table-body') do
          assert_link text: I18n.t('projects.samples.attachments.attachment.delete'), count: 2
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
          click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
        end

        within('dialog') do
          assert_text I18n.t('projects.samples.attachments.delete_attachment_modal.description')
          click_button I18n.t('projects.samples.attachments.delete_attachment_modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'test_file_A.fastq')
        within('#table-listing') do
          assert_no_text 'test_file_A.fastq'
          assert_text 'test_file_B.fastq'
        end

        click_button I18n.t('projects.samples.show.delete_files_button'), match: :first

        within('dialog') do
          assert_text 'test_file_B.fastq'
          assert_no_text 'test_file_A.fastq'
          click_button I18n.t('projects.samples.attachments.deletions.modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
        assert_no_text 'test_file_A.fastq'
        assert_no_text 'test_file_B.fastq'
        assert_text I18n.t('projects.samples.show.no_files')
        assert_selector 'button.cursor-not-allowed.pointer-events-none', count: 2
      end
    end
  end
end
