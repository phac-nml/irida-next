# frozen_string_literal: true

require 'test_helper'

module Groups
  class AttachmentsTest < ActionDispatch::IntegrationTest
    include ActionView::Helpers::NumberHelper

    test 'can view attachments for a group with proper access' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      attachments = [attachments(:group1Attachment1), attachments(:group1Attachment2)]
      get group_attachments_path(group)

      assert_response :success

      assert_select 'h1', I18n.t('groups.attachments.index.title')
      assert_select 'p', I18n.t('groups.attachments.index.subtitle', puid: group.puid)

      assert_select 'button', I18n.t('components.attachments.dialogs.new_attachment_component.upload_files')
      assert_select "input[placeholder='#{I18n.t('groups.attachments.index.search.placeholder')}']"

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
              assert_select 'th', attachment.puid
              assert_select 'td', attachment.file.filename.to_s
              assert_select 'td', attachment.metadata['format']
              assert_select 'td', attachment.metadata['type']
              assert_select 'td', number_to_human_size(attachment.file.byte_size)
              assert_select 'td' do
                assert_select 'time[datetime=?]', attachment.created_at.iso8601
              end
              assert_select 'td' do
                assert_select 'button[aria-label=?]',
                              I18n.t('components.attachments.table_component.preview_aria_label',
                                     name: attachment.file.filename.to_s)
                assert_select 'button', text: I18n.t('common.actions.delete')
              end
            end
          end
        end
      end

      assert_select 'div#limit-component'
    end

    test 'cannot view attachments for a group without proper access' do
      sign_in users(:ryan_doe)
      group = groups(:group_one)

      get group_path(group)

      assert_response :success

      assert_select 'a', text: I18n.t('groups.sidebar.files'), count: 0

      get group_attachments_path(group)

      assert_response :unauthorized
    end

    test 'can create an attachment in a group with proper access' do
      sign_in users(:john_doe)
      group = groups(:group_one)

      get new_group_attachment_path(group, format: :turbo_stream)

      assert_response :success

      assert_select 'turbo-stream[target="attachment_modal"]' do
        assert_select 'h1', I18n.t('components.attachments.dialogs.new_attachment_component.upload_files')
      end

      assert_difference -> { group.attachments.count } do
        post group_attachments_path(group),
             params: { attachment: {
               files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('groups.attachments.create.success',
                                                                          filename: 'test_file_1.fastq')}"
          end
        end
      end

      assert_select 'turbo-stream[action="refresh"]'
    end

    test 'cannot create an attachment in a group with role == Analyst' do
      sign_in(users(:michelle_doe))
      group = groups(:group_one)

      get group_attachments_path(group)

      assert_select 'h1', I18n.t('groups.attachments.index.title')
      assert_select 'p', I18n.t('groups.attachments.index.subtitle', puid: groups(:group_one).puid)

      assert_select 'button', text: I18n.t('components.attachments.dialogs.new_attachment_component.upload_files'),
                              count: 0
      assert_select "input[placeholder='#{I18n.t('groups.attachments.index.search.placeholder')}']"

      get new_group_attachment_path(group, format: :turbo_stream)

      assert_response :unauthorized

      assert_no_difference -> { group.attachments.count } do
        post group_attachments_path(group),
             params: { attachment: {
               files: [fixture_file_upload('test_file_1.fastq', 'text/plain')]
             } },
             as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'can delete an attachment in a group with proper access' do
      sign_in users(:john_doe)
      group = groups(:group_one)

      attachment = attachments(:group1Attachment1)

      get group_attachments_path(group)

      assert_response :success

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select "tr##{dom_id(attachment)}" do
            assert_select 'button', text: I18n.t('common.actions.delete')
          end
        end
      end

      get group_attachment_new_destroy_path(group, attachment)

      assert_response :success

      assert_difference -> { group.attachments.count }, -1 do
        delete group_attachment_path(group, attachment), as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('groups.attachments.destroy.success',
                                                                          filename: attachment.file.filename)}"
          end
        end
      end

      assert_select 'turbo-stream[action="refresh"]'
    end

    test 'cannot delete an attachment in a group without proper access' do
      sign_in users(:michelle_doe)
      group = groups(:group_one)

      attachment = attachments(:group1Attachment1)

      get group_attachment_new_destroy_path(group, attachment)

      assert_response :unauthorized

      assert_no_difference [-> { Attachment.count }, -> { group.attachments.count }] do
        delete group_attachment_path(group, attachment), as: :turbo_stream
      end

      assert_response :unauthorized
    end

    test 'cannot delete an attachment in a group that does not belong to the group' do
      sign_in users(:john_doe)
      group = groups(:group_one)

      attachment = attachments(:attachmentA)

      get group_attachment_new_destroy_path(group, attachment)

      assert_response :success

      assert_no_difference [-> { Attachment.count }, -> { group.attachments.count }] do
        delete group_attachment_path(group, attachment), as: :turbo_stream
      end

      assert_response :unprocessable_content
    end

    test 'can sort attachments by supported columns' do
      sign_in(users(:john_doe))
      group = groups(:group_one)
      attachment1 = attachments(:group1Attachment1)
      attachment2 = attachments(:group1Attachment2)

      get group_attachments_path(group)
      assert_response :success
      assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'puid asc' } })
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(attachment1.puid, attachment2.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'puid desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'file_blob_filename asc' } })
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'metadata_format asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'file_blob_byte_size asc' } })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(attachment2.puid, attachment1.puid, row_scope: '#attachments-table-body')

      get group_attachments_path(group, params: { q: { s: 'updated_at asc' } })
      assert_response :success
      assert_first_rows_include(attachment1.puid, attachment2.puid, row_scope: '#attachments-table-body')
    end

    test 'attempting to access a non-existent attachments page causes pagy overflow and redirects to first page' do
      sign_in users(:john_doe)
      group = groups(:group_one)

      get group_attachments_path(group, page: 50)

      assert_response :redirect

      assert_match(/page=1/, response.location)

      follow_redirect!
      assert_response :success
    end

    test 'can filter attachments by filename or puid' do
      sign_in users(:john_doe)
      group = groups(:group_one)
      attachment1 = attachments(:group1Attachment1)
      attachment2 = attachments(:group1Attachment2)

      get group_attachments_path(group),
          params: { q: { puid_or_file_blob_filename_cont: attachment1.file.filename.to_s } }
      assert_response :success

      assert_select 'tbody' do
        assert_select 'tr', count: 1 do
          assert_select 'th', attachment1.puid
          assert_select 'td', attachment1.file.filename.to_s
        end
      end

      get group_attachments_path(group),
          params: { q: { puid_or_file_blob_filename_cont: attachment2.puid } }
      assert_response :success

      assert_select 'tbody' do
        assert_select 'tr', count: 1 do
          assert_select 'th', attachment2.puid
          assert_select 'td', attachment2.file.filename.to_s
        end
      end
    end
  end
end
