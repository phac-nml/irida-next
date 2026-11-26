# frozen_string_literal: true

FixtureBot.define do
  metadata_template :valid_metadata_template do
    name 'Valid Template'
    description 'This is a valid template.'
    fields(%w[metadatafield2 metadatafield1])
    created_at '<%= 3.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    created_by :john_doe
  end

  metadata_template :valid_group_metadata_template do
    name 'Valid Group Template'
    description 'This is a valid group template.'
    fields(%w[metadatafield1 metadatafield2])
    created_at '<%= 3.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    created_by :john_doe
  end

  2.times do |n|
    metadata_template(:"project1_metadata_template#{n}") do
      name "Project Template#{n}"
      description "This is template #{n} for the project"
      fields(["metadatafield#{n + 1}"])
      created_at "<%= #{n + 3}.hours.ago %>"
      namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
      created_by :joan_doe
    end
  end

  2.times do |n|
    metadata_template(:"group_one_metadata_template#{n}") do
      name "Group Template#{n}"
      description "This is template #{n} for the group"
      fields(["metadatafield#{n + 1}"])
      created_at "<%= #{n + 3}.hours.ago %>"
      namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
      created_by :joan_doe
    end
  end

  metadata_template :project2_metadata_template1 do
    name 'First Project Template'
    description 'This is template 1 for the project"'
    fields(%w[field_a1 field_a2 field_a3])
    created_at '<%= 2.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    created_by :john_doe
  end

  metadata_template :project2_metadata_template2 do
    name 'Second Project Template'
    description 'This is template 2 for the project"'
    fields(%w[field_b1 field_b2 field_b3])
    created_at '<%= 4.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    created_by :joan_doe
  end

  metadata_template :group_two_metadata_template1 do
    name 'First Group Template'
    description 'This is template 1 for the group'
    fields(%w[field_c1 field_c2 field_c3])
    created_at '<%= 2.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_two)
    created_by :joan_doe
  end

  metadata_template :group_two_metadata_template2 do
    name 'Second Group Template'
    description 'This is template 2 for the group'
    fields(%w[field_d1 field_d2 field_d3])
    # NOTE: reproduces a pre-existing typo in the original fixture, where a stray "("
    # (leftover from an unclosed ERB tag) precedes the ERB tag. Rails' timestamp type
    # casting tolerates/ignores the leading "(", so the effective value is unaffected.
    created_at '(<%= 3.hours.ago %>'
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_two)
    created_by :john_doe
  end
end
