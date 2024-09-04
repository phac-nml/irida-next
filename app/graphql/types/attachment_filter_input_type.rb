# frozen_string_literal: true

module Types
  # Attachment Filter Input Type
  class AttachmentFilterInputType < BaseInputObject # rubocop:disable GraphQL/ObjectDescription
    graphql_name 'AttachmentFilter'
    Attachment.ransackable_attributes.each do |attr|
      Ransack.predicates.keys.map do |predicate, value|
        value_type = value&.wants_array ? [String] : String
        argument :"#{attr}_#{predicate}".to_sym,
                 value_type,
                 required: false,
                 camelize: false
      end
    end
  end
end
