# frozen_string_literal: true

namespace :benchmark do # rubocop:disable Metrics/BlockLength
  desc 'Benchmark RouteBased vs Linear namespace traversal against a synthetic hierarchy. ' \
       'Options (env vars): DEPTH (default 9, capped by Namespace::MAX_ANCESTORS), ' \
       'CHILDREN (default 20, groups per level).'
  task namespace_traversal: :environment do
    require_relative '../benchmarks/namespace_traversal'

    Benchmarks::NamespaceTraversal.run(
      depth: (ENV['DEPTH'] || (Namespace::MAX_ANCESTORS - 1)).to_i,
      children_per_level: (ENV['CHILDREN'] || 20).to_i
    )
  end

  desc 'Benchmark old (routes join) vs new (traversal_ids) MemberPolicy/NamespaceGroupLinkPolicy ' \
       'relation scope queries against a synthetic hierarchy. ' \
       'Options (env vars): DEPTH (default 9, capped by Namespace::MAX_ANCESTORS), ' \
       'USERS (default 200, members created), LINKS (default 200, namespace group links created), ' \
       'STRATEGY (old|new|both, default both).'
  task policy_scope: :environment do
    require_relative '../benchmarks/policy_scope'

    strategy = (ENV['STRATEGY'] || 'both').to_sym
    raise ArgumentError, "STRATEGY must be old|new|both, got #{strategy}" unless %i[old new both].include?(strategy)

    Benchmarks::PolicyScope.run(
      depth: (ENV['DEPTH'] || (Namespace::MAX_ANCESTORS - 1)).to_i,
      users_count: (ENV['USERS'] || 200).to_i,
      links_count: (ENV['LINKS'] || 200).to_i,
      strategy:
    )
  end

  desc 'Benchmark old (route-based) vs new (traversal_ids) GroupPolicy/ProjectPolicy relation ' \
       'listing scopes against several distinct branching hierarchies with scattered namespace group links. ' \
       'Options (env vars): TREES (default 5, number of distinct hierarchies), ' \
       'DEPTH (default 4, levels per hierarchy including root), ' \
       'CHILDREN (default 10, children per node), ' \
       'LINKS (default 300, namespace group links created), ' \
       'USERS (default 200, filler members created), ' \
       'STRATEGY (old|new|both, default both).'
  task namespace_listing_policy_scope: :environment do
    require_relative '../benchmarks/namespace_listing_policy_scope'

    strategy = (ENV['STRATEGY'] || 'both').to_sym
    raise ArgumentError, "STRATEGY must be old|new|both, got #{strategy}" unless %i[old new both].include?(strategy)

    Benchmarks::NamespaceListingPolicyScope.run(
      trees_count: (ENV['TREES'] || 5).to_i,
      depth: (ENV['DEPTH'] || 4).to_i,
      children_per_level: (ENV['CHILDREN'] || 10).to_i,
      links_count: (ENV['LINKS'] || 300).to_i,
      users_count: (ENV['USERS'] || 200).to_i,
      strategy:
    )
  end
end
