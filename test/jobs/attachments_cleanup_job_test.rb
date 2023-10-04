# frozen_string_literal: true

require 'test_helper'

class AttachmentsCleanupJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end
  def setup
    @att1 = attachments(:attachment1)
    @att2 = attachments(:attachment2)
    @att3 = attachments(:attachment3)
    @sample = samples(:sample1)
  end

  test 'valid attachments pretest' do
    assert @att1.valid?
    assert @att2.valid?
    assert @att3.valid?
  end

  # test '#destroy is a soft deletion and sets deleted_at' do
  #   assert_nil @attachment1.deleted_at
  #   @attachment1.destroy
  #   assert_not_nil @attachment1.deleted_at
  # end
end
