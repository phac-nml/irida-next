# frozen_string_literal: true

require 'test_helper'

class NamespaceMetricsQueryTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  # We only need to traverse one level of groups and projects to verify
  # that a system user can walk the namespaceMetrics connection and see
  # metrics on the returned objects.  A simpler query avoids hitting the
  # complexity limits built into GraphQL.
  NAMESPACE_METRICS_QUERY = <<~GRAPHQL
    query($namespaceType: [String!], $first: Int) {
      namespaceMetrics(first: $first, namespaceType: $namespaceType) {
        nodes {
          id
          name
          type
          metrics {
            projectsCount
            samplesCount
            membersCount
            diskUsage
          }
          projects {
            nodes {
              id
              name
              metrics {
                samplesCount
                membersCount
                diskUsage
              }
            }
          }
          groups {
            nodes {
              name
              metrics {
                samplesCount
                membersCount
                diskUsage
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # convert an existing fixture user to a system account for ease
    @sys_user = users(:john_doe)
    @non_sys_user = users(:jane_doe)
    @non_sys_user2 = users(:james_doe)
    @sys_user.update!(system: true)

    # build a small namespace hierarchy and a couple of projects so the
    # resolver has something to traverse. we will add real samples with
    # attachments so the counters and disk usage can be asserted against
    # concrete values.

    valid_params = { name: 'Metrics Group', path: 'metrics-group', parent_id: nil }
    @group = Groups::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { name: 'Metrics Subgroup', path: 'metrics-subgroup', parent_id: @group.id }
    @subgroup = Groups::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj1', path: 'proj-1', parent: @group } }
    @project = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj2', path: 'proj-2', parent: @subgroup } }
    @project2 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    # create a few samples via the service so that project and group
    # counters are incremented automatically
    @sample1 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample A').execute
    @sample2 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample B').execute
    @sample3 = Samples::CreateService.new(@non_sys_user, @project2, name: 'Sample C').execute

    # attach some files to the samples; use existing blob fixtures so we
    # know the byte sizes ahead of time
    Attachments::CreateService.new(@non_sys_user, @sample1,
                                   files: [active_storage_blobs(:test_file_fastq_blob)]).execute
    Attachments::CreateService.new(@non_sys_user, @sample2,
                                   files: [active_storage_blobs(:test_file_A_fastq_blob)]).execute
    Attachments::CreateService.new(@non_sys_user, @sample3, files: [
                                     active_storage_blobs(:testsample_illumina_pe_forward_blob),
                                     active_storage_blobs(:testsample_illumina_pe_reverse_blob)
                                   ]).execute

    # add a couple of namespace attachments as well so disk usage covers
    # all three resolver branches (namespace, sample, workflow).
    Attachments::CreateService.new(
      @non_sys_user, @project.namespace,
      files: [active_storage_blobs(:project1_attachment1_file_test_file_fastq_blob)]
    ).execute

    valid_params = { user: @non_sys_user, access_level: Member::AccessLevel::MAINTAINER }
    Members::CreateService.new(@non_sys_user, @group, valid_params).execute

    valid_params = { user: @non_sys_user2, access_level: Member::AccessLevel::MAINTAINER }
    Members::CreateService.new(@non_sys_user, @project.namespace, valid_params).execute

    valid_params = { user: @non_sys_user, access_level: Member::AccessLevel::MAINTAINER }
    Members::CreateService.new(@non_sys_user, @project.namespace, valid_params).execute
  end

  test 'system user can iterate through namespace metrics and view project/group metrics' do
    result = IridaSchema.execute(
      NAMESPACE_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { namespaceType: ['Group'], first: 1_000 },
      max_complexity: nil
    )

    assert_nil result['errors'], 'query should execute without errors'

    namespaces = result['data']['namespaceMetrics']['nodes']
    assert_not_empty namespaces, 'should return at least one namespace'

    metrics_group_node = namespaces.find { |n| n['name'] == @group.name }
    assert metrics_group_node, 'expected our test group to appear in the results'

    # verify the top‑level group has a metrics object with the expected keys
    metrics = metrics_group_node['metrics']
    assert metrics.present?, 'metrics should be returned for the namespace'

    # concrete values based on our setup
    expected_projects = @group.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
    assert metrics['projectsCount'].is_a?(Integer), 'projectsCount should be an integer'
    # value should not exceed what we know is in the database
    assert_operator metrics['projectsCount'], :<=, expected_projects

    # reload before inspecting counters - the in-memory object may be stale
    @group.reload
    # samplesCount should exactly match the resolver's value; we rely on the
    # service in setup to keep counters in sync so this is deterministic
    expected_samples = @group.aggregated_samples_count
    assert_equal expected_samples, metrics['samplesCount'], 'samplesCount should equal aggregated counter'

    assert_equal 1, metrics['membersCount'], 'only jane_doe was added to the group'

    # diskUsage should reflect the attachments we created above; compute the
    # expected string by mirroring the resolver's SQL logic so we stay in
    # control of the database objects rather than instantiating GraphQL
    expected_disk = disk_usage_for(@group)
    assert_equal expected_disk, metrics['diskUsage'], 'diskUsage should sum attachment byte sizes'

    # also validate types just for sanity
    assert metrics['samplesCount'].is_a?(Integer)
    assert metrics['membersCount'].is_a?(Integer)
    assert metrics['diskUsage'].is_a?(String)

    # confirm projects are visible and each project carries its own metrics
    project_nodes = metrics_group_node.dig('projects', 'nodes') || []
    assert(project_nodes.any? { |p| p['name'] == @project.name })
    project_nodes.each do |p|
      assert p['metrics'].present?, 'project metrics should be present'

      # find the matching project record based on the name of its namespace
      project_record = Project.joins(:namespace).find_by(namespaces: { name: p['name'] })

      # the resolver for samplesCount simply returns the counter on the
      # project namespace; use that value for the expected assertion
      expected_proj_samples = project_record.samples_count.to_i
      assert_equal expected_proj_samples, p['metrics']['samplesCount'], 'project sample count should match database'

      # disk usage for the project should also be predictable via resolver
      expected_proj_disk = disk_usage_for(project_record)
      assert_equal expected_proj_disk, p['metrics']['diskUsage'], 'project diskUsage should agree with our helper'

      assert p['metrics']['membersCount'].is_a?(Integer)
      assert_equal 2, p['metrics']['membersCount'], 'project membersCount should only have two members'
    end

    # and sub‑groups should also be iterable at the first level
    subgroup_nodes = metrics_group_node.dig('groups', 'nodes') || []
    assert(subgroup_nodes.any? { |g| g['name'] == @subgroup.name })
    subgroup_nodes.each do |g|
      assert g['metrics'].present?, 'subgroup metrics should be present'
    end
  end

  test 'non-system user is not granted access to namespace metrics' do
    result = IridaSchema.execute(
      NAMESPACE_METRICS_QUERY,
      context: { current_user: users(:jane_doe) },
      variables: { namespaceType: ['Group'], first: 1_000 },
      max_complexity: nil
    )

    # unauthorized objects are reported as errors by the schema
    assert_not_nil result['errors'], 'expect permission errors when not system user'
    assert_match(/hidden due to permissions/, result['errors'][0]['message'])
  end

  test 'user namespace metrics query returns only projects and no groups' do
    # add a project namespace under the system user's private namespace
    user_ns = @non_sys_user2.namespace
    valid_params = { namespace_attributes: { name: 'UserProj', path: 'user-proj', parent_id: user_ns.id } }
    user_proj = Projects::CreateService.new(@non_sys_user2, valid_params).execute

    # create a couple of real samples under the new project and add an
    # attachment so metrics are non‑trivial
    Samples::CreateService.new(@non_sys_user2, user_proj, name: 'UserSample1').execute
    Samples::CreateService.new(@non_sys_user2, user_proj, name: 'UserSample2').execute
    # sanity check that both samples actually exist in the project
    assert_equal 2, Sample.where(project: user_proj).count

    Attachments::CreateService.new(@non_sys_user2, user_proj.namespace,
                                   files: [active_storage_blobs(:test_file_fastq_blob)]).execute

    result = IridaSchema.execute(
      NAMESPACE_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { namespaceType: ['User'], first: 1_000 },
      max_complexity: nil
    )

    assert_nil result['errors'], 'query should execute without errors'

    namespaces = result['data']['namespaceMetrics']['nodes']
    user_node = namespaces.find { |n| n['name'] == user_ns.name }
    assert user_node, 'expected the user namespace to appear'

    # user namespaces should not have any groups attached
    grp_nodes = user_node.dig('groups', 'nodes') || nil
    assert_nil grp_nodes, 'no groups should be returned for a user namespace'

    # metrics at the user namespace itself
    user_metrics = user_node['metrics']
    user_ns.reload
    assert user_metrics['projectsCount'].is_a?(Integer)
    assert_equal user_ns.project_namespaces.count, user_metrics['projectsCount'],
                 'user metrics projectsCount should equal to the number of project_namespaces under the user namespace'

    # the query might return a different namespace object than the one we
    # manually referenced (for example it may be re-loaded or scoped). use
    # the ID from the response to guarantee we're computing against exactly
    # the same record.
    gql_id = user_node['id']
    namespace_record = IridaSchema.object_from_id(gql_id, context: { current_user: @sys_user })
    assert namespace_record.is_a?(Namespaces::UserNamespace)

    expected_user_samples = Sample.where(
      project_id: Project.where(namespace_id: namespace_record.project_namespaces.pluck(:id))
    ).count
    assert_equal expected_user_samples, user_metrics['samplesCount']

    assert user_metrics['membersCount'].is_a?(Integer)
    assert_equal 1, user_metrics['membersCount'], 'only the owner should be counted as a member for the project'

    expected_user_disk = disk_usage_for(user_ns)
    assert_equal expected_user_disk, user_metrics['diskUsage']

    proj_nodes = user_node.dig('projects', 'nodes') || []
    assert(proj_nodes.any? { |p| p['name'] == user_proj.name })
    proj_nodes.each do |p|
      assert p['metrics'].present?

      if p['name'] == user_proj.name
        project_record = user_proj.reload
        assert p['metrics']['samplesCount'].is_a?(Integer)
        assert p['metrics']['diskUsage'].is_a?(String)
        assert p['metrics']['membersCount'].is_a?(Integer)
        assert_equal project_record.samples_count.to_i, p['metrics']['samplesCount']
        expected_proj_disk = disk_usage_for(project_record)
        assert_equal expected_proj_disk, p['metrics']['diskUsage']
        assert_equal 1, p['metrics']['membersCount']
      else
        # other (fixture) projects may have unrelated data; just make sure
        # types are sane
        assert p['metrics']['samplesCount'].is_a?(Integer)
        assert p['metrics']['diskUsage'].is_a?(String)
        assert p['metrics']['membersCount'].is_a?(Integer)
      end
    end
  end

  private

  # replicate the SQL logic used by the DiskUsageResolver so we can verify
  # the GraphQL query without having to construct a full resolver context
  def disk_usage_for(namespace_or_project) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    namespace = namespace_or_project.is_a?(Project) ? namespace_or_project.namespace : namespace_or_project

    total_bytes = Attachment.with(
      namespace_attachments: Attachment.where(
        attachable_type: 'Namespace',
        attachable_id: namespace.self_and_descendants_of_type(
          [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
        ).select(:id)
      ).select(:id),
      sample_attachments: Attachment.where(
        attachable_type: 'Sample',
        attachable_id: Sample.where(
          project_id: Project.where(namespace_id: namespace.self_and_descendants_of_type(
            [Namespaces::ProjectNamespace.sti_name]
          ).select(:id))
        )
      ).select(:id),
      sample_workflow_execution_attachments:
        Attachment.where(attachable_type: 'SamplesWorkflowExecution',
                         attachable: SamplesWorkflowExecution.joins(:workflow_execution).where(
                           workflow_execution: {
                             namespace_id: namespace.self_and_descendants_of_type(
                               [Group.sti_name,
                                Namespaces::ProjectNamespace.sti_name]
                             ).select(:id)
                           }
                         ))
    ).where(
      Arel.sql(
        'attachments.id in (select id from namespace_attachments)
          OR attachments.id in (select id from sample_attachments)
          OR attachments.id in (select id from sample_workflow_execution_attachments)'
      )
    ).joins(file_attachment: :blob)
                            .select('DISTINCT active_storage_blobs.byte_size')
                            .sum('CAST(active_storage_blobs.byte_size AS BIGINT)')

    ActionController::Base.helpers.number_to_human_size(
      total_bytes,
      precision: 2,
      significant: false,
      strip_insignificant_zeros: false
    )
  end
end
