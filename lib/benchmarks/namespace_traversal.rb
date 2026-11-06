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
        raise ActiveRecord::Rollback
      end
    end

    private

    attr_reader :depth, :children_per_level, :root, :deepest_leaf

    # Builds a hierarchy `depth` levels deep. At every level, `children_per_level`
    # sibling groups are created under the previous level's chosen parent, but
    # only the first sibling is descended into further - this keeps the total
    # number of namespaces created linear in depth * children_per_level
    # (rather than exponential), while still giving `root`'s descendants
    # query a realistically large result set to traverse.
    def build_hierarchy
      puts "Building synthetic hierarchy (depth=#{depth}, children per level=#{children_per_level})..."

      @root = Group.create!(name: 'Benchmark Root', path: "benchmark-root-#{SecureRandom.hex(4)}")
      parent = @root

      depth.times do |level|
        siblings = Array.new(children_per_level) do |i|
          Group.create!(
            name: "Benchmark L#{level} G#{i}",
            path: "benchmark-l#{level}-g#{i}-#{SecureRandom.hex(4)}",
            parent:
          )
        end

        parent = siblings.first
      end

      @deepest_leaf = parent
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
  end
end
# rubocop:enable Rails/Output
