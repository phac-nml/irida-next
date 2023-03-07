# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  has_many :group_members, foreign_key: :namespace_id, inverse_of: :namespace,
                           class_name: 'GroupMember', dependent: :destroy

  def self.sti_name
    'Group'
  end
end
