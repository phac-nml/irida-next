# frozen_string_literal: true

# form object for concatenating attachments
class ConcatenationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :basename, :string
  attribute :delete_originals, :boolean, default: false
  attribute :attachment_ids, array: true, default: -> { [] }

  validates :basename, presence: true, format: { with: /\A[a-zA-Z0-9_\-.]+\Z/ }
  validates :attachment_ids, presence: true, length: { minimum: 2 }

  before_validation :compact_attachment_ids

  def initialize(attributes = {})
    super
    self.attachment_ids = attachment_ids.values unless attachment_ids.is_a?(Array)
  end

  private

  def compact_attachment_ids
    self.attachment_ids = attachment_ids.compact_blank if attachment_ids.is_a?(Array)
  end
end
