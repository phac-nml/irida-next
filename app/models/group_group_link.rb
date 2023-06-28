# frozen_string_literal: true

# entity class for GroupGroupLink
class GroupGroupLink < ApplicationRecord
  belongs_to :shared_group, class_name: 'Group'
  belongs_to :shared_with_group, class_name: 'Group'

  validates :shared_group_id, uniqueness: { scope: [:shared_with_group_id] }

  validates :group_access_level, inclusion: { in: Member::AccessLevel.all_values_with_owner },
                                 presence: true
end
