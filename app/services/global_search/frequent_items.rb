# frozen_string_literal: true

module GlobalSearch
  # Builds activity-based frequently visited projects and groups for the search dropdown.
  class FrequentItems < BaseService
    include Rails.application.routes.url_helpers

    DEFAULT_LIMIT = 5
    RECENT_ACTIVITY_MULTIPLIER = 6

    def initialize(user, limit: DEFAULT_LIMIT)
      super(user)
      @limit = limit
    end

    def call
      namespace_ids = recent_namespace_ids
      return { projects: [], groups: [] } if namespace_ids.empty?

      collections = collections_for(namespace_ids)
      collect_items(namespace_ids, collections)
    end

    private

    def collections_for(namespace_ids)
      projects_by_namespace_id = Project.where(namespace_id: namespace_ids)
                                        .includes(namespace: :route)
                                        .index_by(&:namespace_id)

      {
        namespaces: Namespace.where(id: namespace_ids).index_by(&:id),
        projects_by_namespace_id: projects_by_namespace_id,
        groups_by_id: Group.where(id: namespace_ids).includes(:route).index_by(&:id)
      }
    end

    def collect_items(namespace_ids, collections)
      projects = []
      groups = []

      namespace_ids.each do |namespace_id|
        append_namespace_item(namespace_id, collections, projects:, groups:)
        break if limits_reached?(projects, groups)
      end

      { projects: projects.first(@limit), groups: groups.first(@limit) }
    end

    def append_namespace_item(namespace_id, collections, projects:, groups:)
      namespace = collections[:namespaces][namespace_id]
      return unless namespace

      if project_namespace?(namespace)
        item = project_item(collections[:projects_by_namespace_id][namespace.id])
        projects << item if item
        return
      end

      return unless group_namespace?(namespace)

      item = group_item(collections[:groups_by_id][namespace.id])
      groups << item if item
    end

    def limits_reached?(projects, groups)
      projects.size >= @limit && groups.size >= @limit
    end

    def project_namespace?(namespace)
      namespace.type == Namespaces::ProjectNamespace.sti_name
    end

    def group_namespace?(namespace)
      namespace.type == Group.sti_name
    end

    def recent_namespace_ids
      return [] unless current_user

      PublicActivity::Activity
        .where(owner_type: 'User', owner_id: current_user.id, trackable_type: 'Namespace')
        .group(:trackable_id)
        .order(Arel.sql('MAX(created_at) DESC'), trackable_id: :desc)
        .limit(@limit * RECENT_ACTIVITY_MULTIPLIER)
        .pluck(:trackable_id)
    end

    def project_item(project)
      return nil unless project
      return nil unless allowed_to?(:read?, project)

      {
        title: project.name,
        subtitle: "#{project.puid} · #{project.full_path}",
        url: namespace_project_path(project.parent, project)
      }
    end

    def group_item(group)
      return nil unless group
      return nil unless allowed_to?(:read?, group)

      {
        title: group.name,
        subtitle: "#{group.puid} · #{group.full_path}",
        url: group_path(group)
      }
    end
  end
end
