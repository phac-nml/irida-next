# frozen_string_literal: true

module Types
  # Bsse Ransack Filter Input Object
  class BaseRansackFilterInputObject < BaseInputObject
    DEFAULT_EXCLUDED_ATTRIBUTES = %w[id metadata deleted_at].freeze
    JSONB_PREDICATE_KEYS = %w[jcont jcont_all jcont_any jcont_key jcont_key_all jcont_key_any].freeze

    def self.default_predicate_keys
      Ransack.predicates.keys.excluding(JSONB_PREDICATE_KEYS)
    end
  end
end
