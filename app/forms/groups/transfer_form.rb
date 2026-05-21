# frozen_string_literal: true

module Groups
  # Form object for transferring groups
  class TransferForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :new_parent_id, :string
    attribute :group

    validates :new_parent_id, presence: true
    validate :new_parent_exists, if: -> { new_parent_id.present? }
    validate :group_does_not_conflict_with_existing_group, if: -> { new_parent_id.present? && group.present? }

    def initialize(attributes = {})
      super
    end

    def new_parent
      Namespace.find_by(id: new_parent_id)
    end

    def old_parent_id
      group.parent_id
    end

    delegate :id, to: :group, prefix: true

    delegate :name, to: :group, prefix: true

    delegate :path, to: :group, prefix: true

    private

    def new_parent_exists
      return unless new_parent.nil?

      errors.add(:new_parent_id, :namespace_not_found)
    end

    def group_does_not_conflict_with_existing_group
      if new_parent_id == old_parent_id
        errors.add(:new_parent_id, :cannot_be_same_as_old_parent)
        return
      end

      if new_parent_id == group_id
        errors.add(:new_parent_id, :cannot_be_same_as_group)
        return
      end

      return unless Group.where(parent_id: new_parent_id).exists?(['path = ? or name = ?', group_path, group_name])

      errors.add(:new_parent_id, :namespace_group_exists)
    end
  end
end
