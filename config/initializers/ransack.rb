# frozen_string_literal: true

# Do we actually need these?
Ransack.configure do |config|
  config.add_predicate 'dategteq',
                       arel_predicate: 'gteq',
                       formatter: proc { |v| v.beginning_of_day },
                       type: :date

  config.add_predicate 'datelteq',
                       arel_predicate: 'lteq',
                       formatter: proc { |v| v.end_of_day },
                       type: :date
end
