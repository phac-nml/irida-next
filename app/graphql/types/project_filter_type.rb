# frozen_string_literal: true

module Types
  # Project Filter Type
  class ProjectFilterType < BaseRansackFilterInputObject # rubocop:disable GraphQL/ObjectDescription
    Project.ransackable_attributes.excluding(DEFAULT_EXCLUDED_ATTRIBUTES).each do |attr|
      default_predicate_keys.map do |key|
        value_type = Ransack.predicates[key].wants_array ? [String] : String
        argument :"#{attr}_#{key}".to_sym,
                 value_type,
                 required: false,
                 camelize: false
      end
    end
  end
end
