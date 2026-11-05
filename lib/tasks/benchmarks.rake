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
end
