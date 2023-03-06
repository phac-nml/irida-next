# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  # has_many :member, foreign_key: :namespace_id, inverse_of: :namespace, dependent: :destroy

  def self.sti_name
    'Group'
  end

  has_many :group_member, dependent: :destroy, as: :namespace, class_name: 'GroupMember'
end
