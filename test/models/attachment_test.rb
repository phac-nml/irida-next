# frozen_string_literal: true

require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  def setup
    @attachment1 = attachments(:attachment1)
    @sample = samples(:sample1)
  end

  test 'valid attachment' do
    assert @attachment1.valid?
  end

  test 'invalid when no file attached' do
    invalid_attachment = @sample.attachments.build
    assert_not invalid_attachment.valid?
    assert invalid_attachment.errors.added?(:file, :blank)
  end

  test 'invalid when file checksum matches another Attachment associated with the Attachable' do
    new_attachment = @sample.attachments.build
    new_attachment.file.attach(io: Rails.root.join('test/fixtures/files/test_file.fastq').open,
                               filename: 'test_file.fastq')
    assert_not new_attachment.valid?
    assert new_attachment.errors.added?(:file, :checksum_uniqueness)
  end

  test '#destroy does not destroy the ActiveStorage::Attachment' do
    assert_no_difference('ActiveStorage::Attachment.count') do
      @attachment1.destroy
    end
  end

  test '#destroy is a soft deletion and sets deleted_at' do
    assert_nil @attachment1.deleted_at
    @attachment1.destroy
    assert_not_nil @attachment1.deleted_at
  end
end
