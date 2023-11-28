# frozen_string_literal: true

require 'test_helper'

class SamplePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @policy = SamplePolicy.new(@group, user: @user)
  end

  test 'scope' do
    scoped_samples = @policy.apply_scope(Sample, type: :relation, scope_options: { group: @group })

    projects_samples_count = 0
    group_self_and_descendants = @group.self_and_descendants

    # Sample counts from projects belonging to group and it's descendants
    group_self_and_descendants.each do |group|
      group.project_namespaces.each do |project_namespace|
        projects_samples_count += project_namespace.project.samples.count
      end
    end

    namespace_group_links = NamespaceGroupLink.where(group: group_self_and_descendants)

    # Sample counts from projects belonging to group and it's descendants via namespace group links
    namespace_group_links.each do |namespace_group_link|
      if namespace_group_link.namespace_type == Namespaces::ProjectNamespace.sti_name
        projects_samples_count += namespace_group_link.namespace.project.samples.count
      else
        group_self_and_descendants = namespace_group_link.namespace.self_and_descendants

        group_self_and_descendants.each do |group|
          group.project_namespaces.each do |project_namespace|
            projects_samples_count += project_namespace.project.samples.count
          end
        end
      end
    end

    assert_equal projects_samples_count, scoped_samples.count
  end
end
