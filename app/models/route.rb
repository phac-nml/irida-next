# frozen_string_literal: true

# entity used to store fully qualified routes
class Route < ApplicationRecord
  self.implicit_order_column = 'created_at'

  acts_as_paranoid

  belongs_to :source, polymorphic: true, inverse_of: :route

  validates :path,
            length: { within: 1..255 },
            presence: true,
            uniqueness: { case_sensitive: false }

  after_update :rename_descendants

  scope :inside_path, ->(path) { where(Route.arel_table[:path].matches("#{path}/%")) }

  def rename_descendants # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return unless saved_change_to_path? || saved_change_to_name?

    descendant_routes = Route.inside_path(path_before_last_save)

    descendant_routes.each do |route|
      attributes = {}

      attributes[:path] = route.path.sub(path_before_last_save, path) if saved_change_to_path? && route.path.present?

      attributes[:name] = route.name.sub(name_before_last_save, name) if saved_change_to_name? && route.name.present?

      next if attributes.empty?

      # Skips Callbacks so that we can rename all descendants in one go
      route.update_columns(attributes.merge(updated_at: Time.current)) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def split_path_parts
    paths = []

    path.split('/').each_with_index do |_part, index|
      paths << path.split('/')[0..index].join('/')
    end

    paths
  end
end
