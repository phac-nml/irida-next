# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :attachable, polymorphic: true

  has_one_attached :file

  validates :file, attached: true

  # override destroy so that on soft delete we don't delete the ActiveStorage::Attachment
  def destroy
    update(deleted_at: Time.current)
  end
end
