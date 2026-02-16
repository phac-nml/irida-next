# frozen_string_literal: true

require 'test_helper'

class MetricsQueryTest < ActiveSupport::TestCase
  include ActionView::Helpers::NumberHelper

  GROUP_METRICS_QUERY = <<~GRAPHQL
    query($groupPath: ID!) {
      group(fullPath: $groupPath) {
        name
        metrics {
          projectCount
          samplesCount
          membersCount
          diskUsage
        }
      }
    }
  GRAPHQL

  NAMESPACE_PROJECTS_METRICS_QUERY = <<~GRAPHQL
    query($namespacePath: ID!, $include_sub_groups: Boolean) {
      namespace(fullPath: $namespacePath) {
        name
        projects(includeSubGroups: $include_sub_groups) {
          nodes {
            name
            metrics {
              projectCount
              samplesCount
              membersCount
              diskUsage
            }
          }
          totalCount
        }
      }
    }
  GRAPHQL

  PROJECT_METRICS_QUERY = <<~GRAPHQL
    query($projectPath: ID!) {
      project(fullPath: $projectPath) {
        id
        name
        metrics {
          projectCount
          samplesCount
          membersCount
          diskUsage
        }
      }
    }
  GRAPHQL

  GROUPS_QUERY_WITH_METRICS = <<~GRAPHQL
    query($first: Int, $last: Int) {
      groups(first: $first, last: $last) {
        nodes {
          id
          name
          metrics {
            projectCount
            samplesCount
            membersCount
            diskUsage
          }
        }
      }
    }
  GRAPHQL

  PROJECTS_QUERY_WITH_METRICS = <<~GRAPHQL
    query($last: Int) {
      projects(last: $last) {
        nodes {
          id
          name
          metrics {
            projectCount
            samplesCount
            membersCount
            diskUsage
          }
        }
      }
    }
  GRAPHQL

  GROUPS_WITH_NESTED_PROJECTS_METRICS = <<~GRAPHQL
    query($last: Int) {
      groups(last: $last) {
        nodes {
          id
          name
          fullPath
          projects(first: 10) {
            nodes {
              id
              name
              fullPath
              metrics {
                projectCount
                samplesCount
                membersCount
                diskUsage
              }
            }
          }
          metrics {
            projectCount
            samplesCount
            membersCount
            diskUsage
          }
        }
      }
    }
  GRAPHQL

  def setup
    @user_a = users(:john_doe)
    @user_b = users(:jane_doe)

    @user_b.update(system: true)
    setup_data
  end

  def teardown
    @user_b.update(system: false)
  end

  private

  def setup_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @group_a = groups(:group_one)

    @group_b = Groups::CreateService.new(@user_a,
                                         {
                                           name: 'Metrics Test Group B',
                                           path: "metrics-test-group-b-#{SecureRandom.hex(4)}",
                                           parent: @group_a,
                                           description: 'Group B as subgroup of Group A'
                                         }).execute

    Members::CreateService.new(@user_a, @group_b,
                               { user: @user_a,
                                 access_level: Member::AccessLevel::OWNER,
                                 created_by: @user_a }).execute

    @group_c = Groups::CreateService.new(@user_a,
                                         { name: 'Metrics Test Group C',
                                           path: "metrics-test-group-c-#{SecureRandom.hex(4)}",
                                           parent: @group_b,
                                           description: 'Group C as subgroup of Group B' }).execute

    Members::CreateService.new(@user_a, @group_c,
                               { user: @user_a,
                                 access_level: Member::AccessLevel::OWNER,
                                 created_by: @user_a }).execute

    valid_params = { namespace_attributes: {
      name: "Metrics Test GB Project #{SecureRandom.hex(4)}",
      path: "metrics-test-gb-project-#{SecureRandom.hex(4)}",
      parent_id: @group_b.id
    } }

    @group_b_project_1 = Projects::CreateService.new(@user_a, valid_params).execute # rubocop:disable Naming/VariableNumber

    Members::CreateService.new(@user_a, @group_b_project_1.namespace,
                               { user: @user_a, access_level: Member::AccessLevel::OWNER, created_by: @user_a }).execute

    valid_params = { name: 'Group B Project 1 Sample 1', project_id: @group_b_project_1.id }
    @group_b_project_1_sample_1 = Samples::CreateService.new(@user_a, @group_b_project_1, valid_params).execute # rubocop:disable Naming/VariableNumber

    valid_params = { namespace_attributes: { name: "Metrics Test GC Project #{SecureRandom.hex(4)}",
                                             path: "metrics-test-gc-project-#{SecureRandom.hex(4)}",
                                             parent_id: @group_c.id } }

    @group_c_project_1 = Projects::CreateService.new(@user_a, # rubocop:disable Naming/VariableNumber
                                                     valid_params).execute

    Members::CreateService.new(@user_a, @group_c_project_1.namespace,
                               { user: @user_a,
                                 access_level: Member::AccessLevel::OWNER,
                                 created_by: @user_a }).execute

    @group_c_project_1_sample_1 = Samples::CreateService.new(@user_a, @group_c_project_1, # rubocop:disable Naming/VariableNumber
                                                             { name: 'Group C Project 1 Sample 1' }).execute
  end

  def assert_all_true(hash, message)
    assert hash.values.all?, "#{message} - actual: #{hash}"
  end

  test 'group metrics returns project_count for group hierarchy' do
    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: @group_a.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    assert_not_nil data['projectCount'], 'projectCount should be present'
    assert_equal 23, data['projectCount'], 'Group A should have 23 projects in hierarchy'
  end

  test 'group metrics returns correct samples_count for group' do
    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: @group_a.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    assert_not_nil data['samplesCount'], 'samplesCount should be present'
    assert_equal 28, data['samplesCount'], 'Group A should have 28 samples'
  end

  test 'group metrics returns correct members_count including hierarchy' do
    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: @group_a.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    assert_not_nil data['membersCount'], 'membersCount should be present'
    # UserA is owner of Group A, Group B, and Group C
    # Members from ancestors are included
    assert_equal 4, data['membersCount'], 'Group A should have 4 members (UserA, James, UserB, and UserC)'
  end

  test 'group metrics returns disk usage including subgroups' do
    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: @group_a.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    assert_not_nil data['diskUsage'], 'diskUsage should be present'
    assert data['diskUsage'].present?, 'diskUsage should not be empty'
    assert_equal calculate_disk_usage(@group_a), data['diskUsage'], 'disk usage should be correct'
  end

  test 'subgroup metrics returns only its own and subgroups projects' do
    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: @group_b.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    # Group B has 1 project, and Group C (subgroup) has 1 project
    # Total = 2
    assert_equal 2, data['projectCount'], 'Group B should have 2 projects (itself and subgroup C)'
    # Group B has 1 sample in its project, Group C has 1 sample
    # Total = 2
    assert_equal 2, data['samplesCount'], 'Group B should have 2 samples'

    assert_equal 4, data['membersCount'],
                 'Group B (inherited from Group A) should have 4 members (UserA, James, UserB, and UserC)'
  end

  test 'group metrics returns zero for empty group' do
    random_id = SecureRandom.hex(4)

    valid_params = { name: "Metrics Test Empty Group-#{random_id}", path: "metrics-test-empty-group-#{random_id}",
                     parent_id: nil }

    empty_group = Groups::CreateService.new(@user_b, valid_params).execute

    Members::CreateService.new(@user_b, empty_group,
                               { user: @user_a,
                                 access_level: Member::AccessLevel::OWNER,
                                 created_by: @user_a }).execute

    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_b },
                                                      variables: { groupPath: empty_group.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['group']['metrics']

    assert_equal 0, data['projectCount'], 'empty group should have 0 projects'
    assert_equal 0, data['samplesCount'], 'empty group should have 0 samples'
    assert_equal 2, data['membersCount'], 'empty group should have 2 members (UserA and UserB)'
    assert_equal '0 Bytes', data['diskUsage'], 'empty group should have 0 disk usage'
  end

  test 'group metrics authorization - unauthorized user cannot view metrics' do
    random_id = SecureRandom.hex(4)

    valid_params = { name: "Metrics Test User B Group-#{random_id}", path: "metrics-test-userb-group-#{random_id}",
                     parent_id: nil }

    user_b_group = Groups::CreateService.new(@user_b, valid_params).execute

    result = IridaSchema.execute(GROUP_METRICS_QUERY, context: { current_user: @user_a },
                                                      variables: { groupPath: user_b_group.full_path })

    # Unauthorized user should not be able to access group in which they are not a member
    assert_not_nil result['errors'], 'should have authorization errors'
  end

  test 'project metrics returns nil project_count for project' do
    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: @group_b_project_1.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    assert_nil data['projectCount'], 'projectCount should be nil for projects'
  end

  test 'project metrics returns correct samples_count' do
    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: @group_b_project_1.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    assert_equal 1, data['samplesCount'], 'Project should have 1 sample'
  end

  test 'project metrics returns members_count including group members' do
    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: @group_b_project_1.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    # Project is in Group B, so should count members from ancestors
    assert_not_nil data['membersCount'], 'membersCount should be present'
    assert_equal 4, data['membersCount'], 'membersCount should be 4'
  end

  test 'project metrics returns disk usage for project' do
    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: @group_b_project_1.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    assert_not_nil data['diskUsage'], 'diskUsage should be present'
    assert_equal calculate_disk_usage(@group_b_project_1.namespace), data['diskUsage'], 'diskUsage should be 0 Bytes'
  end

  test 'project metrics for empty project' do
    random_id = SecureRandom.hex(4)
    valid_params = { namespace_attributes: { name: "Metrics Test Empty Project #{random_id}",
                                             path: "metrics-test-empty-project-#{random_id}",
                                             parent_id: @group_a.id,
                                             owner: @user_a } }

    empty_project = Projects::CreateService.new(@user_a,
                                                valid_params).execute

    Members::CreateService.new(@user_a, empty_project.namespace,
                               { user: @user_a,
                                 access_level: Member::AccessLevel::OWNER,
                                 created_by: @user_a }).execute

    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: empty_project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    assert_equal 0, data['samplesCount'], 'empty project should have 0 samples'
    assert data['diskUsage'].present?, 'diskUsage should be present even if empty'
    assert_equal '0 Bytes', data['diskUsage'],
                 'empty project should have 0 disk usage'
    assert_equal 4, data['membersCount'], 'empty project should have 4 members (inherited from Group A)'
  end

  test 'project metrics authorization - user can view metrics for their projects via ownership or member inheritance' do
    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_a },
                                                        variables: { projectPath: @group_b_project_1.full_path })

    assert_nil result['errors'], 'should work and have no errors'
    assert_not_nil result['data']['project'], 'should return project data'
  end

  test 'project metrics authorization - system user can view metrics for any project via direct access' do
    random_id = SecureRandom.hex(4)

    valid_params = {
      namespace_attributes: {
        name: "Metrics Test UserB Only Project-#{random_id}",
        path: "metrics-test-userb-only-project-#{random_id}",
        parent_id: @user_b.namespace.id
      }
    }

    user_project = Projects::CreateService.new(@user_b, valid_params).execute

    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_b },
                                                        variables: { projectPath: user_project.full_path })

    assert_nil result['errors'], 'should not have authorization errors'

    data = result['data']['project']

    assert_not_empty data, 'project type should work'
    assert data['metrics'].present?, 'metrics should be present'
    assert_equal 0, data['metrics']['samplesCount'], 'should have 0 samples'
    assert_nil data['metrics']['projectCount'], 'projectCount should be nil for projects'
    assert_equal 1, data['metrics']['membersCount'], 'should have 1 member (the owner of the project)'
    assert_equal calculate_disk_usage(user_project.namespace), data['metrics']['diskUsage'], 'should have 0 disk usage'
  end

  test 'groups query returns metrics for group' do
    total_attachment_size = calculate_disk_usage(@group_a)

    result = IridaSchema.execute(GROUPS_QUERY_WITH_METRICS, context: { current_user: @user_b },
                                                            variables: { last: 50 })

    assert_nil result['errors'], 'should work and have no errors.'
    groups = result['data']['groups']['nodes']

    assert groups.any? { |g| g['name'] == @group_a.name }, 'should include Group One'

    group_a_data = groups.find { |g| g['name'] == @group_a.name }

    assert_not_nil group_a_data['metrics'], 'Group One should have metrics'
    assert_not_nil group_a_data['metrics']['projectCount'], 'metrics should include projectCount'
    assert_equal 23, group_a_data['metrics']['projectCount'], 'Group One should have 23 projects in hierarchy'
    assert_not_nil group_a_data['metrics']['samplesCount'], 'metrics should include samplesCount'
    assert_equal 28, group_a_data['metrics']['samplesCount'],
                 'Group One should have 28 samples including shared groups/projects'
    assert_not_nil group_a_data['metrics']['membersCount'], 'metrics should include membersCount'
    assert_equal 4, group_a_data['metrics']['membersCount'],
                 'Group One should have 4 members (UserA, James, UserB, and UserC)'
    assert_not_nil group_a_data['metrics']['diskUsage'], 'metrics should include diskUsage'
    assert_equal total_attachment_size, group_a_data['metrics']['diskUsage'], 'disk usage should be correct'
  end

  test 'projects query returns metrics for multiple projects' do
    result = IridaSchema.execute(PROJECTS_QUERY_WITH_METRICS, context: { current_user: @user_b },
                                                              variables: { last: 5 })

    assert_nil result['errors'], 'should work and have no errors.'
    projects = result['data']['projects']['nodes']

    assert projects.many?, 'should return multiple projects'

    assert projects.any? { |p| p['name'] == @group_b_project_1.name }, "should include #{@group_b_project_1.name}"

    project_data = projects.find { |p| p['name'] == @group_b_project_1.name }
    assert_not_nil project_data['metrics'], 'project should have metrics'
    assert_not_nil project_data['metrics']['samplesCount'], 'metrics should include samplesCount'
    assert_not_nil project_data['metrics']['membersCount'], 'metrics should include membersCount'
    assert_not_nil project_data['metrics']['diskUsage'], 'metrics should include diskUsage'
  end

  test 'iterate groups query to access nested project metrics in subgroups' do
    result = IridaSchema.execute(GROUPS_WITH_NESTED_PROJECTS_METRICS, context: { current_user: @user_b },
                                                                      variables: { last: 5 })

    assert_nil result['errors'], 'should work and have no errors.'

    # Find Group B in the results
    groups = result['data']['groups']['nodes']
    group_b_data = groups.find { |g| g['fullPath'] == @group_b.full_path }

    assert_not_nil group_b_data, 'Group B should be in results'

    # Access nested projects from Group B
    group_b_projects = group_b_data['projects']['nodes']
    assert_not_nil group_b_projects, 'Group B should have projects array'
    assert group_b_projects.any? { |p| p['name'] == @group_b_project_1.name },
           'Group B should contain Project 1'

    # Verify project metrics are accessible within group context
    project_metrics = group_b_projects.find { |p| p['name'] == @group_b_project_1.name }['metrics']
    assert_not_nil project_metrics, 'project metrics should be accessible'
    assert_equal 1, project_metrics['samplesCount'], 'Project should have 1 sample'
  end

  test 'iterate through groups hierarchy to verify metrics at each level' do
    result = IridaSchema.execute(GROUPS_WITH_NESTED_PROJECTS_METRICS, context: { current_user: @user_b },
                                                                      variables: { last: 50 }, max_complexity: 10_000)

    assert_nil result['errors'], 'should work and have no errors.'
    groups = result['data']['groups']['nodes']

    # Verify Group A metrics
    group_a_data = groups.find { |g| g['fullPath'] == @group_a.full_path }
    assert_equal 23, group_a_data['metrics']['projectCount'],
                 'Group A should have 23 projects in hierarchy'
    assert_equal 28, group_a_data['metrics']['samplesCount'],
                 'Group A should have 28 samples total'
    assert_equal 4, group_a_data['metrics']['membersCount'], 'Group A should have 4 members'

    # Verify Group B metrics (subgroup of A)
    group_b_data = groups.find { |g| g['fullPath'] == @group_b.full_path }
    assert_equal 2, group_b_data['metrics']['projectCount'],
                 'Group B should have 2 projects (itself and subgroup C)'
    assert_equal 2, group_b_data['metrics']['samplesCount'],
                 'Group B should have 2 samples total'
    assert_equal 4, group_b_data['metrics']['membersCount'], 'Group B (subgroup of group a) should have 4 members'

    # Verify Group C metrics (subgroup of B)
    group_c_data = groups.find { |g| g['fullPath'] == @group_c.full_path }
    assert_equal 1, group_c_data['metrics']['projectCount'],
                 'Group C should have 1 project'
    assert_equal 1, group_c_data['metrics']['samplesCount'],
                 'Group C should have 1 sample total'
    assert_equal 4, group_c_data['metrics']['membersCount'], 'Group C (subgroup of group b) should have 4 members'
  end

  test 'system user can access all projects under a group and subgroups through iteration' do
    result = IridaSchema.execute(NAMESPACE_PROJECTS_METRICS_QUERY, context: { current_user: @user_b },
                                                                   variables: {
                                                                     namespacePath: @group_a.full_path,
                                                                     include_sub_groups: true
                                                                   })

    assert_nil result['errors'], 'should work and have no errors.'

    projects_data = result['data']['namespace']['projects']

    assert projects_data.many?, 'should return projects data'

    # Verify all projects under group A and subgroups are accessible
    all_projects = projects_data['nodes']
    project_names = all_projects.pluck('name')

    assert project_names.include?(@group_b_project_1.name), 'should see Group B Project'
    assert project_names.include?(@group_c_project_1.name), 'should see Group C Project'
  end

  test 'iterate groups query returns project metrics without exposing samples' do
    result = IridaSchema.execute(GROUPS_WITH_NESTED_PROJECTS_METRICS, context: { current_user: @user_b },
                                                                      variables: { last: 2 })

    assert_nil result['errors'], 'should work and have no errors.'
    groups = result['data']['groups']['nodes']

    # Get a project from the results
    all_projects = groups.flat_map { |g| g['projects']['nodes'] }
    project_data = all_projects.find { |p| p['name'] == @group_b_project_1.name }

    # Project metrics should be accessible
    assert_not_nil project_data['metrics'], 'project metrics should be included'
    assert_equal 1, project_data['metrics']['samplesCount'],
                 'metrics should show sample count without exposing samples'

    # The response should NOT include samples array itself
    assert_nil project_data['samples'], 'samples array should not be exposed in this query'
  end

  test 'projects within groups/subgroups show correct metrics from group context' do
    result = IridaSchema.execute(GROUPS_WITH_NESTED_PROJECTS_METRICS, context: { current_user: @user_b },
                                                                      variables: { last: 2 })

    assert_nil result['errors'], 'should work and have no errors.'
    groups = result['data']['groups']['nodes']

    # Get Group C data
    group_c_data = groups.find { |g| g['fullPath'] == @group_c.full_path }
    group_c_projects = group_c_data['projects']['nodes']

    # Group C should have its own project
    assert_equal 1, group_c_projects.length, 'Group C should have 1 project'

    # Verify project metrics from group context
    group_c_project = group_c_projects[0]
    assert_equal @group_c_project_1.name, group_c_project['name']
    assert_equal 1, group_c_project['metrics']['samplesCount'],
                 'Group C Project should have 1 sample'
    assert_equal 4, group_c_project['metrics']['membersCount'],
                 'Group C Project should have 4 members (inherited from Group A)'
    assert_equal '0 Bytes', group_c_project['metrics']['diskUsage'],
                 'Group C Project should have 0 disk usage'
  end

  # Edge case tests

  test 'project in user namespace has correct members count' do
    random_id = SecureRandom.hex(4)

    valid_params = {
      namespace_attributes: {
        name: "Metrics Test UserA Personal Project-#{random_id}",
        path: "metrics-test-usera-personal-project-#{random_id}",
        parent_id: @user_a.namespace.id
      }
    }

    user_project = Projects::CreateService.new(@user_a, valid_params).execute

    result = IridaSchema.execute(PROJECT_METRICS_QUERY, context: { current_user: @user_a },
                                                        variables: { projectPath: user_project.full_path })

    assert_nil result['errors'], 'should work and have no errors.'
    data = result['data']['project']['metrics']

    # For user namespace projects, should count project members + owner
    assert_not_nil data['membersCount'], 'membersCount should be present'

    assert data['membersCount'] == 1, 'should have at least the owner'
  end

  def calculate_disk_usage(namespace) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    samples = []
    namespace.self_and_descendants.each do |ns|
      if namespace.group_namespace?
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
