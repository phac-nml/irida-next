# frozen_string_literal: true

module Types
  # Group Filter Type
  class GroupFilterType < BaseInputObject # rubocop:disable GraphQL/ObjectDescription
    Group.ransackable_attributes.excluding(%w[id deleted_at]).each do |attr|
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
