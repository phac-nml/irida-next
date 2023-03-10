# frozen_string_literal: true

module Members
  # entity class for GroupMember
  class GroupMember < Member
    belongs_to :group, foreign_key: :namespace_id # rubocop:disable Rails/InverseOf

    def self.sti_name
      'GroupMember'
    end
  end
end
