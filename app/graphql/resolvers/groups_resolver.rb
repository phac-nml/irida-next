# frozen_string_literal: true

module Resolvers
  # Groups Resolver
  class GroupsResolver < BaseResolver
    type Types::GroupType.connection_type, null: true

    argument :filter, Types::GroupFilterType,
             required: false,
             description: 'Ransack filter',
             default_value: nil

    argument :order_by, Types::GroupOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(filter:, order_by:)
      groups = authorized_scope Group, type: :relation
      ransack_obj = groups.ransack(filter&.to_h)
      ransack_obj.sorts = ["#{order_by.field} #{order_by.direction}"] if order_by.present?

      ransack_obj.result
    end
  end
end
