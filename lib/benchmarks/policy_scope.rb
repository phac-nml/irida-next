# frozen_string_literal: true

# This is a developer-facing CLI benchmark script (invoked via
# `bin/rails benchmark:policy_scope`), not application/request code, so
# printing results directly to stdout is intentional here.
# rubocop:disable Rails/Output

require 'benchmark/ips'
require 'securerandom'

module Benchmarks
  # Builds a synthetic namespace hierarchy with members and namespace group
  # links scattered across its levels, then benchmarks MemberPolicy's and
  # NamespaceGroupLinkPolicy's relation scopes with use_traversal_ids: true
  # (traversal_ids - no routes join) vs use_traversal_ids: false (legacy
  # routes join + ORDER BY routes.path), exercising the actual application
  # code for both strategies (see app/policies/member_policy.rb and
  # app/policies/namespace_group_link_policy.rb).
  #
  # All data created for the benchmark is rolled back at the end via a
  # wrapping transaction.
  class PolicyScope # rubocop:disable Metrics/ClassLength
    def self.run(depth:, users_count:, links_count:, strategy:)
      new(depth:, users_count:, links_count:, strategy:).run
    end

    def initialize(depth:, users_count:, links_count:, strategy:)
      @depth = depth
      @users_count = users_count
      @links_count = links_count
      @strategy = strategy
    end

    def run
      ActiveRecord::Base.transaction do
        build_hierarchy
        build_members
        build_namespace_group_links
        report_setup_size
        benchmark_member_scope
        benchmark_namespace_group_link_scope
        benchmark_top_level_ancestor_lookup
        raise ActiveRecord::Rollback
      end
    end

    private

    attr_reader :depth, :users_count, :links_count, :strategy,
                :root, :deepest_leaf, :deepest_project_namespace, :levels, :created_by

    # Builds a single linear chain of groups `depth` levels deep (no
    # branching) - the benchmarked queries only care about how many
    # namespace_ids are in the ancestor chain being searched, not about the
    # overall hierarchy's breadth, so a chain is enough and keeps setup fast.
    #
    # Also creates a project namespace leaf under the deepest group, so the
    # scopes can be benchmarked against both a group namespace and a project
    # namespace - the latter is where resolving the ancestor chain from the
    # in-memory traversal_ids (vs a parent load plus an ancestor query)
    # saves the most round-trips.
    def build_hierarchy
      puts "Building synthetic hierarchy (depth=#{depth})..."

      @created_by = create_benchmark_user('creator')
      @root = Group.create!(name: 'Policy Scope Benchmark Root', path: "ps-root-#{SecureRandom.hex(4)}")
      @levels = [@root]

      build_remaining_levels

      @deepest_leaf = levels.last
      @deepest_project_namespace = Namespaces::ProjectNamespace.create!(
        name: 'Policy Scope Benchmark Project', path: "ps-proj-#{SecureRandom.hex(4)}",
        parent: deepest_leaf, owner: created_by
      )
    end

    def build_remaining_levels
      (depth - 1).times do |level|
        child = Group.create!(
          name: "Policy Scope Benchmark L#{level}",
          path: "ps-l#{level}-#{SecureRandom.hex(4)}",
          parent: levels.last
        )
        levels << child
      end
    end

    # Spreads `users_count` memberships evenly across every level of the
    # hierarchy, each belonging to a distinct user, so the DISTINCT ON
    # user_id query has real de-duplication work to do.
    def build_members
      puts "Creating #{users_count} members across #{levels.size} levels..."

      users_count.times do |i|
        user = create_benchmark_user("user#{i}")
        namespace = levels[i % levels.size]

        Member.create!(
          user:, namespace:, created_by:,
          access_level: Member::AccessLevel::MAINTAINER
        )
      end
    end

    def create_benchmark_user(label)
      User.create!(
        first_name: 'Benchmark', last_name: label,
        email: "benchmark-#{label}-#{SecureRandom.hex(4)}@example.com",
        password: 'password1'
      )
    end

    # Spreads `links_count` namespace group links evenly across every level
    # of the hierarchy, each from a distinct "linking" group, so the
    # DISTINCT ON group_id query has real de-duplication work to do.
    def build_namespace_group_links
      puts "Creating #{links_count} namespace group links across #{levels.size} levels..."

      links_count.times do |i|
        linking_group = Group.create!(
          name: "Policy Scope Benchmark Linking Group#{i}",
          path: "policy-scope-linking-group-#{i}-#{SecureRandom.hex(4)}"
        )
        namespace = levels[i % levels.size]

        NamespaceGroupLink.create!(
          group: linking_group, namespace:,
          group_access_level: Member::AccessLevel::MAINTAINER
        )
      end
    end

    def report_setup_size
      puts "Deepest leaf ancestor count: #{deepest_leaf.self_and_ancestor_ids.size}"
      puts
    end

    def benchmark_member_scope
      benchmark_member_scope_for('group namespace', deepest_leaf)
      benchmark_member_scope_for('project namespace', deepest_project_namespace)
    end

    def benchmark_member_scope_for(label, namespace)
      puts "--- MemberPolicy relation scope (DISTINCT ON user_id), #{label} ---"
      policy = MemberPolicy.new(user: created_by)
      action = lambda { |use_traversal_ids|
        policy.apply_scope(
          Member, type: :relation,
                  scope_options: { namespace:, use_traversal_ids: }
        ).load
      }

      benchmark_strategies(&action)
    end

    def benchmark_namespace_group_link_scope
      benchmark_namespace_group_link_scope_for('group namespace', deepest_leaf)
      benchmark_namespace_group_link_scope_for('project namespace', deepest_project_namespace)
    end

    def benchmark_namespace_group_link_scope_for(label, namespace)
      puts "--- NamespaceGroupLinkPolicy relation scope (DISTINCT ON group_id), #{label} ---"
      policy = NamespaceGroupLinkPolicy.new(user: created_by)
      action = lambda { |use_traversal_ids|
        policy.apply_scope(
          NamespaceGroupLink, type: :relation,
                              scope_options: { namespace:, use_traversal_ids: }
        ).load
      }

      benchmark_strategies(&action)
    end

    # Runs the given block (which takes a use_traversal_ids argument) through
    # Benchmark.ips for whichever of the `old`/`new` strategies are selected
    # by `strategy` (`:old`, `:new`, or `:both`, the default), reporting a
    # relative comparison when both are run.
    def benchmark_strategies(&block)
      Benchmark.ips do |x|
        x.report('old (routes join + ORDER BY routes.path)') { block.call(false) } if %i[old both].include?(strategy)

        x.report('new (ORDER BY CARDINALITY(traversal_ids))') { block.call(true) } if %i[new both].include?(strategy)

        x.compare! if strategy == :both
      end
      puts
    end

    # Benchmarks ProjectPolicy's `project_samples_transferable` scope's
    # top-level group ancestor lookup (`top_level_group_ancestor` in
    # app/policies/project_policy.rb): old (`self_and_ancestors.find_by(type:
    # Group.sti_name, parent: nil)`, a query walking the whole ancestor
    # chain) vs new (`Group.find(traversal_ids.first)`, a direct primary-key
    # lookup using the id already held in memory).
    def benchmark_top_level_ancestor_lookup
      benchmark_top_level_ancestor_lookup_for('group namespace', deepest_leaf)
      benchmark_top_level_ancestor_lookup_for('project namespace', deepest_project_namespace)
    end

    def benchmark_top_level_ancestor_lookup_for(label, namespace) # rubocop:disable Metrics/MethodLength
      puts "--- ProjectPolicy top-level group ancestor lookup, #{label} ---"
      base = namespace.project_namespace? ? namespace.parent : namespace

      Benchmark.ips do |x|
        if %i[old both].include?(strategy)
          x.report('old (self_and_ancestors.find_by)') do
            base.self_and_ancestors.find_by(type: Group.sti_name, parent: nil)
          end
        end

        if %i[new both].include?(strategy)
          x.report('new (Group.find(traversal_ids.first))') do
            Group.find(base.traversal_ids.first)
          end
        end

        x.compare! if strategy == :both
      end
      puts
    end
  end
end
# rubocop:enable Rails/Output
