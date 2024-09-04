# frozen_string_literal: true

module Types
  class OrderDirectionType < BaseEnum # rubocop:disable Style/Documentation
    description 'Sort by the specified order'
    value :asc
    value :desc
  end
end
