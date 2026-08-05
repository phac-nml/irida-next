# frozen_string_literal: true

# Concern to add archiving support to a model which has an `archived_at` attribute
module Archivable
  extend ActiveSupport::Concern

  ARCHIVABLE_TYPES = ['Project'].freeze

  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :not_archived, -> { where(archived_at: nil) }
  end

  def archived?
    archived_at.present?
  end

  def archivable?
    archived_at.blank? && ARCHIVABLE_TYPES.include?(type)
  end

  def archive(timestamp = Time.current)
    self.archived_at = timestamp
    self
  end

  def archive!
    archive
    save!
  end

  def unarchive
    self.archived_at = nil
    self
  end

  def unarchive!
    unarchive
    save!
  end
end
