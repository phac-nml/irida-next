# frozen_string_literal: true

FixtureBot.define do
  namespace_group_link :namespace_group_link1 do
    group_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project20_namespace, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link2 do
    group_id ActiveRecord::FixtureSet.identify(:group_three, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup1, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link3 do
    group_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project25_namespace, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link4 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup1, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:david_doe_group_four, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link5 do
    group_id ActiveRecord::FixtureSet.identify(:david_doe_group_four, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link6 do
    group_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup1, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link7 do
    group_id ActiveRecord::FixtureSet.identify(:group_six, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup2, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link8 do
    group_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_two, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_one, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link9 do
    group_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_two, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link10 do
    group_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_two, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_one_project1_namespace, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link11 do
    group_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three_project1_namespace, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link12 do
    group_id ActiveRecord::FixtureSet.identify(:group_alpha, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectBravo_namespace, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link13 do
    group_id ActiveRecord::FixtureSet.identify(:group_alpha, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_charlie, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link14 do
    group_id ActiveRecord::FixtureSet.identify(:group_eleven, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link15 do
    group_id ActiveRecord::FixtureSet.identify(:group_delta_subgroupA, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_echo, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link16 do
    group_id ActiveRecord::FixtureSet.identify(:group_golf, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectFoxtrotSubgroupA_namespace, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link17 do
    group_id ActiveRecord::FixtureSet.identify(:user30_group_one, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:user29_project1_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link18 do
    group_id ActiveRecord::FixtureSet.identify(:group_charlie, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link19 do
    group_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link20 do
    group_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link21 do
    group_id ActiveRecord::FixtureSet.identify(:group_india, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectIndia1_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link22 do
    group_id ActiveRecord::FixtureSet.identify(:group_juliett, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_juliett_subgroup1, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link23 do
    group_id ActiveRecord::FixtureSet.identify(:group_kilo, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link24 do
    group_id ActiveRecord::FixtureSet.identify(:group_lima, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link25 do
    group_id ActiveRecord::FixtureSet.identify(:group_lima, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_twelve_a, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link26 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_mike_a, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_mike, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link27 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_mike_a_a, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMike_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link28 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_mike_b, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
    expires_at '2025-01-01'
  end

  namespace_group_link :namespace_group_link29 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_oscar_a, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_twelve_a_a, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link30 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_oscar_a, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project30_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link31 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_papa_a, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_lima, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link32 do
    group_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_owner, :uuid)
    group_access_level Member::AccessLevel::OWNER
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link33 do
    group_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_maintainer, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link34 do
    group_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_analyst, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link35 do
    group_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_guest, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Group'
  end

  namespace_group_link :namespace_group_link36 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_owner_namespace, :uuid)
    group_access_level Member::AccessLevel::OWNER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link37 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_maintainer_namespace, :uuid)
    group_access_level Member::AccessLevel::MAINTAINER
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link38 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_analyst_namespace, :uuid)
    group_access_level Member::AccessLevel::ANALYST
    namespace_type 'Project'
  end

  namespace_group_link :namespace_group_link39 do
    group_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_guest_namespace, :uuid)
    group_access_level Member::AccessLevel::GUEST
    namespace_type 'Project'
  end
end
