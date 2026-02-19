# frozen_string_literal: true

module Resolvers
  # Samples Count Resolver
  class SamplesCountResolver < BaseResolver
    def resolve
      if object.is_a?(Project)
        object.samples_count.to_i
      elsif object.group_namespace?
        object.aggregated_samples_count.to_i
      end
    end
  end
end
