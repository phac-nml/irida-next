# frozen_string_literal: true

require 'test_helper'

class ExtendedDetailTest < ActiveSupport::TestCase
  def setup
    @extended_detail_clone = extended_details(:project1_namespace_sample_clone_extended_details)
    @extended_detail_transfer = extended_details(:project1_namespace_sample_transfer_extended_details)
  end

  test 'valid extended_detail' do
    assert @extended_detail_clone.valid?
    assert @extended_detail_transfer.valid?
  end

  test 'invalid extended_detail' do
    @extended_detail_clone.details = {}
    assert_not @extended_detail_clone.valid?

    @extended_detail_clone.details = nil
    assert_not @extended_detail_clone.valid?

    @extended_detail_transfer.details = {}
    assert_not @extended_detail_transfer.valid?

    @extended_detail_transfer.details = nil
    assert_not @extended_detail_transfer.valid?
  end

  test 'linked to correct activities through activity_extended_details join table' do
    assert @extended_detail_clone.activities.length == 2
    assert @extended_detail_clone.activities.include?(public_activity_activities(:project1_namespace_sample_clone))
    assert @extended_detail_clone.activities.include?(
      public_activity_activities(:project2_namespace_sample_cloned_from_project1)
    )

    assert @extended_detail_transfer.activities.length == 2
    assert @extended_detail_transfer.activities.include?(
      public_activity_activities(:project1_namespace_sample_transfer)
    )
    assert @extended_detail_transfer.activities.include?(
      public_activity_activities(:project2_namespace_sample_transferred_from_project1)
    )
  end
end
