# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class SampleResolver < BaseResolver
    argument :puid, GraphQL::Types::ID,
             required: true,
             description: 'Persistent Unique Identifier of the sample. For example, `INXT_SAM_AAAAAAAAAA`.'

    def resolve(puid:)
      Sample.find_by(puid:)
    end
  end
end
