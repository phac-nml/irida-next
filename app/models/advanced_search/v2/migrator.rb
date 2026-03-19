# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Converts a V1 groups_attributes param hash into a V2 query tree.
    # V1 semantics: OR between groups, AND within each group.
    class Migrator
      def self.from_v1(params)
        return nil if params.blank?
        return nil if params['groups_attributes'].blank?

        groups = params['groups_attributes'].values.filter_map { |g| build_group(g) }
        return nil if groups.empty?

        Tree::GroupNode.new(combinator: 'or', nodes: groups)
      end

      def self.build_group(group_hash)
        conditions = (group_hash['conditions_attributes'] || {}).values.filter_map { |c| build_condition(c) }
        return nil if conditions.empty?

        Tree::GroupNode.new(combinator: 'and', nodes: conditions)
      end

      def self.build_condition(cond)
        return nil if cond['field'].blank? && cond['operator'].blank? && cond['value'].blank?

        Tree::ConditionNode.new(field: cond['field'], operator: cond['operator'], value: cond['value'])
      end

      private_class_method :build_group, :build_condition
    end
  end
end
