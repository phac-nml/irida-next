# frozen_string_literal: true

module Types
  # Sample Filter Type
  class SampleFilterType < BaseInputObject # rubocop:disable GraphQL/ObjectDescription
    Sample.ransackable_attributes.each do |attr|
      Ransack.predicates.keys.map do |predicate, value|
        value_type = value&.wants_array ? [String] : String
        argument :"#{attr}_#{predicate}".to_sym,
                 value_type,
                 required: false,
                 camelize: false
      end
    end
  end
end
