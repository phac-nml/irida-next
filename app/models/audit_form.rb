# frozen_string_literal: true

# entity class for audit form
class AuditForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  MAX_REASON_LENGTH = 500

  attribute :reason, :string

  before_validation :normalize_reason

  validates :reason, presence: true, length: { maximum: MAX_REASON_LENGTH }

  private

  def normalize_reason
    self.reason = reason.to_s.squish
  end
end
