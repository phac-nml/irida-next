# frozen_string_literal: true

FixtureBot.define do
  route :group_one_route do
    name 'Group 1'
    path 'group-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    source_type 'Namespace'
  end

  route :subgroup1_route do
    name 'Group 1 / Subgroup 1'
    path 'group-1/subgroup-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup1)
    source_type 'Namespace'
  end

  (Namespace::MAX_ANCESTORS - 2).times do |n|
    route(:"subgroup#{n + 2}_route") do
      name "Group 1 / #{(n + 2).times.map { |i| "Subgroup #{i + 1}" }.join(' / ')}"
      path "group-1/#{(n + 2).times.map { |i| "subgroup-#{i + 1}" }.join('/')}"
      source_id FixtureBot::Key::Uuid.generate(:groups, :"subgroup#{n + 2}")
      source_type 'Namespace'
    end
  end

  route :john_doe_namespace_route do
    name 'john.doe@localhost'
    path 'john.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :john_doe_namespace)
    source_type 'Namespace'
  end

  route :jeff_doe_namespace_route do
    name 'jeff.doe@localhost'
    path 'jeff.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :jeff_doe_namespace)
    source_type 'Namespace'
  end

  route :jeff_doe_projectA_namespace_route_namespace_route do
    name 'jeff.doe@localhost / Project A'
    path 'jeff.doe_at_localhost/project-a'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    source_type 'Namespace'
  end

  route :jeff_doe_project_namespace_route_namespace_route do
    name 'jeff.doe@localhost / Project Uncounted'
    path 'jeff.doe_at_localhost/project-uncounted'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_jeff_namespace)
    source_type 'Namespace'
  end

  route :jane_doe_namespace_route do
    name 'jane.doe@localhost'
    path 'jane.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :jane_doe_namespace)
    source_type 'Namespace'
  end

  route :jean_doe_namespace_route do
    name 'jean.doe@localhost'
    path 'jean.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :jean_doe_namespace)
    source_type 'Namespace'
  end

  route :james_doe_namespace_route do
    name 'james.doe@localhost'
    path 'james.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :james_doe_namespace)
    source_type 'Namespace'
  end

  route :user_25_namespace_route do
    name 'user.25@localhost'
    path 'user.25_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user_25_namespace)
    source_type 'Namespace'
  end

  route :user_26_namespace_route do
    name 'user.26@localhost'
    path 'user.26_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user_26_namespace)
    source_type 'Namespace'
  end

  route :user_27_namespace_route do
    name 'user.27@localhost'
    path 'user.27_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user27_namespace)
    source_type 'Namespace'
  end

  route :user_28_namespace_route do
    name 'user.28@localhost'
    path 'user.28_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user28_namespace)
    source_type 'Namespace'
  end

  route :private_joan_namespace_route do
    name 'private.joan@localhost'
    path 'private.joan_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :private_joan_namespace)
    source_type 'Namespace'
  end

  route :private_ryan_namespace_route do
    name 'private.ryan@localhost'
    path 'private.ryan_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :private_ryan_namespace)
    source_type 'Namespace'
  end

  route :private_micha_namespace_route do
    name 'private.micha@localhost'
    path 'private.micha_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :private_micha_namespace)
    source_type 'Namespace'
  end

  route :project1_namespace_route do
    name 'Group 1 / Project 1'
    path 'group-1/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    source_type 'Namespace'
  end

  route :project2_namespace_route do
    name 'Group 1 / Project 2'
    path 'group-1/project-2'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    source_type 'Namespace'
  end

  route :john_doe_project2_namespace_route do
    name 'john.doe@localhost / Project 2'
    path 'john.doe_at_localhost/project-2'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    source_type 'Namespace'
  end

  route :project3_namespace_route do
    name 'john.doe@localhost / Project 3'
    path 'john.doe_at_localhost/project-3'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project3_namespace)
    source_type 'Namespace'
  end

  route :project4_namespace_route do
    name 'Group 3 / Subgroup 1 Group 3 / Project 4'
    path 'group-3/subgroup-1-group-3/project-4'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project4_namespace)
    source_type 'Namespace'
  end

  route :project5_namespace_route do
    name 'Group 1 / Project 5'
    path 'group-1/project-5'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project5_namespace)
    source_type 'Namespace'
  end

  route :project6_namespace_route do
    name 'Group 1 / Project 6'
    path 'group-1/project-6'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project6_namespace)
    source_type 'Namespace'
  end

  route :project7_namespace_route do
    name 'Group 1 / Project 7'
    path 'group-1/project-7'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project7_namespace)
    source_type 'Namespace'
  end

  route :project8_namespace_route do
    name 'Group 1 / Project 8'
    path 'group-1/project-8'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project8_namespace)
    source_type 'Namespace'
  end

  route :project9_namespace_route do
    name 'Group 1 / Project 9'
    path 'group-1/project-9'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project9_namespace)
    source_type 'Namespace'
  end

  route :project10_namespace_route do
    name 'Group 1 / Project 10'
    path 'group-1/project-10'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project10_namespace)
    source_type 'Namespace'
  end

  route :project11_namespace_route do
    name 'Group 1 / Project 11'
    path 'group-1/project-11'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project11_namespace)
    source_type 'Namespace'
  end

  route :project12_namespace_route do
    name 'Group 1 / Project 12'
    path 'group-1/project-12'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project12_namespace)
    source_type 'Namespace'
  end

  route :project13_namespace_route do
    name 'Group 1 / Project 13'
    path 'group-1/project-13'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project13_namespace)
    source_type 'Namespace'
  end

  route :project14_namespace_route do
    name 'Group 1 / Project 14'
    path 'group-1/project-14'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project14_namespace)
    source_type 'Namespace'
  end

  route :project15_namespace_route do
    name 'Group 1 / Project 15'
    path 'group-1/project-15'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project15_namespace)
    source_type 'Namespace'
  end

  route :project16_namespace_route do
    name 'Group 1 / Project 16'
    path 'group-1/project-16'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project16_namespace)
    source_type 'Namespace'
  end

  route :project17_namespace_route do
    name 'Group 1 / Project 17'
    path 'group-1/project-17'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project17_namespace)
    source_type 'Namespace'
  end

  route :project18_namespace_route do
    name 'Group 1 / Project 18'
    path 'group-1/project-18'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project18_namespace)
    source_type 'Namespace'
  end

  route :project19_namespace_route do
    name 'Group 1 / Project 19'
    path 'group-1/project-19'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project19_namespace)
    source_type 'Namespace'
  end

  route :group_two_route do
    name 'Group 2'
    path 'group-2'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_two)
    source_type 'Namespace'
  end

  route :group_three_route do
    name 'Group 3'
    path 'group-3'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_three)
    source_type 'Namespace'
  end

  route :subgroup_one_group_three_route do
    name 'Group 3 / Subgroup 1 Group 3'
    path 'group-3/subgroup-1-group-3'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_three)
    source_type 'Namespace'
  end

  route :john_doe_project4_namespace_route do
    name 'john.doe@localhost / Project 4'
    path 'john.doe_at_localhost/project-4'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project4_namespace)
    source_type 'Namespace'
  end

  route :david_doe_namespace_route do
    name 'david.doe@localhost'
    path 'david.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :david_doe_namespace)
    source_type 'Namespace'
  end

  route :alph_abet_namespace_route do
    name 'alph.abet@localhost'
    path 'alph.abet_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :alph_abet_namespace)
    source_type 'Namespace'
  end

  route :david_doe_group_four_route do
    name 'Group 4'
    path 'group-4'
    source_id FixtureBot::Key::Uuid.generate(:groups, :david_doe_group_four)
    source_type 'Namespace'
  end

  route :group_five_route do
    name 'Group 5'
    path 'group-5'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
    source_type 'Namespace'
  end

  route :project22_namespace_route do
    name 'Group 5 / Project 22'
    path 'group-5/project-22'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    source_type 'Namespace'
  end

  route :subgroup_one_group_five_route do
    name 'Group 5 / Subgroup 1 Group 5'
    path 'group-5/subgroup-1-group-5'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_five)
    source_type 'Namespace'
  end

  route :group_six_route do
    name 'Group 6'
    path 'group-6'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_six)
    source_type 'Namespace'
  end

  route :project20_namespace_route do
    name 'Group 1 / Project 20'
    path 'group-1/project-20'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project20_namespace)
    source_type 'Namespace'
  end

  route :project21_namespace_route do
    name 'Group 1 / Project 21'
    path 'group-1/project-21'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project21_namespace)
    source_type 'Namespace'
  end

  route :project23_namespace_route do
    name 'Group 6 / Project 23'
    path 'group-6/project-23'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project23_namespace)
    source_type 'Namespace'
  end

  route :project24_namespace_route do
    name 'Group 1 / Project 24'
    path 'group-1/project-24'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project24_namespace)
    source_type 'Namespace'
  end

  route :project25_namespace_route do
    name 'Group 1 / Subgroup 1 / Project 25'
    path 'group-1/subgroup-1/project-25'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project25_namespace)
    source_type 'Namespace'
  end

  route :group_seven_route do
    name 'Group 7'
    path 'group-7'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_seven)
    source_type 'Namespace'
  end

  route :project26_namespace_route do
    name 'john.doe@localhost / Project 26'
    path 'john.doe_at_localhost/project-26'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project26_namespace)
    source_type 'Namespace'
  end

  route :project32_namespace_route do
    name 'Group 8 / Project 32'
    path 'group-8/project-32'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project32_namespace)
    source_type 'Namespace'
  end

  [*('a'..'z')].each do |letter|
    route(:"group_#{letter}_route") do
      name "Group #{letter.capitalize}"
      path "group-#{letter}"
      source_id FixtureBot::Key::Uuid.generate(:groups, :"group_#{letter}")
      source_type 'Namespace'
    end
  end

  route :namespace_group_link_group_one_route do
    name 'Group One'
    path 'group-one'
    source_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_one)
    source_type 'Namespace'
  end

  route :namespace_group_link_group_two_route do
    name 'Group Two'
    path 'group-two'
    source_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_two)
    source_type 'Namespace'
  end

  route :namespace_group_link_group_three_route do
    name 'Group Three'
    path 'group-three'
    source_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_three)
    source_type 'Namespace'
  end

  route :namespace_group_link_group_one_project1_namespace_route do
    name 'Group One / Project 1'
    path 'group-one/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :namespace_group_link_group_one_project1_namespace)
    source_type 'Namespace'
  end

  route :namespace_group_link_group_three_project1_namespace_route do
    name 'Group Three / Project 1'
    path 'group-three/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :namespace_group_link_group_three_project1_namespace)
    source_type 'Namespace'
  end

  route :group_eight_route do
    name 'Group 8'
    path 'group-8'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_eight)
    source_type 'Namespace'
  end

  route :group_nine_route do
    name 'Group 9'
    path 'group-9'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_nine)
    source_type 'Namespace'
  end

  route :subgroup_one_group_nine_route do
    name 'Group 9 / Subgroup 1 Group 9'
    path 'group-9/subgroup-1-group-9'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_nine)
    source_type 'Namespace'
  end

  route :group_ten_route do
    name 'Group 10'
    path 'group-9/subgroup-1-group-9/group-10'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_ten)
    source_type 'Namespace'
  end

  route :project28_namespace_route do
    name 'Group 4 / Project 28'
    path 'group-4/project-28'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project28_namespace)
    source_type 'Namespace'
  end

  route :group_alpha_route do
    name 'Group Alpha'
    path 'group-alpha'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_alpha)
    source_type 'Namespace'
  end

  route :group_bravo_route do
    name 'Group Bravo'
    path 'group-bravo'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_bravo)
    source_type 'Namespace'
  end

  route :group_charlie_route do
    name 'Group Charlie'
    path 'group-charlie'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_charlie)
    source_type 'Namespace'
  end

  route :group_alpha_namespace_route do
    name 'Group Alpha / Project Alpha'
    path 'group-alpha/project-alpha'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectAlpha_namespace)
    source_type 'Namespace'
  end

  route :group_bravo_namespace_route do
    name 'Group Bravo / Project Bravo'
    path 'group-bravo/project-bravo'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectBravo_namespace)
    source_type 'Namespace'
  end

  route :group_charlie_namespace_route do
    name 'Group Charlie / Project Charlie'
    path 'group-charlie/project-charlie'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectCharlie_namespace)
    source_type 'Namespace'
  end

  route :subgroup_one_group_alpha_route do
    name 'Group Alpha / Subgroup 1'
    path 'group-alpha/subgroup-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_alpha_subgroup1)
    source_type 'Namespace'
  end

  route :project_alpha_1_namespace_route do
    name 'Group Alpha / Subgroup 1 / Project Alpha 1'
    path 'group-alpha/subgroup-1/project-alpha1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectAlpha1_namespace)
    source_type 'Namespace'
  end

  route :group_eleven_route do
    name 'Group 11'
    path 'group-11'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_eleven)
    source_type 'Namespace'
  end

  route :group_twelve_route do
    name 'Group 12'
    path 'group-12'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
    source_type 'Namespace'
  end

  route :subgroup_twelve_a_route do
    name 'Group 12 / Subgroup 12 A'
    path 'group-12/subgroup-12-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_twelve_a)
    source_type 'Namespace'
  end

  route :subgroup_twelve_b_route do
    name 'Group 12 / Subgroup 12 B'
    path 'group-12/subgroup-12-b'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_twelve_b)
    source_type 'Namespace'
  end

  route :subgroup_twelve_a_a_route do
    name 'Group 12 / Subgroup 12 A / Subgroup 12 AA'
    path 'group-12/subgroup-12-a/subgroup-12-a-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_twelve_a_a)
    source_type 'Namespace'
  end

  route :project29_namespace_route do
    name 'Group 12 / Subgroup 12 A / Project 29'
    path 'group-12/subgroup-12-a/project-29'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project29_namespace)
    source_type 'Namespace'
  end

  route :project30_namespace_route do
    name 'Group 12 / Subgroup 12 B / Project 30'
    path 'group-12/subgroup-12-b/project-30'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project30_namespace)
    source_type 'Namespace'
  end

  route :project31_namespace_route do
    name 'Group 12 / Subgroup 12 A / Subgroup 12 A A / Project 31'
    path 'group-12/subgroup-12-a/subgroup-12-a-a/project-31'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project31_namespace)
    source_type 'Namespace'
  end

  route :group_delta_route do
    name 'Group Delta'
    path 'group-delta'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_delta)
    source_type 'Namespace'
  end

  route :group_echo_route do
    name 'Group Echo'
    path 'group-echo'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_echo)
    source_type 'Namespace'
  end

  route :subgroup_a_group_delta_route do
    name 'Group Delta / Subgroup A'
    path 'group-delta/subgroup-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_delta_subgroupA)
    source_type 'Namespace'
  end

  route :subgroup_b_group_echo_route do
    name 'Group Echo / Subgroup B'
    path 'group-echo/subgroup-b'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_echo_subgroupB)
    source_type 'Namespace'
  end

  route :project_delta_namespace_route do
    name 'Group Delta / Project Delta'
    path 'group-delta/project-delta'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectDelta_namespace)
    source_type 'Namespace'
  end

  route :project_echo_namespace_route do
    name 'Group Echo / Project Echo'
    path 'group-echo/project-echo'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectEcho_namespace)
    source_type 'Namespace'
  end

  route :project_delta_subgroupA_namespace_route do
    name 'Group Delta / Subgroup A / Project Delta'
    path 'group-delta/subgroup-a/project-delta'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectDeltaSubgroupA_namespace)
    source_type 'Namespace'
  end

  route :project_echo_subgroupB_namespace_route do
    name 'Group Echo / Subgroup B / Project Echo'
    path 'group-echo/subgroup-b/project-echo'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectEchoSubgroupB_namespace)
    source_type 'Namespace'
  end

  route :group_foxtrot_route do
    name 'Group Foxtrot'
    path 'group-foxtrot'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_foxtrot)
    source_type 'Namespace'
  end

  route :subgroup_a_group_foxtrot_route do
    name 'Group Foxtrot / Subgroup A'
    path 'group-foxtrot/subgroup-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_foxtrot_subgroupA)
    source_type 'Namespace'
  end

  route :project_foxtrot_subgroupA_namespace_route do
    name 'Group Foxtrot / Subgroup A / Project Foxtrot'
    path 'group-foxtrot/subgroup-a/project-foxtrot'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectFoxtrotSubgroupA_namespace)
    source_type 'Namespace'
  end

  route :group_golf_route do
    name 'Group Golf'
    path 'group-golf'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_golf)
    source_type 'Namespace'
  end

  route :user27_project_1_namespace_route do
    name 'user.27@localhost / Project 1'
    path 'user.27_at_localhost/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :user27_project1_namespace)
    source_type 'Namespace'
  end

  route :group_hotel_route do
    name 'Group Hotel'
    path 'group-hotel'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_hotel)
    source_type 'Namespace'
  end

  route :project_hotel_namespace_route do
    name 'Group Hotel / Project Hotel'
    path 'group-hotel/project-hotel'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectHotel_namespace)
    source_type 'Namespace'
  end

  route :group_13_route do
    name 'Group 13'
    path 'group-13'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_thirteen)
    source_type 'Namespace'
  end

  route :project33_namespace_route do
    name 'Group 13 / Project 33'
    path 'group-13/project-33'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project33_namespace)
    source_type 'Namespace'
  end

  route :group_14_route do
    name 'Group 14'
    path 'group-14'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_fourteen)
    source_type 'Namespace'
  end

  route :project34_namespace_route do
    name 'Group 14 / Project 34'
    path 'group-14/project-34'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project34_namespace)
    source_type 'Namespace'
  end

  route :group_15_route do
    name 'Group 15'
    path 'group-15'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_fifteen)
    source_type 'Namespace'
  end

  route :project35_namespace_route do
    name 'Group 15 / Project 35'
    path 'group-15/project-35'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project35_namespace)
    source_type 'Namespace'
  end

  route :project37_namespace_route do
    name 'Group 16 / Project 37'
    path 'group-16/project-37'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project37_namespace)
    source_type 'Namespace'
  end

  route :group_16_route do
    name 'Group 16'
    path 'group-16'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
    source_type 'Namespace'
  end

  route :group_17_route do
    name 'Group 17'
    path 'group-17'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_seventeen)
    source_type 'Namespace'
  end

  route :project38_namespace_route do
    name 'Group 17 / Project 38'
    path 'group-17/project-38'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project38_namespace)
    source_type 'Namespace'
  end

  route :user_29_namespace_route do
    name 'user.29@localhost'
    path 'user.29_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user29_namespace)
    source_type 'Namespace'
  end

  route :user_30_namespace_route do
    name 'user.30@localhost'
    path 'user.30_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user30_namespace)
    source_type 'Namespace'
  end

  route :user29_project1_namespace_route do
    name 'user.29@localhost / Project 1'
    path 'user.29_at_localhost/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :user29_project1_namespace)
    source_type 'Namespace'
  end

  route :user30_group_one_route do
    name 'User 30 Group 1'
    path 'user-30-group-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :user30_group_one)
    source_type 'Namespace'
  end

  route :empty_group_route do
    name 'Empty Group'
    path 'empty-group'
    source_id FixtureBot::Key::Uuid.generate(:groups, :empty_group)
    source_type 'Namespace'
  end

  route :empty_project_namespace_route do
    name 'Empty Group / Empty Project'
    path 'empty-group/empty-project'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :empty_project_namespace)
    source_type 'Namespace'
  end

  route :group_india_route do
    name 'Group India'
    path 'group-india'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_india)
    source_type 'Namespace'
  end

  route :project_india_namespace_route do
    name 'Group India / Project India'
    path 'group-india/project-india'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectIndia_namespace)
    source_type 'Namespace'
  end

  route :subgroup_one_group_india_route do
    name 'Group India / Subgroup 1'
    path 'group-india/subgroup-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_india_subgroup1)
    source_type 'Namespace'
  end

  route :project_india_1_namespace_route do
    name 'Group India / Subgroup 1 / Project India 1'
    path 'group-india/subgroup-1/project-india-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectIndia1_namespace)
    source_type 'Namespace'
  end

  route :group_juliett_route do
    name 'Group Juliett'
    path 'group-juliett'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_juliett)
    source_type 'Namespace'
  end

  route :project_juliett_namespace_route do
    name 'Group Juliett / Project Juliett'
    path 'group-juliett/project-juliett'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectJuliett_namespace)
    source_type 'Namespace'
  end

  route :subgroup_one_group_juliett_route do
    name 'Group Juliett / Subgroup 1'
    path 'group-juliett/subgroup-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_juliett_subgroup1)
    source_type 'Namespace'
  end

  route :project_juliett_1_namespace_route do
    name 'Group Juliett / Subgroup 1 / Project Juliett 1'
    path 'group-juliett/subgroup-1/project-juliett-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectJuliett1_namespace)
    source_type 'Namespace'
  end

  route :group_kilo_route do
    name 'Group Kilo'
    path 'group-kilo'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_kilo)
    source_type 'Namespace'
  end

  route :group_lima_route do
    name 'Group Lima'
    path 'group-lima'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_lima)
    source_type 'Namespace'
  end

  route :group_mike_route do
    name 'Group Mike'
    path 'group-mike'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_mike)
    source_type 'Namespace'
  end

  route :projectMike_namespace_route do
    name 'Group Mike / Project Mike'
    path 'group-mike/project-mike'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMike_namespace)
    source_type 'Namespace'
  end

  route :subgroup_mike_a_route do
    name 'Group Mike / Subgroup Mike A'
    path 'group-mike/subgroup-mike-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_mike_a)
    source_type 'Namespace'
  end

  route :projectMikeA_namespace_route do
    name 'Group Mike / Subgroup Mike A / Project Mike A'
    path 'group-mike/subgroup-mike-a/project-mike-a'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMikeA_namespace)
    source_type 'Namespace'
  end

  route :subgroup_mike_b_route do
    name 'Group Mike / Subgroup Mike B'
    path 'group-mike/subgroup-mike-b'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_mike_b)
    source_type 'Namespace'
  end

  route :projectMikeB_namespace_route do
    name 'Group Mike / Subgroup Mike B / Project Mike B'
    path 'group-mike/subgroup-mike-b/project-mike-b'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMikeB_namespace)
    source_type 'Namespace'
  end

  route :subgroup_mike_a_a_route do
    name 'Group Mike / Subgroup Mike A / Subgroup Mike AA'
    path 'group-mike/subgroup-mike-a/subgroup-mike-a-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_mike_a_a)
    source_type 'Namespace'
  end

  route :group_oscar_route do
    name 'Group Oscar'
    path 'group-oscar'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_oscar)
    source_type 'Namespace'
  end

  route :subgroup_oscar_a_route do
    name 'Group Oscar / Subgroup Oscar A'
    path 'group-oscar/subgroup-oscar-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_oscar_a)
    source_type 'Namespace'
  end

  route :group_papa_route do
    name 'Group Papa'
    path 'group-papa'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_papa)
    source_type 'Namespace'
  end

  route :subgroup_papa_a_route do
    name 'Group Papa / Subgroup Papa A'
    path 'group-papa/subgroup-papa-a'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_papa_a)
    source_type 'Namespace'
  end

  route :group_metadata_route do
    name 'Group Metadata'
    path 'group-metadata'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_metadata)
    source_type 'Namespace'
  end

  route :projectMetadata_namespace_route do
    name 'Group Metadata / Project Metadata'
    path 'group-metadata/project-metadata'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMetadata_namespace)
    source_type 'Namespace'
  end

  route :metadata_doe_namespace_route do
    name 'metadata.doe@localhost'
    path 'metadata.doe_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :metadata_doe_namespace)
    source_type 'Namespace'
  end

  route :metadata_doe_projectMetadata2_namespace_route do
    name 'metadata.doe@localhost / Project Metadata 2'
    path 'metadata.doe_at_localhost/project-metadata-2'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :metadata_doe_projectMetadata2_namespace)
    source_type 'Namespace'
  end

  route :group_sample_transfer_route do
    name 'Group Sample Transfer'
    path 'group-sample-transfer'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_transfer)
    source_type 'Namespace'
  end

  route :group_sample_transfer_target_route do
    name 'Group Sample Transfer Target'
    path 'group-sample-transfer-target'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_transfer_target)
    source_type 'Namespace'
  end

  route :project_group_sample_transfer_namespace do
    name 'Group Sample Transfer / Project Group Sample Transfer'
    path 'group-sample-transfer/project-group-sample-transfer'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_group_sample_transfer_namespace)
    source_type 'Namespace'
  end

  route :project_group_sample_transfer_target_namespace_route do
    name 'Group Sample Transfer Target / Project Group Sample Transfer Target'
    path 'group-sample-transfer-target/project-group-sample-transfer-target'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_group_sample_transfer_target_namespace)
    source_type 'Namespace'
  end

  route :group_sample_actions_route do
    name 'Group Sample Actions'
    path 'group-sample-actions'
    source_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_actions)
    source_type 'Namespace'
  end

  route :subgroup_sample_actions_route do
    name 'Group Sample Actions / Subgroup Sample Actions'
    path 'group-sample-actions/subgroup-sample-actions'
    source_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_sample_actions)
    source_type 'Namespace'
  end

  route :project_group_sample_actions_namespace_route do
    name 'Group Sample Actions / Project Group Sample Actions'
    path 'group-sample-actions/project-group-sample-actions'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_group_sample_actions_namespace)
    source_type 'Namespace'
  end

  route :project_subgroup_sample_actions_namespace_route do
    name 'Group Sample Actions / Subgroup Sample Actions / Project Subgroup Sample Actions'
    path 'group-sample-actions/subgroup-sample-actions/project-subgroup-sample-actions'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_subgroup_sample_actions_namespace)
    source_type 'Namespace'
  end

  route :shared_group_sample_actions_owner_route do
    name 'Shared Group Sample Actions Owner'
    path 'shared-group-sample-actions-owner'
    source_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_owner)
    source_type 'Namespace'
  end

  route :shared_group_sample_actions_maintainer_route do
    name 'Shared Group Sample Actions Maintainer'
    path 'shared-group-sample-actions-maintainer'
    source_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_maintainer)
    source_type 'Namespace'
  end

  route :shared_group_sample_actions_analyst_route do
    name 'Shared Group Sample Actions Analyst'
    path 'shared-group-sample-actions-analyst'
    source_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_analyst)
    source_type 'Namespace'
  end

  route :shared_group_sample_actions_guest_route do
    name 'Shared Group Sample Actions Guest'
    path 'shared-group-sample-actions-guest'
    source_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_guest)
    source_type 'Namespace'
  end

  route :project_shared_group_sample_actions_owner_route do
    name 'Shared Group Sample Actions Owner / Project Shared Group Sample Actions Owner'
    path 'shared-group-sample-actions-owner/project-shared-group-sample-actions-owner'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_shared_group_sample_actions_owner_namespace)
    source_type 'Namespace'
  end

  route :project_shared_group_sample_actions_maintainer_route do
    name 'Shared Group Sample Actions Maintainer / Project Shared Group Sample Actions Maintainer'
    path 'shared-group-sample-actions-maintainer/project-shared-group-sample-actions-maintainer'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_shared_group_sample_actions_maintainer_namespace)
    source_type 'Namespace'
  end

  route :project_shared_group_sample_actions_analyst_route do
    name 'Shared Group Sample Actions Analyst / Project Shared Group Sample Actions Analyst'
    path 'shared-group-sample-actions-analyst/project-shared-group-sample-actions-analyst'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_shared_group_sample_actions_analyst_namespace)
    source_type 'Namespace'
  end

  route :project_shared_group_sample_actions_guest_route do
    name 'Shared Group Sample Actions Guest / Project Shared Group Sample Actions Guest'
    path 'shared-group-sample-actions-guest/project-shared-group-sample-actions-guest'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces',
                                             :project_shared_group_sample_actions_guest_namespace)
    source_type 'Namespace'
  end

  route :user31_namespace_route do
    name 'user.31@localhost'
    path 'user.31_at_localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :user31_namespace)
    source_type 'Namespace'
  end

  route :user31_project1_namespace_route do
    name 'user.31@localhost / Project 1'
    path 'user.31_at_localhost/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectUser31_namespace)
    source_type 'Namespace'
  end

  route :chunked_samples_doe_namespace_route do
    name 'chunked_samples_doe@localhost'
    path 'chunked-samples-doe-at-localhost'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :chunked_samples_doe_namespace)
    source_type 'Namespace'
  end

  (1..10).each do |n|
    route(:"public_group_#{n}_route") do
      name "Public Group #{n}"
      path "public-group-#{n}"
      source_id FixtureBot::Key::Uuid.generate(:groups, :"public_group#{n}")
      source_type 'Namespace'
    end
  end

  route :project_chunked_samples_namespace_route do
    name 'chunked_samples_doe@localhost / Project Chunked Samples'
    path 'chunked-samples-doe-at-localhost/project-chunked-samples'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_chunked_samples_namespace)
    source_type 'Namespace'
  end

  route :public_group1_subgroup1_route do
    name 'Public Group 1 Subgroup 1'
    path 'public-group-1/subgroup-1'
    source_id FixtureBot::Key::Uuid.generate(:groups, :public_group1_subgroup1)
    source_type 'Namespace'
  end

  route :public_group1_subgroup1_project1_route do
    name 'Public Group 1 Subgroup 1 Project 1'
    path 'public-group-1/subgroup-1/project-1'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :public_subgroup1_project1_namespace)
    source_type 'Namespace'
  end

  route :snvphyl_group_route do
    name 'SNVPhyl Group'
    path 'snvphyl-group'
    source_id FixtureBot::Key::Uuid.generate(:groups, :snvphyl_group)
    source_type 'Namespace'
  end

  route :snvphyl_project_route do
    name 'SNVPhyl Group / SNVPhyl Project'
    path 'snvphyl-group/snvphyl-project'
    source_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :snvphyl_project_namespace)
    source_type 'Namespace'
  end
end
