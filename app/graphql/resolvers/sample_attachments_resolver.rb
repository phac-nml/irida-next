# frozen_string_literal: true

module Resolvers
  # Sample Attachments Resolver
  class SampleAttachmentsResolver < BaseResolver
    type [String], null: true

    alias sample object

    def resolve
      sample.attachments
    end
  end
end
