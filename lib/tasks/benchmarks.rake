# frozen_string_literal: true

namespace :benchmark do # rubocop:disable Metrics/BlockLength
  desc 'Benchmark NamespaceRowPresenter.build_collection (batched/memoized) vs a naive per-row ' \
       'implementation by issuing real HTTP requests through the groups dashboard, a group show ' \
       'page and the projects dashboard (respecting Pagy\'s default 20-item page limit), against a ' \
       'synthetic forest of branching group hierarchies with project namespaces and scattered ' \
       'namespace group links. ' \
       'Options (env vars): TREES (default 25, number of distinct hierarchies - keep above the Pagy ' \
       'page limit so the dashboard is realistically paginated), ' \
       'DEPTH (default 3, levels per hierarchy including root), ' \
       'CHILDREN (default 3, children per node), ' \
       'PROJECTS (default 2, project namespaces per leaf group), ' \
       'ROOT_EXTRA_PROJECTS (default 25, extra project namespaces attached directly to the first ' \
       'tree\'s root, so its show page is also realistically paginated), ' \
       'LINKS (default 150, namespace group links created), ' \
       'STRATEGY (old|new|both, default both).'
  task namespace_row_rendering: :environment do
    require_relative '../benchmarks/namespace_row_rendering'

    strategy = (ENV['STRATEGY'] || 'both').to_sym
    raise ArgumentError, "STRATEGY must be old|new|both, got #{strategy}" unless %i[old new both].include?(strategy)

    Benchmarks::NamespaceRowRendering.run(
      trees_count: (ENV['TREES'] || 25).to_i,
      depth: (ENV['DEPTH'] || 3).to_i,
      children_per_level: (ENV['CHILDREN'] || 3).to_i,
      projects_per_leaf: (ENV['PROJECTS'] || 2).to_i,
      root_extra_projects: (ENV['ROOT_EXTRA_PROJECTS'] || 25).to_i,
      links_count: (ENV['LINKS'] || 150).to_i,
      strategy:
    )
  end
end
