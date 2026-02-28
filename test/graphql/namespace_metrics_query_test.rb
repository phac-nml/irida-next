# frozen_string_literal: true

require 'test_helper'
require 'active_storage_test_case'

class NamespaceMetricsQueryTest < ActiveStorageTestCase
  include ActionDispatch::TestProcess
  include ActionView::Helpers::NumberHelper

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

    valid_params = { name: 'Metrics Group 2', path: 'metrics-group-2', parent_id: nil }
    @group2 = Groups::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj1', path: 'proj-1', parent: @group } }
    @project = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj2', path: 'proj-2', parent: @subgroup } }
    @project2 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    valid_params = { namespace_attributes: { name: 'Proj3', path: 'proj-3', parent: @group2 } }
    @project3 = Projects::CreateService.new(@non_sys_user, valid_params).execute

    # create a few samples via the service so that project and group
    # counters are incremented automatically
    @sample1 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample A').execute
    @sample2 = Samples::CreateService.new(@non_sys_user, @project, name: 'Sample B').execute
    @sample3 = Samples::CreateService.new(@non_sys_user, @project2, name: 'Sample C').execute

    @sample4 = Samples::CreateService.new(@non_sys_user, @project3, name: 'Sample D').execute

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

    # verify the top‑level group has a metrics object with the expected keys
    metrics = metrics_group_node['metrics']
    assert metrics.present?, 'metrics should be returned for the namespace'

    # also validate types just for sanity
    assert metrics['samplesCount'].is_a?(Integer)
    assert metrics['membersCount'].is_a?(Integer)
    assert metrics['diskUsage'].is_a?(String)

    # concrete values based on our setup
    expected_projects = @group.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).count
    assert metrics['projectsCount'].is_a?(Integer), 'projectsCount should be an integer'
    assert_equal expected_projects, metrics['projectsCount'],
                 'group projectsCount should return count of projects from itself and its subgroups'

    # reload before inspecting counters - the in-memory object may be stale
    @group.reload
    # samplesCount should exactly match the resolver's value; we rely on the
    # service in setup to keep counters in sync so this is deterministic. Group
    # samplesCount includes samples from shared groups
    expected_samples = @group.aggregated_samples_count
    assert_equal expected_samples, metrics['samplesCount'], 'samplesCount should equal aggregated counter'

    assert_equal 1, metrics['membersCount'], 'only jane_doe was added to the group'

    # diskUsage should reflect the attachments we created above; compute the
    # expected string by mirroring the resolver's SQL logic so we stay in
    # control of the database objects rather than instantiating GraphQL
    expected_disk = calculate_disk_usage(@group)
    assert_equal expected_disk, metrics['diskUsage'], 'diskUsage should sum attachment byte sizes'

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
      expected_proj_disk = calculate_disk_usage(project_record)
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

    expected_user_disk = calculate_disk_usage(user_ns)
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
        expected_proj_disk = calculate_disk_usage(project_record)
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

    analysis_output_filenames = [@analysis1_file_blob.filename, @analysis2_file_blob.filename]

    analysis_output_blobs_total_size = @analysis1_file_blob.byte_size + @analysis2_file_blob.byte_size

    existing_attachments_size = 0

    namespace_samples = workflow_execution.namespace.project.samples
    namespace_samples.each do |sample|
      sample.attachments.each do |att|
        existing_attachments_size += att.file.byte_size
      end
    end

    sample = samples(:sampleA)
    assert_equal 3, sample.attachments.count

    assert 'completing', workflow_execution.state

    assert WorkflowExecutions::CompletionService.new(workflow_execution, {}).execute

    assert_equal 'my_run_id_g', workflow_execution.run_id

    assert_equal 3, workflow_execution.outputs.count

    global_analysis_outputs = workflow_execution.outputs.reject { |o| o.file.filename == 'summary.txt' }

    global_output_size = 0

    global_analysis_outputs.each do |global_analysis_output|
      global_output_size += global_analysis_output.file.byte_size
    end

    size_with_duplicates = existing_attachments_size + global_output_size + analysis_output_blobs_total_size
    size_without_duplicates = existing_attachments_size + analysis_output_blobs_total_size

    assert size_without_duplicates < size_with_duplicates

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

    expected_disk_usage = number_to_human_size(
      size_without_duplicates, precision: 2, significant: false, strip_insignificant_zeros: false
    )

    assert_equal expected_disk_usage, namespace_calculated_disk_usage
  end

  private

  # Calculate the disk usage for unique attachment blobs under a namespace (namespace attachments, sample attachments,
  # sample workflow execution attachments)
  def calculate_disk_usage(namespace_or_project) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    namespace = namespace_or_project.is_a?(Project) ? namespace_or_project.namespace : namespace_or_project

    samples = []
    namespace.self_and_descendants.each do |ns|
      if namespace.group_namespace? || namespace.user_namespace?
        ns.project_namespaces.each do |pn|
          samples.concat(pn.project.samples) if pn.project.samples_count.positive?
        end
      elsif !ns.project.samples_count.nil? && ns.project.samples_count.positive?
        samples.concat(ns.project.samples)
      end
    end

    sample_ids = samples.map(&:id)
    namespace_ids = namespace.self_and_descendants_of_type(
      [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
    ).map(&:id)
    sample_workflow_execution_ids = SamplesWorkflowExecution.joins(:workflow_execution).where(
      sample_id: sample_ids,
      workflow_execution: {
        namespace_id: namespace.self_and_descendants_of_type(
          [Group.sti_name,
           Namespaces::ProjectNamespace.sti_name]
        ).select(:id)
      }
    ).pluck(:id)

    attachable_ids = sample_ids + namespace_ids + sample_workflow_execution_ids

    attachments = Attachment.where(attachable_id: attachable_ids)

    total_attachments_size = 0
    blob_ids = []
    attachments.each do |att|
      total_attachments_size += att.file.blob.byte_size if att.file&.blob && blob_ids.exclude?(att.file.blob_id)
      blob_ids << att.file.blob_id if att.file&.blob_id
    end

    number_to_human_size(
      total_attachments_size, precision: 2, significant: false, strip_insignificant_zeros: false
    )
  end
end
