# frozen_string_literal: true

# This is a developer-facing CLI benchmark script (invoked via
# `bin/rails benchmark:namespace_traversal`), not application/request code,
# so printing results directly to stdout is intentional here.
# rubocop:disable Rails/Output

require 'benchmark/ips'
require 'securerandom'

module Benchmarks
  # Builds a synthetic namespace hierarchy and benchmarks the RouteBased vs
  # Linear namespace traversal strategies (see
  # app/models/namespaces/traversal/route_based.rb and
  # app/models/namespaces/traversal/linear.rb) against it.
  #
  # All data created for the benchmark is created and rolled back inside a
  # single transaction, so this is safe to run against any environment's
  # database without leaving data behind.
  class NamespaceTraversal
    def self.run(depth:, children_per_level:)
      new(depth:, children_per_level:).run
    end

    def initialize(depth:, children_per_level:)
      @depth = depth
      @children_per_level = children_per_level
    end

    def run
      ActiveRecord::Base.transaction do
        build_hierarchy
        report_hierarchy_size
        benchmark_ancestors
        benchmark_descendants
        benchmark_scopes
        raise ActiveRecord::Rollback
      end
    end

    private

    attr_reader :depth, :children_per_level, :root, :deepest_leaf, :scope_sample

    # Builds a hierarchy `depth` levels deep under `root`. At every level,
    # `children_per_level` sibling groups are created under the previous
    # level's chosen parent, but only the first sibling is descended into
    # further - this keeps the total number of namespaces created linear in
    # depth * children_per_level (rather than exponential), while still
    # giving `root`'s descendants query a realistically large result set to
    # traverse.
    #
    # Also builds a handful of smaller, independent sibling branches off
    # `root` (`scope_sample`) - mutually unrelated namespaces (none is an
    # ancestor/descendant of another) that each have their own real
    # descendants, used to benchmark the class-level `self_and_descendants`/
    # `without_descendants` scopes against a multi-row base relation.
    def build_hierarchy
      puts "Building synthetic hierarchy (depth=#{depth}, children per level=#{children_per_level})..."

      @root = Group.create!(name: 'Benchmark Root', path: "benchmark-root-#{SecureRandom.hex(4)}")
      @deepest_leaf = build_branch(root, depth)

      scope_branch_depth = [depth / 2, 1].max
      branch_heads = Array.new(3) do |i|
        branch_root = Group.create!(
          name: "Benchmark Branch #{i}", path: "benchmark-branch-#{i}-#{SecureRandom.hex(4)}", parent: root
        )
        build_branch(branch_root, scope_branch_depth)
        branch_root
      end
      @scope_sample = Group.where(id: branch_heads.map(&:id))
    end

    # Builds a chain `levels` deep starting at `start_parent`, creating
    # `children_per_level` sibling groups at each level but only descending
    # further into the first sibling. Returns the deepest descended-into
    # group.
    def build_branch(start_parent, levels)
      parent = start_parent

      levels.times do |level|
        siblings = Array.new(children_per_level) do |i|
          Group.create!(
            name: "Benchmark #{start_parent.id} L#{level} G#{i}",
            path: "benchmark-#{SecureRandom.hex(4)}-l#{level}-g#{i}",
            parent:
          )
        end

        parent = siblings.first
      end

      parent
    end

    def report_hierarchy_size
      puts "Total namespaces created: #{root.self_and_descendants.count}"
      puts "Deepest leaf ancestor count: #{deepest_leaf.ancestor_ids.size}"
      puts
    end

    def benchmark_ancestors
      puts '--- ancestors / self_and_ancestors (from deepest leaf) ---'
      benchmark_methods(deepest_leaf, %w[ancestors self_and_ancestors])
    end

    def benchmark_descendants
      puts '--- descendants / self_and_descendants (from root) ---'
      benchmark_methods(root, %w[descendants self_and_descendants])
    end

    # Benchmarks the class-level `self_and_descendants`/`without_descendants`
    # scopes directly against a multi-row base relation, as opposed to
    # `benchmark_descendants` above which only exercises them indirectly via
    # single-namespace instance method delegation.
    def benchmark_scopes
      puts "--- self_and_descendants / without_descendants scopes (multi-row base, #{scope_sample.count} rows) ---"
      benchmark_scope_methods(scope_sample, %w[self_and_descendants without_descendants])
    end

    # Benchmarks the `route_based_<method_name>` (routes join) and bare
    # `<method_name>` (traversal_ids - Linear is the default implementation
    # for bare method names) variants of each given method name against
    # `namespace`, reporting a single iterations-per-second comparison
    # across all of them.
    def benchmark_methods(namespace, method_names)
      Benchmark.ips do |x|
        method_names.each do |method_name|
          x.report("route_based #{method_name}") { namespace.public_send(:"route_based_#{method_name}").load }
          x.report("linear #{method_name}") { namespace.public_send(method_name).load }
        end

        x.compare!
      end
      puts
    end

    # Same as `benchmark_methods`, but for class-level scopes invoked on a
    # relation (e.g. `Group.where(...).self_and_descendants`) rather than
    # instance methods invoked on a single namespace.
    def benchmark_scope_methods(relation, method_names)
      Benchmark.ips do |x|
        method_names.each do |method_name|
          x.report("route_based #{method_name}") { relation.public_send(:"route_based_#{method_name}").load }
          x.report("linear #{method_name}") { relation.public_send(method_name).load }
        end

        x.compare!
      end
      puts
    end
  end
end
# rubocop:enable Rails/Output
