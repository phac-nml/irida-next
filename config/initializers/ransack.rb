# frozen_string_literal: true

module Arel
  module Predications # rubocop:disable Style/Documentation
    def contains_key(other)
      Arel::Nodes::InfixOperation.new(:'?', self, Arel::Nodes::Quoted.new(other))
    end
  end
end

Ransack.configure do |config|
  config.add_predicate 'jcont', arel_predicate: 'contains', formatter: proc { |v| JSON.parse(v.to_s) }
  config.add_predicate 'jcont_key', arel_predicate: 'contains_key'
end
