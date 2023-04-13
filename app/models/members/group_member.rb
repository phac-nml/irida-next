# frozen_string_literal: true

module Members
  # entity class for GroupMember
  class GroupMember < Member
    belongs_to :group, foreign_key: :namespace_id # rubocop:disable Rails/InverseOf
    before_destroy :last_namespace_owner_member

    def self.sti_name
      'GroupMember'
    end

    # Method to ensure we don't leave a group or project without an owner
    def last_namespace_owner_member
      return if destroyed_by_association
      return if access_level != Member::AccessLevel::OWNER
      return if Members::GroupMember.where(namespace: namespace.self_and_ancestors,
                                           access_level: Member::AccessLevel::OWNER).order(:access_level).many?

      errors.add(:base,
                 I18n.t('activerecord.errors.models.member.destroy.last_member',
                        namespace_type: namespace.type.downcase))
      false
    end
  end
end
