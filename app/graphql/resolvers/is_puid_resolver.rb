# frozen_string_literal: true

module Resolvers
  # IsPuid Resolver
  class IsPuidResolver < BaseResolver
    argument :id, GraphQL::Types::ID,
             required: true,
             description: 'ID to compare to puid format'

    type Boolean, null: false

    def resolve(id:)
      id_sections = id.split('_')
      model_prefix = id_sections[1]
      return false unless id_sections.length == 3

      case model_prefix
      when 'SAM'
        Irida::PersistentUniqueId.valid_puid?(id, Sample)
      when 'ATT'
        Irida::PersistentUniqueId.valid_puid?(id, Attachment)
      when 'GRP'
        Irida::PersistentUniqueId.valid_puid?(id, Group)
      when 'PRJ'
        Irida::PersistentUniqueId.valid_puid?(id, Namespaces::ProjectNamespace)
      else
        false
      end
    end
  end
end
