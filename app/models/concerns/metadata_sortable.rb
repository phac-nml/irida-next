# frozen_string_literal: true

# Concern for models that have sorting metadata logic
module MetadataSortable
  extend ActiveSupport::Concern

  included do
    def self.metadata_sort(field, dir)
      metadata_field = Arel::Nodes::InfixOperation.new(
        'collate',
        Arel::Nodes::InfixOperation.new(
          '->>',
          arel_table[:metadata],
          Arel::Nodes.build_quoted(field)
        ),
        Arel::Nodes::SqlLiteral.new('numeric')
      )

      if dir.to_sym == :asc
        metadata_field.asc
      else
        metadata_field.desc
      end
    end
  end
end
