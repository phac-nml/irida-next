# frozen_string_literal: true

FixtureBot.define do
  namespace_group_link.group_access_level { Member::AccessLevel::ANALYST }
  namespace_group_link.namespace_type { 'Group' }

  namespace_group_link :namespace_group_link1 do
    group :group_one
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project20_namespace)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link2 do
    group :group_three
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup1)
  end

  namespace_group_link :namespace_group_link3 do
    group :group_five
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project25_namespace)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link4 do
    group :subgroup1
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :david_doe_group_four)
  end

  namespace_group_link :namespace_group_link5 do
    group :david_doe_group_four
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link6 do
    group :group_five
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup1)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link7 do
    group :group_six
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup2)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link8 do
    group :namespace_group_link_group_two
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_one)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link9 do
    group :namespace_group_link_group_three
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_two)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link10 do
    group :namespace_group_link_group_two
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :namespace_group_link_group_one_project1_namespace)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link11 do
    group :namespace_group_link_group_three
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :namespace_group_link_group_three_project1_namespace)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link12 do
    group :group_alpha
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectBravo_namespace)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link13 do
    group :group_alpha
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_charlie)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link14 do
    group :group_eleven
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    group_access_level Member::AccessLevel::MAINTAINER
  end

  namespace_group_link :namespace_group_link15 do
    group :group_delta_subgroupA
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_echo)
    group_access_level Member::AccessLevel::MAINTAINER
  end

  namespace_group_link :namespace_group_link16 do
    group :group_golf
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectFoxtrotSubgroupA_namespace)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link17 do
    group :user30_group_one
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :user29_project1_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link18 do
    group :group_charlie
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link19 do
    group :group_five
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
  end

  namespace_group_link :namespace_group_link20 do
    group :group_five
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link21 do
    group :group_india
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectIndia1_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link22 do
    group :group_juliett
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_juliett_subgroup1)
  end

  namespace_group_link :namespace_group_link23 do
    group :group_kilo
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
  end

  namespace_group_link :namespace_group_link24 do
    group :group_lima
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
  end

  namespace_group_link :namespace_group_link25 do
    group :group_lima
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_twelve_a)
  end

  namespace_group_link :namespace_group_link26 do
    group :subgroup_mike_a
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_mike)
  end

  namespace_group_link :namespace_group_link27 do
    group :subgroup_mike_a_a
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMike_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link28 do
    group :subgroup_mike_b
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
    expires_at '2025-01-01'
  end

  namespace_group_link :namespace_group_link29 do
    group :subgroup_oscar_a
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_twelve_a_a)
  end

  namespace_group_link :namespace_group_link30 do
    group :subgroup_oscar_a
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project30_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link31 do
    group :subgroup_papa_a
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_lima)
  end

  namespace_group_link :namespace_group_link32 do
    group :group_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_owner)
    group_access_level Member::AccessLevel::OWNER
  end

  namespace_group_link :namespace_group_link33 do
    group :group_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_maintainer)
    group_access_level Member::AccessLevel::MAINTAINER
  end

  namespace_group_link :namespace_group_link34 do
    group :group_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_analyst)
  end

  namespace_group_link :namespace_group_link35 do
    group :group_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_guest)
    group_access_level Member::AccessLevel::GUEST
  end

  namespace_group_link :namespace_group_link36 do
    group :subgroup_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_shared_group_sample_actions_owner_namespace)
    group_access_level Member::AccessLevel::OWNER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link37 do
    group :subgroup_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_shared_group_sample_actions_maintainer_namespace)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link38 do
    group :subgroup_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_shared_group_sample_actions_analyst_namespace)
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link39 do
    group :subgroup_sample_actions
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                                :project_shared_group_sample_actions_guest_namespace)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Project'
  end
end
