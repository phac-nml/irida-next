# frozen_string_literal: true

module Types
  # Preauthorized Attachment Type
  # Only to be used as a return type on fields that are connections and
  # are either scoped or come from an authorized object
  class PreauthorizedAttachmentType < Types::AttachmentType # rubocop:disable GraphQL/ObjectDescription
    def self.authorized?(_object, _context)
      true
    end
  end
end
