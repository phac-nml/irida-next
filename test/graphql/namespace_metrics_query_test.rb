# frozen_string_literal: true

require 'test_helper'
require 'active_storage_test_case'

class NamespaceMetricsQueryTest < ActiveStorageTestCase
  include ActionDispatch::TestProcess
  include ActionView::Helpers::NumberHelper

  NAMESPACE_METRICS_QUERY = <<~GRAPHQL
    query(
      $namespaceType: [String!],
      $first: Int,
      $projFirst: Int,
      $projAfter: String,
      $grpFirst: Int,
      $grpAfter: String
    ) {
      namespaceMetrics(
        namespaceType: $namespaceType,
        first: $first,
      ) {
        nodes {
          id
          name
          puid
          type
          samplesCount
          diskUsage
          projectsCount
          projects(first: $projFirst, after: $projAfter) {
            pageInfo { hasNextPage endCursor }
            nodes {
              name
              samplesCount
              diskUsage
            }
          }
          ... on GroupMetricsType {
            projectsCount
            descendantGroups(first: $grpFirst, after: $grpAfter) {
              pageInfo { hasNextPage endCursor }
              nodes {
                name
                samplesCount
                diskUsage
                projectsCount
              }
            }
          }
          ... on UserNamespaceMetricsType {
            projectsCount
          }
        }
      }
    }
  GRAPHQL

  NAMESPACE_METRICS_DIRECT_QUERY = <<~GRAPHQL
    query($namespaceType: [String!], $first: Int, $directOnly: Boolean) {
      namespaceMetrics(first: $first, namespaceType: $namespaceType) {
        nodes {
          name
          puid
          type
          samplesCount(directOnly: $directOnly)
          diskUsage(directOnly: $directOnly)
          projectsCount(directOnly: $directOnly)
          ... on GroupMetricsType {
            projectsCount(directOnly: $directOnly)
          }
          ... on UserNamespaceMetricsType {
            projectsCount(directOnly: $directOnly)
          }
        }
      }
    }
  GRAPHQL

  GROUP_TOP_LEVEL_METRICS_QUERY = <<~GRAPHQL
    query($namespaceType: [String!], $topLevelOnly: Boolean) {
      namespaceMetrics(namespaceType: $namespaceType, topLevelOnly: $topLevelOnly) {
        nodes {
          name
          parent
          type
          samplesCount
          diskUsage
          projectsCount
        }
      }
    }
  GRAPHQL

  GROUP_OR_USER_BY_PUID_METRICS_QUERY = <<~GRAPHQL
    query($puid: ID!) {
      namespaceMetrics(puid: $puid) {
        nodes {
          name
          parent
          type
          samplesCount
          diskUsage
          projectsCount
        }
      }
    }
  GRAPHQL

  GROUP_OR_USER_BY_FULL_PATH_METRICS_QUERY = <<~GRAPHQL
    query($fullPath: ID!) {
      namespaceMetrics(fullPath: $fullPath) {
        nodes {
          name
          parent
          type
          samplesCount
          diskUsage
          projectsCount
        }
      }
    }
  GRAPHQL

  NAMESPACE_METRICS_MEMBERS_QUERY = <<~GRAPHQL
    query($puid: ID!, $userType: [String!], $source: String) {
      namespaceMetrics(puid: $puid) {
        nodes {
          name
          ... on GroupMetricsType {
            members(source: $source, userType: $userType) {
              nodes {
                user {
                  email
                }
                accessLevel
                expiresAt
              }
              totalCount
            }
            projects {
              nodes {
                name
                members(source: $source, userType: $userType) {
                  nodes {
                    user {
                      email
                    }
                    accessLevel
                    expiresAt
                  }
                  totalCount
                }

              }
            }
          }
        }
      }
    }
  GRAPHQL

  # used in the pagination test below; it exposes cursor information on the
  # nested projects/groups connections so that we can walk the pages one at a
  # time.
  PAGINATED_NAMESPACE_METRICS_QUERY = <<~GRAPHQL
    query(
      $namespaceType: [String!],
      $first: Int,
      $projFirst: Int,
      $projAfter: String,
      $grpFirst: Int,
      $grpAfter: String
    ) {
      namespaceMetrics(first: $first, namespaceType: $namespaceType) {
        nodes {
          name
          samplesCount
          diskUsage
          projects(first: $projFirst, after: $projAfter) {
            pageInfo { hasNextPage endCursor }
            nodes {
              name
              samplesCount
              diskUsage
            }
          }
          ... on GroupMetricsType {
            descendantGroups(first: $grpFirst, after: $grpAfter) {
              pageInfo { hasNextPage endCursor }
              nodes {
                name
                samplesCount
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

    valid_params = { name: 'Metrics Group 2', path: 'metrics-group-2', parent_id: nil }
    @group2 = Groups::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj1', path: 'proj-1', parent: @group } }
    @project = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj2', path: 'proj-2', parent: @subgroup } }
    @project2 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj3', path: 'proj-3', parent: @group2 } }
    @project3 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj4', path: 'proj-4', parent: @non_sys_user.namespace } }
    @project4 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj5', path: 'proj-5', parent: @non_sys_user.namespace } }
    @project5 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    # create a few samples via the service so that project and group
    # counters are incremented automatically
    @sample1 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample A').execute
    @sample2 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample B').execute
    @sample3 = Samples::CreateService.new(@non_sys_user, @project2, name: 'Sample C').execute

    @sample4 = Samples::CreateService.new(@non_sys_user, @project3, name: 'Sample D').execute
    @sample5 = Samples::CreateService.new(@non_sys_user, @project5, name: 'Sample E').execute

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

    Attachments::CreateService.new(@non_sys_user, @sample4,
                                   files: [active_storage_blobs(:test_file_fastq_blob)]).execute

    Attachments::CreateService.new(@non_sys_user, @sample5,
                                   files: [active_storage_blobs(:test_file_A_fastq_blob)]).execute

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

    valid_params = { user: @non_sys_user2, access_level: Member::AccessLevel::MAINTAINER }
    Members::CreateService.new(@non_sys_user, @project3.namespace, valid_params).execute

    params = { group_id: @group.id, group_access_level: Member::AccessLevel::MAINTAINER }
    GroupLinks::GroupLinkService.new(@non_sys_user, @group2, params).execute
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

    assert metrics_group_node['samplesCount'].is_a?(Integer)
    assert metrics_group_node['diskUsage'].is_a?(String)

    expected_projects = @group.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
    assert metrics_group_node['projectsCount'].is_a?(Integer), 'projectsCount should be an integer'
    assert_equal expected_projects, metrics_group_node['projectsCount'],
                 'group projectsCount should return count of projects from itself and its subgroups'

    @group.reload
    expected_samples = @group.aggregated_samples_count
    assert_equal expected_samples, metrics_group_node['samplesCount'], 'samplesCount should equal aggregated counter'

    expected_disk = calculate_disk_usage(@group)
    assert_equal expected_disk, metrics_group_node['diskUsage'], 'diskUsage should sum attachment byte sizes'

    # confirm projects are visible and each project carries its own metrics
    project_nodes = metrics_group_node.dig('projects', 'nodes') || []
    assert(project_nodes.any? { |p| p['name'] == @project.name })
    project_nodes.each do |p|
      # projects now also expose metric fields directly
      assert p['samplesCount'].is_a?(Integer)
      assert p['diskUsage'].is_a?(String)

      project_record = Project.joins(:namespace).find_by(namespaces: { name: p['name'] })
      expected_proj_samples = project_record.samples_count.to_i
      assert_equal expected_proj_samples, p['samplesCount'], 'project sample count should match database'

      expected_proj_disk = calculate_disk_usage(project_record)
      assert_equal expected_proj_disk, p['diskUsage'], 'project diskUsage should agree with our helper'
    end

    # and sub‑groups should also be iterable at the first level
    subgroup_nodes = metrics_group_node.dig('descendantGroups', 'nodes') || []
    assert(subgroup_nodes.any? { |g| g['name'] == @subgroup.name })
    subgroup_nodes.each do |g|
      assert g['samplesCount'].is_a?(Integer)
      assert g['diskUsage'].is_a?(String)
    end
  end

  test 'cursor pagination works for projects and groups within namespace metrics' do
    # build additional items so pagination has multiple pages to return
    extra_project = Projects::CreateService.new(
      @non_sys_user,
      namespace_attributes: { name: 'Proj Extra', path: 'proj-extra', parent: @group }
    ).execute

    sample1 = Samples::CreateService.new(@non_sys_user, extra_project, name: 'Sample A').execute
    sample2 = Samples::CreateService.new(@non_sys_user, extra_project, name: 'Sample B').execute
    sample3 = Samples::CreateService.new(@non_sys_user, extra_project, name: 'Sample C').execute

    sample4 = Samples::CreateService.new(@non_sys_user, extra_project, name: 'Sample D').execute

    # attach some files to the samples; use existing blob fixtures so we
    # know the byte sizes ahead of time
    Attachments::CreateService.new(@non_sys_user, sample1,
                                   files: [active_storage_blobs(:test_file_fastq_blob)]).execute
    Attachments::CreateService.new(@non_sys_user, sample2,
                                   files: [active_storage_blobs(:test_file_A_fastq_blob)]).execute
    Attachments::CreateService.new(@non_sys_user, sample3, files: [
                                     active_storage_blobs(:testsample_illumina_pe_forward_blob),
                                     active_storage_blobs(:testsample_illumina_pe_reverse_blob)
                                   ]).execute

    Attachments::CreateService.new(@non_sys_user, sample4,
                                   files: [active_storage_blobs(:test_file_fastq_blob)]).execute

    extra_group = Groups::CreateService.new(
      @non_sys_user,
      name: 'Extra Subgroup',
      path: 'extra-subgroup',
      parent_id: @group.id
    ).execute

    paginated_query = PAGINATED_NAMESPACE_METRICS_QUERY
    variables = { namespaceType: ['Group'], first: 1_000 }

    # iterate through project pages using cursor
    project_names = []
    proj_after = nil
    loop do
      variables.merge!(projFirst: 1, projAfter: proj_after,
                       grpFirst: nil, grpAfter: nil)

      result = IridaSchema.execute(
        paginated_query,
        context: { current_user: @sys_user },
        variables: variables,
        max_complexity: nil
      )
      assert_nil result['errors'], 'pagination query for projects should not error'

      ns_node = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == @group.name }
      assert ns_node, 'expected our group to be present in the paginated result'

      page = ns_node['projects']

      project_names.concat(page['nodes'].pluck('name'))
      break unless page['pageInfo']['hasNextPage']

      page['nodes'].each do |p|
        if p['name'] == extra_project.name
          project_record = extra_project.reload
          assert p['samplesCount'].is_a?(Integer)
          assert p['diskUsage'].is_a?(String)
          assert_equal project_record.samples_count.to_i, p['samplesCount']
          expected_proj_disk = calculate_disk_usage(project_record)
          assert_equal expected_proj_disk, p['diskUsage']
        else
          # other projects may have unrelated data so we just make sure the
          # types are as expected
          assert p['samplesCount'].is_a?(Integer)
          assert p['diskUsage'].is_a?(String)
        end
      end
      proj_after = page['pageInfo']['endCursor']
    end

    assert_equal [@project.name, extra_project.name].sort, project_names.sort,
                 'should retrieve all direct projects via successive pages'

    # iterate through group pages using cursor
    group_names = []
    grp_after = nil
    loop do
      variables.merge!(projFirst: nil, projAfter: nil,
                       grpFirst: 1, grpAfter: grp_after)

      result = IridaSchema.execute(
        paginated_query,
        context: { current_user: @sys_user },
        variables: variables,
        max_complexity: nil
      )
      assert_nil result['errors'], 'pagination query for groups should not error'

      ns_node = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == @group.name }
      page = ns_node['descendantGroups']
      group_names.concat(page['nodes'].pluck('name'))
      break unless page['pageInfo']['hasNextPage']

      page['nodes'].each do |g|
        if g['name'] == extra_group.name
          group_record = extra_group.reload
          assert g['samplesCount'].is_a?(Integer)
          assert g['diskUsage'].is_a?(String)
          assert_equal 0, g['samplesCount']
          expected_group_disk = calculate_disk_usage(group_record)
          assert_equal expected_group_disk, g['diskUsage']
        else
          assert g['samplesCount'].is_a?(Integer)
          assert g['diskUsage'].is_a?(String)
        end
      end

      grp_after = page['pageInfo']['endCursor']
    end

    assert_equal [@subgroup.name, extra_group.name].sort, group_names.sort,
                 'should retrieve all subgroups via successive pages'
  end

  test 'non-system user cannot see namespace metrics endpoint' do
    result = IridaSchema.execute(
      NAMESPACE_METRICS_QUERY,
      context: { current_user: users(:jane_doe) },
      variables: { namespaceType: ['Group'], first: 1_000 },
      max_complexity: nil
    )

    assert_not_nil result['errors'], 'expect permission errors when not system user'
    assert_match(/(doesn't exist)/, result['errors'][0]['message'])
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
    grp_nodes = user_node.dig('descendantGroups', 'nodes') || nil
    assert_nil grp_nodes, 'no subgroups should be returned for a user namespace'

    # metrics at the user namespace itself are now available directly on
    # the node rather than under a nested object.
    user_ns.reload
    assert user_node['projectsCount'].is_a?(Integer)
    assert_equal user_ns.project_namespaces.count, user_node['projectsCount'],
                 'user metrics projectsCount should equal to the number of project_namespaces under the user namespace'

    gql_id = user_node['id']
    namespace_record = IridaSchema.object_from_id(gql_id, context: { current_user: @sys_user })
    assert namespace_record.is_a?(Namespaces::UserNamespace)

    expected_user_samples = Sample.where(
      project_id: Project.where(namespace_id: namespace_record.project_namespaces.pluck(:id))
    ).count
    assert_equal expected_user_samples, user_node['samplesCount']

    expected_user_disk = calculate_disk_usage(user_ns)
    assert_equal expected_user_disk, user_node['diskUsage']

    proj_nodes = user_node.dig('projects', 'nodes') || []
    assert(proj_nodes.any? { |p| p['name'] == user_proj.name })
    proj_nodes.each do |p|
      # projects expose metrics fields directly now
      assert p['samplesCount'].is_a?(Integer)
      assert p['diskUsage'].is_a?(String)

      next unless p['name'] == user_proj.name

      project_record = user_proj.reload
      assert_equal project_record.samples_count.to_i, p['samplesCount']
      expected_proj_disk = calculate_disk_usage(project_record)
      assert_equal expected_proj_disk, p['diskUsage']
    end
  end

  test 'ensure duplicate attachments pointing to same blob are not double counted for diskUsage' do
    workflow_execution = workflow_executions(:irida_next_example_completing_g)

    blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
    workflow_execution.blob_run_directory = blob_run_directory_a

    # create file blobs
    @normal_output_json_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal5/iridanext.output.json',
      blob_run_directory: blob_run_directory_a,
      gzip: true
    )

    @normal_output_summary_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal5/summary.txt',
      blob_run_directory: blob_run_directory_a
    )

    @analysis1_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal5/analysis1.txt',
      blob_run_directory: blob_run_directory_a,
      gzip: false
    )

    @analysis2_file_blob = make_and_upload_blob(
      filepath: 'test/fixtures/files/blob_outputs/normal5/analysis2.txt',
      blob_run_directory: blob_run_directory_a,
      gzip: false
    )

    workflow_execution.save

    analysis_output_filenames = [@analysis1_file_blob.filename, @analysis2_file_blob.filename]

    sample = samples(:sampleA)
    assert_equal 3, sample.attachments.count

    assert 'completing', workflow_execution.state

    assert_equal 'my_run_id_g', workflow_execution.run_id

    perform_enqueued_jobs(only: WorkflowExecutionCompletionJob) do
      WorkflowExecutionCompletionJob.perform_later(workflow_execution)
    end
    workflow_execution.reload

    assert_equal 3, workflow_execution.outputs.count

    # Workflow execution ran with 2 samples
    assert_equal 2, workflow_execution.samples_workflow_executions.count

    swe = workflow_execution.samples_workflow_executions.find { |swe| swe.sample_id == sample.id }
    assert_equal 2, swe.outputs.count

    output_summary_file = workflow_execution.outputs.find { |o| o.file.filename == 'summary.txt' }
    assert_not_equal @normal_output_summary_file_blob.id, output_summary_file.id
    assert_equal @normal_output_summary_file_blob.filename, output_summary_file.filename
    assert_equal @normal_output_summary_file_blob.checksum, output_summary_file.file.checksum

    output_analysis1_file = workflow_execution.outputs.find { |o| o.file.filename == 'analysis1.txt' }
    assert_equal @analysis1_file_blob.filename, output_analysis1_file.filename
    assert_equal @analysis1_file_blob.checksum, output_analysis1_file.file.checksum

    output_analysis2_file = workflow_execution.outputs.find { |o| o.file.filename == 'analysis2.txt' }
    assert_equal @analysis2_file_blob.filename, output_analysis2_file.filename
    assert_equal @analysis2_file_blob.checksum, output_analysis2_file.file.checksum

    swe_output_filenames = swe.outputs.map(&:filename)

    assert_equal swe_output_filenames.sort, analysis_output_filenames.sort

    assert_equal 5, sample.attachments.count

    assert_equal 'completed', workflow_execution.state

    namespace_calculated_disk_usage = calculate_disk_usage(workflow_execution.namespace)

    jeff_doe_user_namespace = users(:jeff_doe).namespace

    result = IridaSchema.execute(
      GROUP_OR_USER_BY_PUID_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { puid: jeff_doe_user_namespace.puid },
      max_complexity: nil
    )

    assert_nil result['errors'], 'query should execute without errors'
    assert_equal 1, result['data']['namespaceMetrics']['nodes'].size, 'should return one namespace'
    namespace_node = result['data']['namespaceMetrics']['nodes'].first
    assert_equal jeff_doe_user_namespace.name, namespace_node['name'], 'should return the correct user namespace'
    assert_equal namespace_calculated_disk_usage, namespace_node['diskUsage'],
                 'disk usage should match expected value without double counting duplicate attachments'
  end

  test 'group namespace metrics query with topLevelOnly flag returns only top level groups' do
    result = IridaSchema.execute(
      GROUP_TOP_LEVEL_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { namespaceType: ['Group'], topLevelOnly: true },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert_not_empty namespaces, 'should return at least one namespace'
    assert namespaces.all? { |n| n['parent'].nil? }, 'all returned namespaces should be top-level (no parent)'
  end

  test 'get group namespace metrics by PUID' do
    result = IridaSchema.execute(
      GROUP_OR_USER_BY_PUID_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { puid: @group.puid },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert namespaces.one?, 'should return one namespace'
    group_node = namespaces.last
    assert_equal @group.name, group_node['name'], 'should return the correct group based on PUID'
    assert group_node['samplesCount'].is_a?(Integer)
    assert group_node['diskUsage'].is_a?(String)
    assert_equal @group.reload.aggregated_samples_count, group_node['samplesCount']
    expected_group_disk = calculate_disk_usage(@group)
    assert_equal expected_group_disk, group_node['diskUsage']
  end

  test 'get group namespace metrics by full path' do
    result = IridaSchema.execute(
      GROUP_OR_USER_BY_FULL_PATH_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { fullPath: @group.full_path },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert namespaces.one?, 'should return one namespace'
    group_node = namespaces.last
    assert_equal @group.name, group_node['name'], 'should return the correct group based on full path'
    assert group_node['samplesCount'].is_a?(Integer)
    assert group_node['diskUsage'].is_a?(String)
    assert_equal @group.reload.aggregated_samples_count, group_node['samplesCount']
    expected_group_disk = calculate_disk_usage(@group)
    assert_equal expected_group_disk, group_node['diskUsage']
  end

  test 'get user namespace metrics by PUID' do
    result = IridaSchema.execute(
      GROUP_OR_USER_BY_PUID_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { puid: @non_sys_user.namespace.puid },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert namespaces.one?, 'should return one namespace'
    user_node = namespaces.last
    assert_equal @non_sys_user.email, user_node['name'], 'should return the correct user based on PUID'
    assert user_node['samplesCount'].is_a?(Integer)
    assert user_node['diskUsage'].is_a?(String)
    assert_equal 1, user_node['samplesCount']
    expected_user_disk = calculate_disk_usage(@non_sys_user.namespace)
    assert_equal expected_user_disk, user_node['diskUsage']
    assert_equal 2, user_node['projectsCount']
  end

  test 'get user namespace metrics by full path' do
    result = IridaSchema.execute(
      GROUP_OR_USER_BY_FULL_PATH_METRICS_QUERY,
      context: { current_user: @sys_user },
      variables: { fullPath: @non_sys_user.namespace.full_path },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert namespaces.one?, 'should return one namespace'
    user_node = namespaces.last
    assert_equal @non_sys_user.email, user_node['name'], 'should return the correct user based on PUID'
    assert user_node['samplesCount'].is_a?(Integer)
    assert user_node['diskUsage'].is_a?(String)
    assert_equal 1, user_node['samplesCount']
    expected_user_disk = calculate_disk_usage(@non_sys_user.namespace)
    assert_equal expected_user_disk, user_node['diskUsage']
    assert_equal 2, user_node['projectsCount']
  end

  test 'namespace metrics query with directOnly flag returns metrics for direct projects and samples only' do
    result = IridaSchema.execute(
      NAMESPACE_METRICS_DIRECT_QUERY,
      context: { current_user: @sys_user },
      variables: { namespaceType: ['Group'], first: 1_000, directOnly: true },
      max_complexity: nil
    )
    assert_nil result['errors'], 'query should execute without errors'
    namespaces = result['data']['namespaceMetrics']['nodes']
    assert_not_empty namespaces, 'should return at least one namespace'
    metrics_group_node = namespaces.find { |n| n['name'] == @group.name }
    assert metrics_group_node, 'expected our test group to appear in the results'

    expected_projects = @group.project_namespaces.count
    assert metrics_group_node['projectsCount'].is_a?(Integer), 'projectsCount should be an integer'
    assert_equal expected_projects, metrics_group_node['projectsCount'],
                 'group projectsCount with directOnly should return count of only direct projects'

    expected_samples_count = 0
    @group.project_namespaces.each do |pn|
      expected_samples_count += pn.project.samples_count.to_i
    end

    assert_equal expected_samples_count, metrics_group_node['samplesCount'],
                 'samplesCount with directOnly should equal the direct counter'
    expected_disk_usage = calculate_disk_usage(@group, direct_only: true)
    assert_equal expected_disk_usage, metrics_group_node['diskUsage'],
                 'diskUsage with directOnly should sum attachment byte sizes for direct projects and samples only'
  end

  test 'group members query should work' do
    group = groups(:group_one)

    result = IridaSchema.execute(NAMESPACE_METRICS_MEMBERS_QUERY, context: { current_user: @sys_user },
                                                                  variables: { puid: group.puid },
                                                                  max_complexity: nil)

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == group.name }

    assert_not_empty data, 'group type should work'
    assert_equal group.name, data['name']

    members_data = data['members']

    assert_not_empty members_data, 'members field should return data'
    assert_equal 4, members_data['totalCount'], 'totalCount should be correct'

    member_nodes = members_data['nodes']
    assert_not_empty member_nodes, 'member nodes should not be empty'
    assert_equal 4, member_nodes.size, 'should return the correct number of member nodes'

    member_nodes.each do |member_node|
      user_email = member_node['user']['email']
      access_level = member_node['accessLevel']
      expires_at = member_node['expiresAt']

      expected_emails = [users(:john_doe).email, users(:joan_doe).email, users(:ryan_doe).email,
                         users(:james_doe).email]

      assert_includes expected_emails,
                      user_email

      access_level_translations = [I18n.t('members.access_levels.level_10'),
                                   I18n.t('members.access_levels.level_40'),
                                   I18n.t('members.access_levels.level_50')]

      assert_includes access_level_translations, access_level
      assert_nil expires_at if user_email == 'john.doe@localhost'
      assert_not_nil expires_at if user_email != 'john.doe@localhost'
    end
  end

  test 'subgroup direct members query should work' do
    # subgroup1 is a subgroup of group_one
    group = groups(:subgroup1)

    result = IridaSchema.execute(NAMESPACE_METRICS_MEMBERS_QUERY, context: { current_user: @sys_user },
                                                                  variables: {
                                                                    puid: group.puid,
                                                                    source: 'direct'
                                                                  },
                                                                  max_complexity: nil)

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == group.name }

    assert_not_empty data, 'group type should work'
    assert_equal group.name, data['name']

    members_data = data['members']

    assert_not_empty members_data, 'members field should return data'
    assert_equal 1, members_data['totalCount'], 'totalCount should be correct'

    member_nodes = members_data['nodes']
    assert_not_empty member_nodes, 'member nodes should not be empty'
    assert_equal 1, member_nodes.size, 'should return the correct number of member nodes'

    member_nodes.each do |member_node|
      user_email = member_node['user']['email']
      access_level = member_node['accessLevel']
      expires_at = member_node['expiresAt']

      assert_includes ['ryan.doe@localhost'],
                      user_email

      assert_equal I18n.t('members.access_levels.level_10'), access_level

      assert_nil expires_at
    end
  end

  test 'project members query should work' do
    group = groups(:group_one)
    project = projects(:project1)

    result = IridaSchema.execute(NAMESPACE_METRICS_MEMBERS_QUERY, context: { current_user: @sys_user },
                                                                  variables: { puid: group.puid },
                                                                  max_complexity: nil)

    assert_nil result['errors'], 'should work and have no errors.'

    group_data = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == group.name }
    data = group_data['projects']['nodes'].find { |p| p['name'] == project.name }

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']
    assert_equal 5, data['members']['totalCount']

    members_data = data['members']

    assert_not_empty members_data, 'members field should return data'
    assert_equal 5, members_data['totalCount'], 'totalCount should be correct'

    member_nodes = members_data['nodes']
    assert_not_empty member_nodes, 'member nodes should not be empty'
    assert_equal 5, member_nodes.size, 'should return the correct number of member nodes'

    access_level_translations = [I18n.t('members.access_levels.level_10'),
                                 I18n.t('members.access_levels.level_30'),
                                 I18n.t('members.access_levels.level_40'),
                                 I18n.t('members.access_levels.level_50')]

    expected_emails = [users(:john_doe).email, users(:joan_doe).email, users(:ryan_doe).email, users(:james_doe).email,
                       users(:michelle_doe).email]

    member_nodes.each do |member_node|
      user_email = member_node['user']['email']
      access_level = member_node['accessLevel']
      expires_at = member_node['expiresAt']

      assert_includes expected_emails,
                      user_email

      assert_includes access_level_translations, access_level

      assert_nil expires_at if user_email != users(:joan_doe).email
      assert_not_nil expires_at if user_email == users(:joan_doe).email
    end
  end

  test 'project members query with source set to direct should only return direct members' do
    group = groups(:group_one)
    project = projects(:project1)

    result = IridaSchema.execute(NAMESPACE_METRICS_MEMBERS_QUERY, context: { current_user: @sys_user },
                                                                  variables: {
                                                                    puid: group.puid,
                                                                    source: 'direct'
                                                                  },
                                                                  max_complexity: nil)

    assert_nil result['errors'], 'should work and have no errors.'

    group_data = result['data']['namespaceMetrics']['nodes'].find { |n| n['name'] == group.name }
    data = group_data['projects']['nodes'].find { |p| p['name'] == project.name }

    assert_not_empty data, 'project type should work'
    assert_equal project.name, data['name']
    assert_equal 4, data['members']['totalCount']

    members_data = data['members']

    assert_not_empty members_data, 'members field should return data'
    assert_equal 4, members_data['totalCount'], 'totalCount should be correct'

    member_nodes = members_data['nodes']
    assert_not_empty member_nodes, 'member nodes should not be empty'
    assert_equal 4, member_nodes.size, 'should return the correct number of member nodes'

    access_level_translations = [I18n.t('members.access_levels.level_10'),
                                 I18n.t('members.access_levels.level_30'),
                                 I18n.t('members.access_levels.level_40'),
                                 I18n.t('members.access_levels.level_50')]

    expected_emails = [users(:john_doe).email, users(:ryan_doe).email, users(:james_doe).email,
                       users(:michelle_doe).email]

    member_nodes.each do |member_node|
      user_email = member_node['user']['email']
      access_level = member_node['accessLevel']
      expires_at = member_node['expiresAt']

      assert_includes expected_emails,
                      user_email

      assert_includes access_level_translations, access_level

      assert_nil expires_at if user_email
    end
  end

  private

  # Calculate the disk usage for unique attachment blobs under a namespace (namespace attachments, sample attachments,
  # sample workflow execution attachments)
  def calculate_disk_usage(namespace_or_project, direct_only: false) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    namespace = namespace_or_project.is_a?(Project) ? namespace_or_project.namespace : namespace_or_project

    samples = []
    if direct_only && !namespace.project_namespace?
      namespace.project_namespaces.each do |pn|
        samples.concat(pn.project.samples) if pn.project.samples_count&.positive?
      end
    else
      namespace.self_and_descendants.each do |ns|
        if ns.group_namespace? || ns.user_namespace?
          ns.project_namespaces.each do |pn|
            samples.concat(pn.project.samples) if pn.project.samples_count&.positive?
          end
        elsif !ns.project.samples_count.nil? && ns.project.samples_count&.positive?
          samples.concat(ns.project.samples)
        end
      end
    end

    sample_ids = samples.map(&:id)

    namespace_ids = if direct_only && !namespace.project_namespace?
                      [namespace.id] + namespace.project_namespaces.pluck(:id)
                    else
                      namespace.self_and_descendants_of_type(
                        [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
                      ).map(&:id)
                    end

    sample_workflow_execution_ids = SamplesWorkflowExecution.joins(:workflow_execution).where(
      sample_id: sample_ids,
      workflow_execution: {
        namespace_id: namespace_ids
      }
    ).pluck(:id)

    workflow_execution_ids = WorkflowExecution.where(namespace_id: namespace_ids).pluck(:id)

    attachable_ids = sample_ids + namespace_ids + sample_workflow_execution_ids + workflow_execution_ids

    attachments = Attachment.where(attachable_id: attachable_ids)

    total_attachments_size = 0
    blob_ids = []
    # Duplicates can occur when a blob is attached to multiple records (e.g. a sample attachment that is attached to
    # both the sample and a workflow execution output), so we track blob ids to avoid double counting the blobs.
    attachments.each do |att|
      total_attachments_size += att.file.blob.byte_size if att.file&.blob && blob_ids.exclude?(att.file.blob_id)
      blob_ids << att.file.blob_id if att.file&.blob_id
    end

    number_to_human_size(
      total_attachments_size, precision: 2, significant: false, strip_insignificant_zeros: false
    )
  end
end
