# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace
  has_many :group_members, foreign_key: :namespace_id, inverse_of: :namespace,
                           class_name: 'Member', dependent: :destroy

  has_many :users, through: :group_members

  def self.sti_name
    'Group'
  end
end
