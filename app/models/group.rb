# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  has_many :group_members, foreign_key: :namespace_id, inverse_of: :namespace,
                           class_name: 'Members::GroupMember', dependent: :destroy

  has_many :users, through: :group_members
  has_many :owners,
           -> { where(members: { access_level: Member::AccessLevel::OWNER }) },
           through: :group_members,
           source: :user

  def self.sti_name
    'Group'
  end
end
