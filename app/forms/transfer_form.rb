# frozen_string_literal: true

# Form object for transferring groups
class TransferForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :new_namespace_id, :string
  attribute :group_id, :string

  validates :new_namespace_id, presence: { message: I18n.t('services.groups.transfer.namespace_empty') }
  validates :new_namespace_id,
            comparison: { other_than: :group_id,
                          message: I18n.t('services.groups.transfer.same_group_and_namespace') }

  def initialize(attributes = {})
    super
  end
end
