# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class AttachmentsTest < ActionDispatch::IntegrationTest
      include ActionView::Helpers::NumberHelper

      setup do
        @sample1 = samples(:sample1)
        @project = projects(:project1)
        @group = groups(:group_one)
      end

      test 'can view attachments for a sample with proper access' do
        sign_in users(:john_doe)
        attachments = [attachments(:attachment1), attachments(:attachment2)]
        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }

        assert_response :success

        assert_select 'h1', @sample1.name

        assert_select 'button', text: I18n.t('components.attachments.dialogs.new_attachment_component.upload_files')
        assert_select 'button', text: I18n.t('projects.samples.show.concatenate_button')
        assert_select 'button', text: I18n.t('projects.samples.show.delete_files_button')
        assert_select 'button', text: I18n.t('common.controls.select_all')
        assert_select 'button', text: I18n.t('common.controls.deselect_all')
        assert_select "input[placeholder='#{I18n.t('projects.samples.attachments.table.search.placeholder')}']"

        assert_select 'table' do
          assert_select 'thead' do
            assert_select 'tr' do
              assert_select 'th', I18n.t('components.attachments.table_component.id')
              assert_select 'th', I18n.t('components.attachments.table_component.filename')
              assert_select 'th', I18n.t('components.attachments.table_component.format')
              assert_select 'th', I18n.t('components.attachments.table_component.type')
              assert_select 'th', I18n.t('components.attachments.table_component.byte_size')
              assert_select 'th', I18n.t('components.attachments.table_component.created_at')
              assert_select 'th', I18n.t('common.labels.actions')
            end
          end

          assert_select 'tbody' do
            attachments.each do |attachment|
              assert_select 'tr' do
                assert_select 'th', attachment.puid do
                  assert_select 'input[type=checkbox]'
                end
                assert_select 'td', attachment.file.filename.to_s
                assert_select 'td', attachment.metadata['format']
                assert_select 'td', attachment.metadata['type']
                assert_select 'td', number_to_human_size(attachment.file.byte_size)
                assert_select 'td' do
                  assert_select 'time[datetime=?]', attachment.created_at.iso8601
                end
                assert_select 'td' do
                  assert_select 'a', text: I18n.t('components.attachments.table_component.preview')
                  assert_select 'button', text: I18n.t('common.actions.delete')
                end
              end
            end
          end
        end

        assert_select 'div#limit-component'
      end

      test 'can view attachments with role < Maintainer but not actions' do
        sign_in users(:ryan_doe)
        attachments = [attachments(:attachment1), attachments(:attachment2)]
        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }

        assert_response :success

        assert_select 'h1', @sample1.name

        assert_select 'button', text: I18n.t('components.attachments.dialogs.new_attachment_component.upload_files'),
                                count: 0
        assert_select 'button', text: I18n.t('projects.samples.show.concatenate_button'), count: 0
        assert_select 'button', text: I18n.t('projects.samples.show.delete_files_button'), count: 0
        assert_select 'button', text: I18n.t('common.controls.select_all'), count: 0
        assert_select 'button', text: I18n.t('common.controls.deselect_all'), count: 0
        assert_select "input[placeholder='#{I18n.t('projects.samples.attachments.table.search.placeholder')}']"

        assert_select 'table' do
          assert_select 'thead' do
            assert_select 'tr' do
              assert_select 'th', I18n.t('components.attachments.table_component.id')
              assert_select 'th', I18n.t('components.attachments.table_component.filename')
              assert_select 'th', I18n.t('components.attachments.table_component.format')
              assert_select 'th', I18n.t('components.attachments.table_component.type')
              assert_select 'th', I18n.t('components.attachments.table_component.byte_size')
              assert_select 'th', I18n.t('components.attachments.table_component.created_at')
              assert_select 'th', I18n.t('common.labels.actions')
            end
          end

          assert_select 'tbody' do
            attachments.each do |attachment|
              assert_select 'tr' do
                assert_select 'th', attachment.puid do
                  assert_select 'input[type=checkbox]', count: 0
                end
                assert_select 'td', attachment.file.filename.to_s
                assert_select 'td', attachment.metadata['format']
                assert_select 'td', attachment.metadata['type']
                assert_select 'td', number_to_human_size(attachment.file.byte_size)
                assert_select 'td' do
                  assert_select 'time[datetime=?]', attachment.created_at.iso8601
                end
                assert_select 'td' do
                  assert_select 'a', text: I18n.t('components.attachments.table_component.preview')
                  assert_select 'button', text: I18n.t('common.actions.delete'), count: 0
                end
              end
            end
          end
        end

        assert_select 'div#limit-component'
      end

      test 'cannot view attachments for a sample without proper access' do
        sign_in users(:micha_doe)
        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }

        assert_response :unauthorized
      end

      test 'empty state is displayed when no attachments exist for a sample with proper access' do
        sign_in users(:john_doe)
        get namespace_project_sample_path(@group, @project, samples(:sample2)), params: { tab: 'files' }

        assert_response :success

        assert_select 'h2', I18n.t('projects.samples.attachments.table.empty_state.title')
        assert_select 'a', I18n.t('projects.samples.attachments.table.empty_state.action_text')
      end

      test 'can create an attachment for a sample with proper access' do
        sign_in users(:john_doe)

        get new_namespace_project_sample_attachment_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[target="sample_modal"]' do
          assert_select 'h1', I18n.t('projects.samples.show.upload_files')
        end

        assert_difference -> { @sample1.attachments.count } do
          post namespace_project_sample_attachments_url(@group, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.create.success',
                                             filename: 'test_file_1.fastq')}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'cannot create an attachment in a sample with role == Analyst' do
        sign_in users(:michelle_doe)

        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }

        assert_select 'h1', @sample1.name

        assert_select 'button', text: I18n.t('components.attachments.dialogs.new_attachment_component.upload_files'),
                                count: 0
        assert_select "input[placeholder='#{I18n.t('projects.samples.attachments.table.search.placeholder')}']"

        get new_namespace_project_sample_attachment_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :unauthorized

        assert_no_difference -> { @sample1.attachments.count } do
          post namespace_project_sample_attachments_url(@group, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end

        assert_response :unauthorized
      end

      test 'can create multiple attachments at once for a sample with proper access' do
        sign_in users(:john_doe)

        get new_namespace_project_sample_attachment_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[target="sample_modal"]' do
          assert_select 'h1', I18n.t('projects.samples.show.upload_files')
        end

        assert_difference -> { @sample1.attachments.count }, 2 do
          post namespace_project_sample_attachments_url(@group, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_1.fastq', 'text/plain'),
                         fixture_file_upload('test_file_2.fastq.gz', 'application/gzip')]
               } },
               as: :turbo_stream
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.create.success',
                                             filename: 'test_file_1.fastq')}"

              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.create.success',
                                             filename: 'test_file_2.fastq.gz')}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'cannot upload a duplicate attachment for a sample with proper access' do
        sign_in users(:john_doe)

        get new_namespace_project_sample_attachment_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[target="sample_modal"]' do
          assert_select 'h1', I18n.t('projects.samples.show.upload_files')
        end

        assert_no_difference -> { @sample1.attachments.count } do
          post namespace_project_sample_attachments_url(@group, @project, @sample1),
               params: { attachment: {
                 files: [fixture_file_upload('test_file_A.fastq', 'text/plain')]
               } },
               as: :turbo_stream
        end

        assert_response :multi_status

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('projects.samples.attachments.create.failure',
                                             filename: 'test_file_A.fastq',
                                             errors: 'File checksum matches existing file')}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'cannot upload a attachment for a sample when no file passed' do
        sign_in users(:john_doe)

        get new_namespace_project_sample_attachment_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[target="sample_modal"]' do
          assert_select 'h1', I18n.t('projects.samples.show.upload_files')
        end

        assert_no_difference -> { @sample1.attachments.count } do
          post namespace_project_sample_attachments_url(@group, @project, @sample1),
               params: { attachment: {
                 files: []
               } },
               as: :turbo_stream
        end

        assert_response :unprocessable_content
      end

      test 'can delete an attachment in a sample with proper access' do
        sign_in users(:john_doe)

        attachment = attachments(:attachment1)

        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }

        assert_response :success

        assert_select 'table' do
          assert_select 'tbody' do
            assert_select "tr##{dom_id(attachment)}" do
              assert_select 'button', text: I18n.t('common.actions.delete')
            end
          end
        end

        get namespace_project_sample_attachment_new_destroy_path(@group, @project, @sample1, attachment)

        assert_response :success

        assert_difference -> { @sample1.attachments.count }, -1 do
          delete namespace_project_sample_attachment_url(@group, @project, @sample1, attachment), as: :turbo_stream
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.destroy.success',
                                             filename: attachment.file.filename.to_s)}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'cannot delete an attachment in a sample without proper access' do
        sign_in users(:michelle_doe)

        attachment = attachments(:attachment1)

        get namespace_project_sample_attachment_new_destroy_path(@group, @project, @sample1, attachment)

        assert_response :unauthorized

        assert_no_difference -> { @sample1.attachments.count } do
          delete namespace_project_sample_attachment_url(@group, @project, @sample1, attachment), as: :turbo_stream
        end

        assert_response :unauthorized
      end

      test 'cannot delete an attachment in a sample that does not belong to the sample' do
        sign_in users(:john_doe)

        attachment = attachments(:attachment3)

        get namespace_project_sample_attachment_new_destroy_path(@group, @project, @sample1, attachment)

        assert_response :success

        assert_no_difference -> { @sample1.attachments.count } do
          delete namespace_project_sample_attachment_url(@group, @project, @sample1, attachment), as: :turbo_stream
        end

        assert_response :not_found
      end

      test 'can delete a paired attachment in a sample with proper access' do
        sign_in users(:jeff_doe)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        project = projects(:projectA)
        sample = samples(:sampleB)
        attachment_pe_fwd1 = attachments(:attachmentPEFWD1)
        attachment_pe_rev1 = attachments(:attachmentPEREV1)

        get namespace_project_sample_path(namespace, project, sample), params: { tab: 'files' }

        assert_response :success

        assert_select 'table' do
          assert_select 'tbody' do
            assert_select "tr##{dom_id(attachment_pe_fwd1)}" do
              assert_select 'button', text: I18n.t('common.actions.delete')
            end
          end
        end

        get namespace_project_sample_attachment_new_destroy_path(namespace, project, sample, attachment_pe_fwd1)

        assert_response :success

        assert_difference -> { sample.attachments.count }, -2 do
          delete namespace_project_sample_attachment_url(namespace, project, sample, attachment_pe_fwd1),
                 as: :turbo_stream
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.destroy.success',
                                             filename: attachment_pe_fwd1.file.filename.to_s)}"
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.destroy.success',
                                             filename: attachment_pe_rev1.file.filename.to_s)}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'can delete multiple attachments in a sample with role >= Maintainer' do
        sign_in users(:john_doe)

        get new_namespace_project_sample_attachments_deletion_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[target="sample_modal"]' do
          assert_select 'h1', I18n.t('projects.samples.attachments.deletions.modal.title')
          assert_select 'p', I18n.t('projects.samples.attachments.deletions.modal.description')

          assert_select 'form' do
            assert_select 'input[type="submit"]', value: I18n.t('common.actions.delete')
          end
        end

        assert_difference -> { @sample1.attachments.count }, -2 do
          delete namespace_project_sample_attachments_deletion_path(@group, @project, @sample1, format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => attachments(:attachment1).id, '1' => attachments(:attachment2).id }
                   }
                 }
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.success',
                                             count: 2)}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'cannot delete multiple attachments in a sample with role < Maintainer' do
        sign_in users(:michelle_doe)

        get new_namespace_project_sample_attachments_deletion_path(@group, @project, @sample1, format: :turbo_stream)

        assert_response :unauthorized

        assert_no_difference -> { @sample1.attachments.count }, -> { Attachment.count } do
          delete namespace_project_sample_attachments_deletion_path(@group, @project, @sample1, format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => attachments(:attachment1).id, '1' => attachments(:attachment2).id }
                   }
                 }
        end

        assert_response :unauthorized
      end

      test 'cannot delete multiple attachments in a sample that do not belong to the sample' do
        sign_in users(:john_doe)

        assert_no_difference -> { @sample1.attachments.count }, -> { Attachment.count } do
          delete namespace_project_sample_attachments_deletion_path(@group, @project, @sample1, format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => attachments(:attachmentA).id, '1' => attachments(:attachmentB).id }
                   }
                 }
        end

        assert_response :unprocessable_content

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.error',
                                             filename: attachments(:attachmentA).file.filename.to_s,
                                             errors:
                                               I18n.t('services.attachments.destroy.does_not_belong_to_attachable'))}"
            end
          end
        end

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.error',
                                             filename: attachments(:attachmentB).file.filename.to_s,
                                             errors:
                                               I18n.t('services.attachments.destroy.does_not_belong_to_attachable'))}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'can delete multiple paired attachments in a sample with role >= Maintainer' do
        sign_in users(:jeff_doe)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        project = projects(:projectA)
        sample = samples(:sampleB)
        attachment_pe_fwd1 = attachments(:attachmentPEFWD1)
        attachment_pe_rev1 = attachments(:attachmentPEREV1)
        attachment_pe_fwd2 = attachments(:attachmentPEFWD2)
        attachment_pe_rev2 = attachments(:attachmentPEREV2)

        get new_namespace_project_sample_attachments_deletion_path(namespace, project, sample, format: :turbo_stream)

        assert_response :success

        assert_difference -> { sample.attachments.count }, -4 do
          delete namespace_project_sample_attachments_deletion_path(namespace, project, sample, format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => [attachment_pe_fwd1.id, attachment_pe_rev1.id],
                                       '1' => [attachment_pe_fwd2.id, attachment_pe_rev2.id] }
                   }
                 }
        end

        assert_response :success

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.success')}"
            end
          end
        end

        assert_select 'turbo-stream[action="refresh"]'
      end

      test 'multiple deletion request returns multi_status when only some attachments are deleted' do
        sign_in users(:jeff_doe)
        namespace = namespaces_user_namespaces(:jeff_doe_namespace)
        project = projects(:projectA)
        sample = samples(:sampleB)
        attachment_a = attachments(:attachmentA)
        attachment_pe_fwd1 = attachments(:attachmentPEFWD1)
        attachment_pe_rev1 = attachments(:attachmentPEREV1)

        assert_difference -> { sample.attachments.count }, -2 do
          delete namespace_project_sample_attachments_deletion_path(namespace, project, sample, format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => [attachment_pe_fwd1.id, attachment_pe_rev1.id],
                                       '1' => attachment_a.id }
                   }
                 }
        end

        assert_response :multi_status

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.success')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.partial_success')}"
            end
          end
        end

        assert_select 'turbo-stream[action="append"][target="flashes"]' do
          assert_select 'template' do
            assert_select 'div[role="alert"]' do
              assert_select 'div', "#{I18n.t('common.statuses.error')}: " \
                                   "#{I18n.t('projects.samples.attachments.deletions.destroy.error',
                                             filename: attachment_a.file.filename.to_s,
                                             errors:
                                               I18n.t('services.attachments.destroy.does_not_belong_to_attachable'))}"
            end
          end
        end
      end

      test 'can sort attachments by supported columns' do
        sign_in users(:john_doe)

        attachment1 = attachments(:attachment1)
        attachment2 = attachments(:attachment2)

        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files' }
        assert_response :success
        assert_first_rows_include(attachment2.puid, attachment1.puid)

        get namespace_project_sample_path(@group, @project, @sample1, params: { tab: 'files', q: { s: 'puid asc' } })
        assert_response :success
        assert_sort_state(1, 'ascending')
        assert_first_rows_include(attachment1.puid, attachment2.puid, row_scope: '#attachments-table-body')

        get namespace_project_sample_path(@group, @project, @sample1, params: { tab: 'files', q: { s: 'puid desc' } })
        assert_response :success
        assert_sort_state(1, 'descending')
        assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

        get namespace_project_sample_path(@group, @project, @sample1,
                                          params: { tab: 'files', q: { s: 'file_blob_filename asc' } })
        assert_response :success
        assert_sort_state(2, 'ascending')
        assert_first_rows_include(attachment1.puid, attachment2.puid, row_scope: '#attachments-table-body')

        get namespace_project_sample_path(@group, @project, @sample1,
                                          params: { tab: 'files', q: { s: 'metadata_format asc' } })
        assert_response :success
        assert_sort_state(3, 'ascending')

        get namespace_project_sample_path(@group, @project, @sample1,
                                          params: { tab: 'files', q: { s: 'file_blob_byte_size asc' } })
        assert_response :success
        assert_sort_state(5, 'ascending')

        get namespace_project_sample_path(@group, @project, @sample1,
                                          params: { tab: 'files', q: { s: 'updated_at asc' } })
        assert_response :success
        assert_first_rows_include(attachment1.puid, attachment2.puid, row_scope: '#attachments-table-body')
      end

      test 'accessing a non-existent attachments page causes pagy overflow and redirects to the first page' do
        sign_in users(:john_doe)

        get namespace_project_sample_path(@group, @project, @sample1), params: { tab: 'files', page: 999 }

        assert_response :redirect

        assert_match(/page=1/, response.location)

        follow_redirect!
        assert_response :success
      end

      test 'can filter attachments by filename or puid' do
        sign_in users(:john_doe)

        attachment1 = attachments(:attachment1)
        attachment2 = attachments(:attachment2)

        get namespace_project_sample_path(@group, @project, @sample1),
            params: { tab: 'files', q: { puid_or_file_blob_filename_cont: attachment1.file.filename.to_s } }
        assert_response :success

        assert_select 'tbody' do
          assert_select 'tr', count: 1 do
            assert_select 'th', attachment1.puid
            assert_select 'td', attachment1.file.filename.to_s
          end
        end

        get namespace_project_sample_path(@group, @project, @sample1),
            params: { tab: 'files', q: { puid_or_file_blob_filename_cont: attachment2.puid } }
        assert_response :success

        assert_select 'tbody' do
          assert_select 'tr', count: 1 do
            assert_select 'th', attachment2.puid
            assert_select 'td', attachment2.file.filename.to_s
          end
        end
      end

      test 'can select attachments for a sample with proper access' do
        sign_in users(:john_doe)

        attachments = [attachments(:attachment1), attachments(:attachment2)]
        attachment_ids = attachments.map(&:id)

        get select_namespace_project_sample_attachments_url(@group, @project, @sample1, format: :turbo_stream),
            params: { select: true }

        assert_response :success

        assert_select 'turbo-stream[action="update"][target="selected"]' do
          assert_select 'template' do
            assert_select "div[data-controller='table-selection']" \
                          "[data-table-selection-selection-outlet='#attachments-table']" \
                          "[data-table-selection-ids-value='#{attachment_ids}']"
          end
        end
      end

      test 'can deselect attachments for a sample with proper access' do
        sign_in users(:john_doe)

        get select_namespace_project_sample_attachments_url(@group, @project, @sample1, format: :turbo_stream)

        assert_response :success

        assert_select 'turbo-stream[action="update"][target="selected"]' do
          assert_select 'template' do
            assert_select "div[data-controller='table-selection']" \
                          "[data-table-selection-selection-outlet='#attachments-table']" \
                          "[data-table-selection-ids-value='[]']"
          end
        end
      end

      test 'cannot select attachments for a sample without proper access' do
        sign_in users(:ryan_doe)

        get select_namespace_project_sample_attachments_url(@group, @project, @sample1, format: :turbo_stream)

        assert_response :unauthorized
      end
    end
  end
end
