# frozen_string_literal: true

module Resolvers
  module Metrics
    # Members Count Resolver
    class MembersCountResolver < BaseResolver
      def resolve # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
        if object.is_a?(Project)
          if object.namespace.parent.group_namespace?
            namespace_ids = if context[:direct_only]
                              object.namespace.id
                            else
                              [object.namespace.id] +
                                object.namespace.parent.self_and_ancestors_of_type([Group.sti_name]).select(:id)
                            end

            Member.joins(:user).where(
              user: { user_type: User.user_types[:human] },
              namespace_id: namespace_ids
            ).select(:user_id).distinct.count

          else
            object.namespace.project_members.joins(:user).where(
              user: { user_type: User.user_types[:human] }
            ).count + 1 # +1 for owner
          end
        elsif object.group_namespace?
          namespace_ids = if context[:direct_only]
                            object.id
                          else
                            object.self_and_ancestors_of_type([Group.sti_name]).select(:id)
                          end
          Member.joins(:user).where(
            user: { user_type: User.user_types[:human] },
            namespace_id: namespace_ids
          ).select(:user_id).distinct.count
        else
          count = Member.joins(:user).where(user: { user_type: User.user_types[:human] },
                                            namespace_id: Namespaces::ProjectNamespace.where(owner: object)).count

          return count + 1 if object.project_namespaces.any?

          count
        end
      end
    end
  end
end
