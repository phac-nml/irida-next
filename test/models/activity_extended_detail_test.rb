# frozen_string_literal: true

require 'test_helper'

class ActivityExtendedDetailTest < ActiveSupport::TestCase
  def setup
    @activity_extended_detail = activity_extended_details(:project1_namespace_sample_transfer_activity_extended_details)
  end

  test 'valid activity_extended_detail' do
    assert @activity_extended_detail.valid?
  end

  test 'invalid activity_extended_detail activity reference' do
    @activity_extended_detail.activity = nil
    assert_not @activity_extended_detail.valid?
  end

  test 'invalid activity_extended_detail extended_detail reference' do
    @activity_extended_detail.extended_detail = nil
    assert_not @activity_extended_detail.valid?
  end

  test 'invalid activity_extended_detail activity_type' do
    @activity_extended_detail.activity_type = nil
    assert_not @activity_extended_detail.valid?
  end

  test 'maximum entries (2) for sample_clone between extended_details and activities' do
    activity = public_activity_activities(:project1_namespace_create)
    ext_details = extended_details(:project1_namespace_sample_clone_extended_details)

    activity_extended_detail = activity.create_activity_extended_detail(extended_detail: ext_details,
                                                                        activity_type: 'sample_clone')

    assert activity_extended_detail.errors.full_messages_for(:base).include?(
      I18n.t('activerecord.errors.models.activity_extended_detail.maximum_entries',
             activity_type: 'sample_clone')
    )
  end

  test 'maximum entries (2) for sample_transfer between extended_details and activities' do
    activity = public_activity_activities(:project1_namespace_create)
    ext_details = extended_details(:project1_namespace_sample_transfer_extended_details)

    activity_extended_detail = activity.create_activity_extended_detail(extended_detail: ext_details,
                                                                        activity_type: 'sample_transfer')

    assert activity_extended_detail.errors.full_messages_for(:base).include?(
      I18n.t('activerecord.errors.models.activity_extended_detail.maximum_entries',
             activity_type: 'sample_transfer')
    )
  end
end
