# frozen_string_literal: true

# entity class (join) for activity extended details
class ActivityExtendedDetail < ApplicationRecord
  before_create :validate_ext_details_entries

  belongs_to :activity, class_name: 'PublicActivity::Activity'
  belongs_to :extended_detail, class_name: 'ExtendedDetail'

  validates :activity_type, presence: true

  validates :extended_detail_id, uniqueness: { scope: :activity_id }

  # Validates that only the correct amount of join table entries can exist
  # for the activity_type
  def validate_ext_details_entries
    shared_extended_details_types = %w[project_sample_clone sample_transfer]
    existing_count = ActivityExtendedDetail.where(extended_detail: extended_detail).count

    if shared_extended_details_types.include?(activity_type)
      return if existing_count < 2
    elsif existing_count < 1
      return
    end

    errors.add(:base,
               I18n.t('activerecord.errors.models.activity_extended_detail.maximum_entries',
                      activity_type: activity_type))
  end
end
