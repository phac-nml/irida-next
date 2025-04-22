# frozen_string_literal: true

PublicActivity::Activity.class_eval do
  serialize :parameters, coder: YAML, type: Hash unless %i[json jsonb hstore].include?(columns_hash['parameters'].type)

  has_one :activity_extended_detail
  has_one :extended_details, through: :activity_extended_detail, source: :extended_detail
end
