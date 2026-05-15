# frozen_string_literal: true

# Form object for transferring groups
class TransferForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :new_namespace_id, :string
  attribute :group_id, :string
  attribute :group_name, :string
  attribute :group_path, :string

  validates :new_namespace_id, presence: { message: I18n.t('services.groups.transfer.namespace_empty') }
  validates :new_namespace_id,
            comparison: { other_than: :group_id,
                          message: I18n.t('services.groups.transfer.same_group_and_namespace') },
            if: -> { group_id.present? }
  validate :group_exists_in_namespace, if: -> { group_name.present? && group_path.present? }

  def initialize(attributes = {})
    super
  end

  private

  def group_exists_in_namespace
    return unless Group.where(parent_id: new_namespace_id).exists?(['path = ? or name = ?', group_path, group_name])

    errors.add(:new_namespace_id, I18n.t('services.groups.transfer.namespace_group_exists'))
  end
end
