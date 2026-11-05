# frozen_string_literal: true

namespace :benchmark do
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
end
