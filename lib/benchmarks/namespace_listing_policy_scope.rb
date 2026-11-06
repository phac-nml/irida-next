# frozen_string_literal: true

# This is a developer-facing CLI benchmark script (invoked via
# `bin/rails benchmark:namespace_listing_policy_scope`), not
# application/request code, so printing results directly to stdout is
# intentional here.
# rubocop:disable Rails/Output

require 'benchmark/ips'
require 'securerandom'

module Benchmarks
  # Builds several distinct, deeply branching group hierarchies ("trees")
  # with namespace group links scattered across levels and across trees
  # (some granting a benchmark user access to namespaces in other
  # hierarchies), then benchmarks GroupPolicy's and ProjectPolicy's relation
  # listing scopes (ultimately NamespacePolicy#scope_for(:relation), see
  # app/policies/namespace_policy.rb) with use_traversal_ids: true
  # (traversal_ids array overlap) vs use_traversal_ids: false (legacy
  # route-based self_and_descendants), exercising the actual application
  # code for both strategies.
  #
  # All data created for the benchmark is rolled back at the end via a
  # wrapping transaction.
  class NamespaceListingPolicyScope # rubocop:disable Metrics/ClassLength
    Tree = Struct.new(:root, :nodes_by_level, :leaves)

    def self.run(trees_count:, depth:, children_per_level:, links_count:, users_count:, strategy:) # rubocop:disable Metrics/ParameterLists
      new(trees_count:, depth:, children_per_level:, links_count:, users_count:, strategy:).run
    end

    def initialize(trees_count:, depth:, children_per_level:, links_count:, users_count:, strategy:) # rubocop:disable Metrics/ParameterLists
      @trees_count = trees_count
      @depth = depth
      @children_per_level = children_per_level
      @links_count = links_count
      @users_count = users_count
      @strategy = strategy
    end

    def run
      ActiveRecord::Base.transaction do
        build_forest
        build_project_namespaces
        build_benchmark_user
        build_filler_members
        build_namespace_group_links
        report_setup_size
        benchmark_group_scope
        benchmark_project_scope
        raise ActiveRecord::Rollback
      end
    end

    private

    attr_reader :trees_count, :depth, :children_per_level, :links_count, :users_count, :strategy,
                :trees, :benchmark_user, :created_members_count, :created_links_count

    # Builds `trees_count` independent, fully-branching group hierarchies,
    # each `depth` levels deep (root included) with `children_per_level`
    # children per node - unlike the chain/sibling-fan shapes used by the
    # other benchmarks, every node here has real children, so that
    # memberships and namespace group links can be scattered across
    # genuinely distinct branches at every level.
    def build_forest
      puts "Building #{trees_count} branching hierarchies " \
           "(depth=#{depth}, children per level=#{children_per_level})..."

      @trees = Array.new(trees_count) { |i| build_tree(i) }
    end

    def build_tree(index)
      root = Group.create!(name: "Listing Benchmark Tree#{index} Root",
                           path: "lb-t#{index}-root-#{SecureRandom.hex(4)}")
      nodes_by_level = [[root]]

      (depth - 1).times do |level|
        nodes_by_level << nodes_by_level.last.flat_map do |parent|
          Array.new(children_per_level) do |i|
            Group.create!(
              name: "Listing Benchmark Tree#{index} L#{level + 1} G#{i}",
              path: "lb-t#{index}-l#{level + 1}-#{SecureRandom.hex(4)}",
              parent:
            )
          end
        end
      end

      Tree.new(root, nodes_by_level, nodes_by_level.last)
    end

    # Attaches a project namespace (and project) under a sample of leaves in
    # every tree (one in ten), rather than every leaf, to keep the dataset
    # size reasonable while still giving ProjectPolicy's scope real project
    # rows to filter at every tree's bottom level.
    def build_project_namespaces
      sampled_leaves = trees.flat_map { |tree| tree.leaves.each_slice(10).map(&:first) }
      puts "Creating #{sampled_leaves.size} project namespaces across #{trees_count} trees..."

      sampled_leaves.each_with_index do |leaf, i|
        project = Project.new(creator: owner)
        project.build_namespace(
          name: "Listing Benchmark Project#{i}", path: "lb-proj-#{i}-#{SecureRandom.hex(4)}",
          parent: leaf, owner:
        )
        project.save!
      end
    end

    def owner
      @owner ||= create_benchmark_user('owner')
    end

    # Creates the user whose access we actually benchmark: direct membership
    # at one node per level of the first tree (so the own-namespaces CTE
    # spans the whole depth of a single hierarchy), used as the subject of
    # every `apply_scope` call below.
    def build_benchmark_user
      @benchmark_user = create_benchmark_user('subject')
      @created_members_count = 0

      trees.first.nodes_by_level.each do |level_nodes|
        Member.create!(
          user: benchmark_user, namespace: level_nodes.sample, created_by: owner,
          access_level: Member::AccessLevel::MAINTAINER
        )
        @created_members_count += 1
      end
    end

    # Spreads `users_count` memberships across random nodes of random trees
    # - this is noise data representing realistic membership density; it
    # does not affect the benchmark user's own result set, but gives the
    # DISTINCT ON user_id / traversal_ids array-overlap queries a realistic
    # amount of unrelated data to filter through.
    def build_filler_members
      puts "Creating #{users_count} filler members across #{trees_count} trees..."

      users_count.times do |i|
        user = create_benchmark_user("filler#{i}")
        Member.create!(
          user:, namespace: random_node, created_by: owner,
          access_level: Member::AccessLevel::MAINTAINER
        )
        @created_members_count += 1
      end
    end

    # Creates `links_count` namespace group links, with the target namespace
    # scattered across every tree and every level. One link in `trees_count`
    # is "real" - its group is one of the benchmark user's own membership
    # nodes, granting them cross-hierarchy access to a node in a different
    # tree - the rest link unrelated, randomly chosen groups, adding
    # realistic noise rows that the benchmark user cannot see through.
    def build_namespace_group_links
      puts "Creating #{links_count} namespace group links across #{trees_count} trees..."
      own_nodes = benchmark_user.members.pluck(:namespace_id)
      used_pairs = Set.new
      @created_links_count = 0

      links_count.times do |i|
        group, namespace = unique_namespace_group_link_pair(i, own_nodes, used_pairs)
        NamespaceGroupLink.create!(group:, namespace:, group_access_level: Member::AccessLevel::MAINTAINER)
        @created_links_count += 1
      end
    end

    # Retries `namespace_group_link_pair` until it returns a (group,
    # namespace) pair not already used - small trees have a limited number
    # of nodes, so the same random pair can otherwise be drawn more than
    # once, which NamespaceGroupLink's uniqueness validation rejects.
    def unique_namespace_group_link_pair(index, own_nodes, used_pairs)
      loop do
        group, namespace = namespace_group_link_pair(index, own_nodes)
        pair = [group.id, namespace.id]
        next if used_pairs.include?(pair)

        used_pairs << pair
        return [group, namespace]
      end
    end

    # Picks the (group, namespace) pair for namespace group link `i`. One
    # link in `trees_count` is "real" - its group is one of the benchmark
    # user's own nodes (all in tree 0), target is a non-root node in a
    # *different* tree (excluding the root keeps the grant scoped to a
    # sub-branch rather than accidentally handing out the whole tree) -
    # this both grants genuine, scattered cross-hierarchy access and
    # guarantees group and namespace can never be the same node. The rest
    # link unrelated, randomly chosen groups (also excluding tree 0, so
    # they can never coincide with the benchmark user's own access) to a
    # node in a different tree, adding realistic noise rows that the
    # benchmark user cannot see through.
    def namespace_group_link_pair(index, own_nodes)
      if (index % trees_count).zero?
        group = Namespace.find(own_nodes.sample)
        namespace = random_node(except_tree_indices: [0], exclude_root: true)
      else
        target_tree_index = index % trees_count
        namespace = random_node(tree_index: target_tree_index)
        group = random_node(except_tree_indices: [0, target_tree_index])
      end

      group = random_node(except_tree_indices: [0]) while group == namespace
      [group, namespace]
    end

    # Picks a random group node from a random level, optionally restricted
    # to a specific tree, excluded from one or more trees, and/or excluded
    # from the root level. Falls back to any tree (ignoring exclusions) if
    # the given constraints would leave no candidates (e.g. a small/
    # single-tree setup).
    def random_node(tree_index: nil, except_tree_indices: [], exclude_root: false)
      tree = candidate_trees(tree_index, except_tree_indices).sample
      levels = exclude_root ? tree.nodes_by_level.drop(1) : tree.nodes_by_level
      levels = tree.nodes_by_level if levels.empty?
      levels.sample.sample
    end

    def candidate_trees(tree_index, except_tree_indices)
      return [trees[tree_index]] if tree_index

      if except_tree_indices.any?
        candidates = trees.each_with_index.reject { |_, i| except_tree_indices.include?(i) }.map(&:first)
        return candidates if candidates.any?
      end

      trees
    end

    def create_benchmark_user(label)
      User.create!(
        first_name: 'Benchmark', last_name: label,
        email: "benchmark-listing-#{label}-#{SecureRandom.hex(4)}@example.com",
        password: 'password1'
      )
    end

    def report_setup_size
      total_groups = trees.sum { |tree| tree.nodes_by_level.flatten.size }
      puts "Total groups created: #{total_groups} (#{trees_count} trees)"
      puts "Memberships created: #{created_members_count}, namespace group links created: #{created_links_count}"
      puts
    end

    def benchmark_group_scope
      puts '--- GroupPolicy relation scope ---'
      policy = GroupPolicy.new(user: benchmark_user)
      report_result_counts(policy, Group)

      action = lambda { |use_traversal_ids|
        policy.apply_scope(Group, type: :relation, scope_options: { use_traversal_ids: }).load
      }
      benchmark_strategies(&action)
    end

    def benchmark_project_scope
      puts '--- ProjectPolicy relation scope ---'
      policy = ProjectPolicy.new(user: benchmark_user)
      report_result_counts(policy, Project)

      action = lambda { |use_traversal_ids|
        policy.apply_scope(Project, type: :relation, scope_options: { use_traversal_ids: }).load
      }
      benchmark_strategies(&action)
    end

    # Sanity-checks both strategies return the same result set before
    # benchmarking their performance.
    def report_result_counts(policy, klass)
      traversal_ids_count = policy.apply_scope(klass, type: :relation, scope_options: { use_traversal_ids: true }).count
      route_based_count = policy.apply_scope(klass, type: :relation, scope_options: { use_traversal_ids: false }).count
      puts "Accessible #{klass.name.downcase}s: #{traversal_ids_count} (traversal_ids), " \
           "#{route_based_count} (route-based)"
    end

    # Runs the given block (which takes a use_traversal_ids argument) through
    # Benchmark.ips for whichever of the `old`/`new` strategies are selected
    # by `strategy` (`:old`, `:new`, or `:both`, the default), reporting a
    # relative comparison when both are run.
    def benchmark_strategies(&block)
      Benchmark.ips do |x|
        x.report('old (route-based self_and_descendants)') { block.call(false) } if %i[old both].include?(strategy)

        x.report('new (traversal_ids self_and_descendants)') { block.call(true) } if %i[new both].include?(strategy)

        x.compare! if strategy == :both
      end
      puts
    end
  end
end
# rubocop:enable Rails/Output
