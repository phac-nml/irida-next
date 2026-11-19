# frozen_string_literal: true

# This is a developer-facing CLI benchmark script (invoked via
# `bin/rails benchmark:namespace_row_rendering`), not application/request
# code, so printing results directly to stdout is intentional here.
# rubocop:disable Rails/Output

require 'benchmark/ips'
require 'securerandom'

module Benchmarks
  # Builds several distinct, branching group hierarchies ("trees") with
  # project namespaces at their leaves and namespace group links scattered
  # across levels and across trees (so a group's "shared" samples can come
  # from a completely different hierarchy), then issues *real* HTTP
  # requests - through the actual controllers, views and `pagy()` calls,
  # exactly as a browser would - against the three real call sites
  # `NamespaceRowPresenter.build_collection` covers: the groups dashboard,
  # a group's show page, and the projects dashboard.
  #
  # Each page is benchmarked twice per request: once with the current
  # batched/memoized `NamespaceRowPresenter.build_collection`, and once with
  # a naive drop-in replacement that builds one presenter per namespace with
  # no preloading/batching at all (the pre-refactor N+1 pattern) - achieved
  # by temporarily swapping `build_collection` itself, so the *exact same*
  # controller/view code runs for both strategies and pagination (Pagy's
  # default 20-item page limit) is respected exactly as it is in production.
  #
  # All data created for the benchmark is rolled back at the end via a
  # wrapping transaction.
  class NamespaceRowRendering # rubocop:disable Metrics/ClassLength
    Tree = Struct.new(:root, :nodes_by_level, :leaves)

    # rubocop:disable Metrics/ParameterLists
    def self.run(trees_count:, depth:, children_per_level:, projects_per_leaf:, root_extra_projects:, links_count:,
                 strategy:)
      new(trees_count:, depth:, children_per_level:, projects_per_leaf:, root_extra_projects:, links_count:,
          strategy:).run
    end

    def initialize(trees_count:, depth:, children_per_level:, projects_per_leaf:, root_extra_projects:, links_count:,
                   strategy:)
      @trees_count = trees_count
      @depth = depth
      @children_per_level = children_per_level
      @projects_per_leaf = projects_per_leaf
      @root_extra_projects = root_extra_projects
      @links_count = links_count
      @strategy = strategy
    end
    # rubocop:enable Metrics/ParameterLists

    def run
      ActiveRecord::Base.transaction do
        build_forest
        build_project_namespaces
        build_benchmark_user
        build_namespace_group_links
        report_setup_size
        with_signed_in_session do |session|
          benchmark_page(session, 'groups dashboard', '/dashboard/groups')
          benchmark_page(session, 'group show page', group_show_path)
          benchmark_page(session, 'projects dashboard', '/dashboard/projects')
        end
        raise ActiveRecord::Rollback
      end
    end

    private

    attr_reader :trees_count, :depth, :children_per_level, :projects_per_leaf, :root_extra_projects, :links_count,
                :strategy, :trees, :benchmark_user

    # Builds `trees_count` independent, fully-branching group hierarchies,
    # each `depth` levels deep (root included) with `children_per_level`
    # children per node - every node has real children, so project
    # namespaces, memberships and namespace group links can be scattered
    # across genuinely distinct branches at every level. `trees_count`
    # should exceed Pagy's default page size (20) so the groups dashboard's
    # first page is realistically full.
    def build_forest
      puts "Building #{trees_count} branching hierarchies " \
           "(depth=#{depth}, children per level=#{children_per_level})..."

      @trees = Array.new(trees_count) { |i| build_tree(i) }
    end

    def build_tree(index)
      root = Group.create!(name: "Row Rendering Benchmark Tree#{index} Root",
                           path: "rr-t#{index}-root-#{SecureRandom.hex(4)}")
      nodes_by_level = [[root]]

      (depth - 1).times do |level|
        nodes_by_level << nodes_by_level.last.flat_map do |parent|
          Array.new(children_per_level) do |i|
            Group.create!(
              name: "Row Rendering Benchmark Tree#{index} L#{level + 1} G#{i}",
              path: "rr-t#{index}-l#{level + 1}-#{SecureRandom.hex(4)}",
              parent:
            )
          end
        end
      end

      Tree.new(root, nodes_by_level, nodes_by_level.last)
    end

    # Attaches `projects_per_leaf` project namespaces (each with a project)
    # to every leaf group in every tree, plus `root_extra_projects` extra
    # project namespaces directly under the first tree's root - so that
    # tree's show page also exceeds Pagy's default page size and exercises
    # real pagination. Each project's `samples_count` counter-cache column
    # is set directly (not via real Sample records) purely to keep setup
    # fast - the benchmark only ever reads this column, never its
    # maintenance.
    def build_project_namespaces
      total = (trees_count * leaves_per_tree * projects_per_leaf) + root_extra_projects
      puts "Creating #{total} project namespaces across #{trees_count} trees..."

      build_leaf_project_namespaces
      root_extra_projects.times { |i| create_project_namespace(0, trees.first.root, "root#{i}") }
    end

    def build_leaf_project_namespaces
      trees.each_with_index do |tree, tree_index|
        tree.leaves.each do |leaf|
          projects_per_leaf.times { |i| create_project_namespace(tree_index, leaf, i) }
        end
      end
    end

    def leaves_per_tree
      children_per_level**(depth - 1)
    end

    def create_project_namespace(tree_index, parent, index)
      project = Project.new(creator: owner)
      project.build_namespace(
        name: "Row Rendering Benchmark Project T#{tree_index} #{parent.id} ##{index}",
        path: "rr-proj-#{tree_index}-#{parent.id}-#{index}-#{SecureRandom.hex(4)}",
        parent:, owner:
      )
      project.save!
      project.update_column(:samples_count, rand(1..50)) # rubocop:disable Rails/SkipsModelValidations
    end

    def owner
      @owner ||= create_benchmark_user('owner')
    end

    # Creates the user whose access we actually benchmark, and grants it a
    # direct MAINTAINER membership on *every* tree's root (so the groups
    # dashboard, group show page and projects dashboard all scale with
    # `trees_count` - access is inherited down each hierarchy), plus one
    # membership per level of the first tree so `Member.effective_access_level`
    # still has a real ancestor chain to walk for that tree's rows.
    def build_benchmark_user
      @benchmark_user = create_benchmark_user('subject')

      trees.each do |tree|
        Member.create!(
          user: benchmark_user, namespace: tree.root, created_by: owner,
          access_level: Member::AccessLevel::MAINTAINER
        )
      end
    end

    # Scatters `links_count` active namespace group links, each granting a
    # group sampled from one tree access to a (sub)group sampled from a
    # *different* tree - this is what makes `aggregated_samples_count`
    # genuinely expensive to compute per-row: every group's "shared" sample
    # total can span any of the other hierarchies, not just its own subtree.
    def build_namespace_group_links
      puts "Creating #{links_count} namespace group links scattered across #{trees_count} trees..."
      used_pairs = Set.new

      links_count.times { create_unique_namespace_group_link(used_pairs) }
    end

    # Retries until a (group, namespace) pair not already used is drawn -
    # small forests have a limited number of cross-tree pairs, so the same
    # pair can otherwise be drawn more than once, which NamespaceGroupLink's
    # uniqueness validation rejects.
    def create_unique_namespace_group_link(used_pairs)
      loop do
        source_tree, target_tree = trees.sample(2)
        group = source_tree.nodes_by_level.sample.sample
        namespace = target_tree.nodes_by_level.sample.sample
        pair = [group.id, namespace.id]
        next if used_pairs.include?(pair)

        used_pairs << pair
        NamespaceGroupLink.create!(group:, namespace:, group_access_level: Member::AccessLevel::ANALYST)
        break
      end
    end

    def report_setup_size
      namespace_ids = trees.flat_map { |t| t.nodes_by_level.flatten.map(&:id) }
      puts "Groups created: #{namespace_ids.size}"
      puts "Project namespaces created: #{Namespaces::ProjectNamespace.where(parent_id: namespace_ids).count}"
      puts "Namespace group links created: #{NamespaceGroupLink.count}"
      puts
    end

    def group_show_path
      "/#{trees.first.root.full_path}"
    end

    # Builds a real, signed-in integration session (a proper
    # `ActionDispatch::IntegrationTest` instance, not a bare
    # `ActionDispatch::Integration::Session` - Devise's test sign-in helper
    # requires the full Minitest integration-test lifecycle to work) so
    # every benchmarked request goes through the actual Warden/Devise
    # session, controller, view and `pagy()` call, exactly as a browser
    # request would.
    def with_signed_in_session
      integration_test_class = Class.new(ActionDispatch::IntegrationTest) do
        include Devise::Test::IntegrationHelpers
      end
      session = integration_test_class.new('namespace_row_rendering_benchmark')
      session.sign_in(benchmark_user)
      yield session
    end

    def benchmark_page(session, label, path)
      puts "--- #{label} (#{path}) ---"
      report_query_counts(session, path)

      Benchmark.ips do |x|
        x.report('naive (old N+1)') { request_with_strategy(session, path, :naive) } if run_strategy?(:old)
        x.report('presenter (new, batched)') { request_with_strategy(session, path, :presenter) } if run_strategy?(:new)
        x.compare! if strategy == :both
      end
      puts
    end

    def report_query_counts(session, path)
      naive_queries = count_queries { request_with_strategy(session, path, :naive) } if run_strategy?(:old)
      presenter_queries = count_queries { request_with_strategy(session, path, :presenter) } if run_strategy?(:new)

      puts "SQL queries - naive: #{naive_queries.inspect}, presenter: #{presenter_queries.inspect}"
    end

    def run_strategy?(which)
      [:both, which].include?(strategy)
    end

    def request_with_strategy(session, path, which)
      with_build_collection_strategy(which) do
        session.get(path)
        raise "unexpected response status #{session.response.status} for #{path}" unless session.response.status == 200
      end
    end

    # Temporarily swaps `NamespaceRowPresenter.build_collection` for a naive,
    # unbatched drop-in (one presenter per namespace, with no preloading and
    # no bulk `aggregated_samples_count` computation - each value is then
    # queried fresh, per row, exactly like the pre-refactor implementation)
    # so the real controller/view code path can be exercised for both
    # strategies without any other change.
    def with_build_collection_strategy(which)
      original_method = NamespaceRowPresenter.method(:build_collection)

      if which == :naive
        NamespaceRowPresenter.define_singleton_method(:build_collection) do |namespaces:, user:|
          namespaces.to_a.to_h { |namespace| [namespace.id, new(namespace:, user:)] }
        end
      end

      yield
    ensure
      NamespaceRowPresenter.define_singleton_method(:build_collection, &original_method)
    end

    def count_queries(&)
      count = 0
      callback = lambda do |*, payload|
        next if payload[:name].in?(%w[SCHEMA CACHE])
        next if payload[:sql].start_with?('BEGIN', 'COMMIT', 'ROLLBACK', 'SAVEPOINT', 'RELEASE')

        count += 1
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
      count
    end

    def create_benchmark_user(label)
      User.create!(
        first_name: 'Benchmark', last_name: label,
        email: "row-rendering-benchmark-#{label}-#{SecureRandom.hex(4)}@example.com",
        password: 'password1'
      )
    end
  end
end
# rubocop:enable Rails/Output
