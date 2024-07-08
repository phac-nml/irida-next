# frozen_string_literal: true

# Concern to make a Model Routable
module Routable
  extend ActiveSupport::Concern

  def self.find_by_full_path(path, route_scope: Route)
    return unless path.present? # rubocop:disable Rails/Blank

    path = path.to_s

    route = route_scope.find_by(routes: { path: }) ||
            route_scope.find_by(path:)

    return unless route

    route.is_a?(Routable) ? route : route.source
  end

  included do
    has_one :route, as: :source, autosave: true, dependent: :destroy, inverse_of: :source

    validates :route, presence: true

    after_validation :set_path_errors

    before_validation :prepare_route
    before_save :prepare_route
  end

  class_methods do
    def find_by_full_path(path)
      Routable.find_by_full_path(
        path,
        route_scope: includes(:route).references(:routes)
      )
    end
  end

  def full_name
    route&.name || build_full_name
  end

  def full_path
    route&.path || build_full_path
  end

  def abbreviated_path
    new_path = []
    paths = route&.path&.split('/')
    paths.each do |path_part|
      new_path << if path_part == path
                    path_part
                  else
                    path_part[0]
                  end
    end
    new_path.join('/')
  end

  def build_full_path
    if parent && path
      "#{parent.full_path}/#{path}"
    else
      path
    end
  end

  private

  def set_path_errors
    route_path_errors = errors.delete(:'route.path')
    route_path_errors&.each do |msg|
      errors.add(:path, msg)
    end
  end

  def build_full_name
    if parent && name
      "#{parent.human_name} / #{name}"
    else
      name
    end
  end

  def prepare_route
    route || build_route(source: self)
    route.path = build_full_path
    route.name = build_full_name
  end
end
