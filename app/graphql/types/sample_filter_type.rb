# frozen_string_literal: true

module Types
  # Sample Filter Type
  class SampleFilterType < BaseInputObject # rubocop:disable GraphQL/ObjectDescription
    Sample.ransackable_attributes.each do |attr|
      Ransack.predicates.keys.map do |key|
        value_type = Ransack.predicates[key].wants_array ? [String] : String
        argument :"#{attr}_#{key}".to_sym,
                 value_type,
                 required: false,
                 camelize: false
      end
    end
  end
end
