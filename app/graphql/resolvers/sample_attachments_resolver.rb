# frozen_string_literal: true

module Resolvers
  # Sample Attachments Resolver
  class SampleAttachmentsResolver < BaseResolver
    type [String], null: true

    alias sample object

    def resolve
      scope = sample
      scope.attachments
    end
  end
end
