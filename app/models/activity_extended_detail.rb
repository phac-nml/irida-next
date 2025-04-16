# frozen_string_literal: true

# entity class (join) for activity extended details
class ActivityExtendedDetail < ApplicationRecord
  belongs_to :activity, class_name: 'PublicActivity::Activity'
  belongs_to :extended_detail, class_name: 'ExtendedDetail'

  validates :extended_detail_id, uniqueness: { scope: :activity_id }
end
