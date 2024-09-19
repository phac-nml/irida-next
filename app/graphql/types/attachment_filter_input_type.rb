# frozen_string_literal: true

module Types
  # Attachment Filter Input Type
  class AttachmentFilterInputType < BaseRansackFilterInputObject # rubocop:disable GraphQL/ObjectDescription
    graphql_name 'AttachmentFilter'
    Attachment.ransackable_attributes.excluding(DEFAULT_EXCLUDED_ATTRIBUTES).each do |attr|
      default_predicate_keys.map do |key|
        value_type = Ransack.predicates[key].wants_array ? [String] : String
        argument :"#{attr}_#{key}".to_sym,
                 value_type,
                 required: false,
                 camelize: false
      end
    end

    argument :metadata_jcont, GraphQL::Types::JSON,
             required: false, camelize: false,
             prepare: lambda { |json, _ctx|
               JSON.generate(json)
             },
             description: 'Filter attachments by metadata which contains the supplied key value pairs'
    argument :metadata_jcont_key, String,
             required: false, camelize: false,
             description: 'Filter attachments by metadata which contains the key'
  end
end
