# frozen_string_literal: true

module Groups
  # Form object for transferring groups
  class TransferForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :new_parent_id, :string
    attribute :group_id, :string
    attribute :group_name, :string
    attribute :group_path, :string

    validates :new_parent_id, presence: true
    validate :new_parent_exists, if: -> { new_parent_id.present? }
    validates :new_parent_id, comparison: { other_than: :group_id }, if: lambda {
      new_parent_id.present? && group_id.present?
    }
    validate :group_does_not_conflict_with_existing_group, if: lambda {
      new_parent_id.present? && group_name.present? && group_path.present?
    }

    def initialize(attributes = {})
      super
    end

    def new_parent
      Namespace.find_by(id: new_parent_id)
    end

    private

    def new_parent_exists
      return unless new_parent.nil?

      errors.add(:new_parent_id, :namespace_not_found)
    end

    def group_does_not_conflict_with_existing_group
      return unless Group.where(parent_id: new_parent_id).exists?(['path = ? or name = ?', group_path, group_name])

      errors.add(:new_parent_id, :namespace_group_exists)
    end
  end
end
