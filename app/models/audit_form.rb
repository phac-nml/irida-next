# frozen_string_literal: true

# entity class for audit form
class AuditForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  MAX_REASON_LENGTH = 500

  attribute :reason, :string
  attr_accessor :user

  before_validation :normalize_reason

  validates :reason, presence: true, length: { maximum: MAX_REASON_LENGTH }, if: :reason_required?

  private

  def normalize_reason
    self.reason = reason.to_s.strip
  end

  def reason_required?
    user.nil? || Flipper.enabled?(:sample_deletion_reason, user)
  end
end
