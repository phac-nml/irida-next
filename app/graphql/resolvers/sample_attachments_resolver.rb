# frozen_string_literal: true

module Resolvers
  # Sample Attachments Resolver
  class SampleAttachmentsResolver < BaseResolver
    argument :filter, Types::AttachmentFilterInputType,
             required: false,
             description: 'Ransack filter',
             default_value: nil

    argument :order_by, Types::AttachmentOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    alias sample object

    def resolve(filter:, order_by:)
      ransack_obj = sample.attachments.joins(:file_blob).ransack(filter&.to_h)
      ransack_obj.sorts = ["#{order_by.field} #{order_by.direction}"] if order_by.present?

      ransack_obj.result
    end
  end
end
