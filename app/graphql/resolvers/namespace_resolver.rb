# frozen_string_literal: true

module Resolvers
  # Namespace Resolver
  class NamespaceResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: false,
             description: 'Full path of the namespace. For example, `pathogen/surveillance`.'
    argument :puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifer of the namespace.
                           For example a group namespace, `INXT_GRP_GGGGGGGGGG.`'
    validates required: { one_of: %i[full_path puid] }

    def resolve(args)
      if args[:full_path]
        # Resolve Group or Namespaces::UserNamespace by full path
        Namespace.joins(:route).find_by(route: { path: args[:full_path] },
                                        type: [Group.sti_name,
                                               Namespaces::UserNamespace.sti_name])
      else
        # Resolve Group or Namespaces::UserNamespace by puid
        Namespace.find_by(puid: args[:puid], type: [Group.sti_name,
                                                    Namespaces::UserNamespace.sti_name])
      end
    end
  end
end
