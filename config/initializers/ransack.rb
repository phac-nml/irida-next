# frozen_string_literal: true

module Arel
  module Predications # rubocop:disable Style/Documentation
    def contains_key(other)
      Arel::Nodes::InfixOperation.new(:'?', self, Arel::Nodes::Quoted.new(other))
    end

    # contains but case insensitive
    def contains_ci(other)
      Arel::Nodes::Contains.new(
        Arel::Nodes::SqlLiteral.new("lower(\"#{relation.name}\".\"#{name}\"::text)::jsonb"),
        Arel::Nodes.build_quoted(other, self)
      )
    end
  end
end

Ransack.configure do |config|
  config.add_predicate 'jcont', arel_predicate: 'contains_ci', formatter: proc { |v| JSON.parse(v.to_s.downcase) }
  config.add_predicate 'jcont_key', arel_predicate: 'contains_key', formatter: proc { |v| v.to_s.downcase }
end
