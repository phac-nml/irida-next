# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Converts a V1 groups_attributes param hash into a V2 query tree.
    # V1 semantics: OR between groups, AND within each group.
    class Migrator
      def self.from_v1(params)
        return nil if params.blank?

        groups_attributes = attribute_value(params, :groups_attributes)
        return nil unless attribute_collection?(groups_attributes)

        groups = groups_attributes.values.filter_map { |g| build_group(g) }
        return nil if groups.empty?

        Tree::GroupNode.new(combinator: 'or', nodes: groups)
      end

      def self.build_group(group_hash)
        conditions_attributes = attribute_value(group_hash, :conditions_attributes)
        return nil unless attribute_collection?(conditions_attributes)

        conditions = conditions_attributes.values.filter_map { |c| build_condition(c) }
        return nil if conditions.empty?

        Tree::GroupNode.new(combinator: 'and', nodes: conditions)
      end

      def self.build_condition(cond)
        field = attribute_value(cond, :field)
        operator = FieldConfiguration.normalize_operator(attribute_value(cond, :operator))
        value = attribute_value(cond, :value)
        return nil if field.blank? && operator.blank? && value.blank?

        Tree::ConditionNode.new(field:, operator:, value:)
      end

      def self.attribute_value(hash, key)
        return nil unless hash.respond_to?(:key?)

        return hash[key] if hash.key?(key)

        string_key = key.to_s
        return hash[string_key] if hash.key?(string_key)

        symbol_key = key.to_sym
        return hash[symbol_key] if hash.key?(symbol_key)

        nil
      end

      def self.attribute_collection?(value)
        value.respond_to?(:key?) && value.respond_to?(:values)
      end

      private_class_method :build_group, :build_condition, :attribute_value, :attribute_collection?
    end
  end
end
