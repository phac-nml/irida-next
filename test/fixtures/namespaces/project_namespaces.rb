# frozen_string_literal: true

FixtureBot.define do
  namespaces_project_namespace :project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 1'
    path 'project-1'
    description 'Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 10, 'metadatafield2' => 35 })
    puid 'INXT_PRJ_AAAAAAAAAA'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  namespaces_project_namespace :project2_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 2'
    path 'project-2'
    description 'Project 2 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAB'
  end

  namespaces_project_namespace :john_doe_project2_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 2'
    path 'project-2'
    description 'Project 2 description'
    parent_id ActiveRecord::FixtureSet.identify(:john_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAC'
  end

  namespaces_project_namespace :john_doe_project3_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 3'
    path 'project-3'
    description 'Project 3 description'
    parent_id ActiveRecord::FixtureSet.identify(:john_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAD'
  end

  namespaces_project_namespace :project4_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 4'
    path 'project-4'
    description 'Project 4 description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_three, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAE'
  end

  namespaces_project_namespace :project5_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 5'
    path 'project-5'
    description 'Project 5 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 623, 'metadatafield2' => 71 })
    puid 'INXT_PRJ_AAAAAAAAAF'
  end

  namespaces_project_namespace :project6_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 6'
    path 'project-6'
    description 'Project 6 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAG'
  end

  namespaces_project_namespace :project7_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 7'
    path 'project-7'
    description 'Project 7 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAH'
  end

  namespaces_project_namespace :project8_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 8'
    path 'project-8'
    description 'Project 8 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAI'
  end

  namespaces_project_namespace :project9_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 9'
    path 'project-9'
    description 'Project 9 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAJ'
  end

  namespaces_project_namespace :project10_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 10'
    path 'project-10'
    description 'Project 10 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAK'
  end

  namespaces_project_namespace :project11_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 11'
    path 'project-11'
    description 'Project 11 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAL'
  end

  namespaces_project_namespace :project12_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 12'
    path 'project-12'
    description 'Project 12 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAM'
  end

  namespaces_project_namespace :project13_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 13'
    path 'project-13'
    description 'Project 13 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAN'
  end

  namespaces_project_namespace :project14_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 14'
    path 'project-14'
    description 'Project 14 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAO'
  end

  namespaces_project_namespace :project15_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 15'
    path 'project-15'
    description 'Project 15 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAP'
  end

  namespaces_project_namespace :project16_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 16'
    path 'project-16'
    description 'Project 16 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAQ'
  end

  namespaces_project_namespace :project17_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 17'
    path 'project-17'
    description 'Project 17 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAR'
  end

  namespaces_project_namespace :project18_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 18'
    path 'project-18'
    description 'Project 18 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAS'
  end

  namespaces_project_namespace :project19_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 19'
    path 'project-19'
    description 'Project 19 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAT'
  end

  namespaces_project_namespace :project20_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 20'
    path 'project-20'
    description 'Project 20 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAU'
  end

  namespaces_project_namespace :project21_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 21'
    path 'project-21'
    description 'Project 21 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAV'
  end

  namespaces_project_namespace :project22_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 22'
    path 'project-22'
    description 'Project 22 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAW'
  end

  namespaces_project_namespace :project23_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 23'
    path 'project-23'
    description 'Project 23 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_six, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAX'
  end

  namespaces_project_namespace :project24_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 24'
    path 'project-24'
    description 'Project 24 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAY'
  end

  namespaces_project_namespace :john_doe_project4_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 4'
    path 'project-4'
    description 'Project 4 description'
    parent_id ActiveRecord::FixtureSet.identify(:john_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAAZ'
  end

  namespaces_project_namespace :project25_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 25'
    path 'project-25'
    description 'Project 25 description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup1, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA2'
  end

  namespaces_project_namespace :project26_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 26'
    path 'project-26'
    description 'Project 26 description'
    parent_id ActiveRecord::FixtureSet.identify(:john_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA3'
  end

  namespaces_project_namespace :project32_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 32'
    path 'project-32'
    description 'Project 32 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_eight, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA4'
  end

  namespaces_project_namespace :projectA_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project A'
    path 'project-a'
    description 'Project A description'
    parent_id ActiveRecord::FixtureSet.identify(:jeff_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA5'
  end

  namespaces_project_namespace :namespace_group_link_group_one_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Group One Project 1'
    path 'project-1'
    description 'Group One Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_one, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:user24, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA6'
  end

  namespaces_project_namespace :namespace_group_link_group_three_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Group Three Project 1'
    path 'project-1'
    description 'Group Three Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:user24, :uuid)
    puid 'INXT_PRJ_AAAAAAAAA7'
  end

  namespaces_project_namespace :project28_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 28'
    path 'project-28'
    description 'Project 28 description'
    parent_id ActiveRecord::FixtureSet.identify(:david_doe_group_four, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:david_doe, :uuid)
    metadata_summary({ 'unique.metadata.field' => 1, 'metadata field with spaces' => 1 })
    puid 'INXT_PRJ_AAAAAAAABA'
  end

  namespaces_project_namespace :project29_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 29'
    path 'project-29'
    description 'Project 29 description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_twelve_a, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAABB'
  end

  namespaces_project_namespace :project30_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 30'
    path 'project-30'
    description 'Project 30 description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_twelve_b, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAABC'
  end

  namespaces_project_namespace :project31_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 31'
    path 'project-31'
    description 'Project 31 description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_twelve_a_a, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAABD'
  end

  namespaces_project_namespace :user32_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Personal Project 1'
    path 'personal-project-1'
    description 'Personal Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:user32_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:user32, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAZBD'
  end

  namespaces_project_namespace :projectAlpha_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Alpha'
    path 'project-alpha'
    description 'Project Alpha description'
    parent_id ActiveRecord::FixtureSet.identify(:group_alpha, :uuid)
    puid 'INXT_PRJ_AAAAAAAABE'
  end

  namespaces_project_namespace :projectBravo_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Bravo'
    path 'project-bravo'
    description 'Project Bravo description'
    type 'Project'
    parent_id ActiveRecord::FixtureSet.identify(:group_bravo, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAABF'
  end

  namespaces_project_namespace :projectCharlie_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Charlie'
    path 'project-charlie'
    description 'Project Charlie description'
    parent_id ActiveRecord::FixtureSet.identify(:group_charlie, :uuid)
    puid 'INXT_PRJ_AAAAAAAABG'
  end

  namespaces_project_namespace :projectAlpha1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Alpha 1'
    path 'project-alpha-1'
    description 'Project Alpha 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_alpha_subgroup1, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    puid 'INXT_PRJ_AAAAAAAABH'
  end

  namespaces_project_namespace :projectDelta_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Delta'
    path 'project-delta'
    description 'Project Delta description'
    parent_id ActiveRecord::FixtureSet.identify(:group_delta, :uuid)
    puid 'INXT_PRJ_AAAAAAAABI'
  end

  namespaces_project_namespace :projectDeltaSubgroupA_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Delta Subgroup A'
    path 'project-delta-subgroup-a'
    description 'Project Delta Subgroup A description'
    parent_id ActiveRecord::FixtureSet.identify(:group_delta_subgroupA, :uuid)
    puid 'INXT_PRJ_AAAAAAAABJ'
  end

  namespaces_project_namespace :projectEcho_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Echo'
    path 'project-echo'
    description 'Project Echo description'
    parent_id ActiveRecord::FixtureSet.identify(:group_echo, :uuid)
    puid 'INXT_PRJ_AAAAAAAABK'
  end

  namespaces_project_namespace :projectEchoSubgroupB_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Echo Subgroup B'
    path 'project-echo-subgroup-b'
    description 'Project Echo Subgroup B description'
    parent_id ActiveRecord::FixtureSet.identify(:group_echo_subgroupB, :uuid)
    puid 'INXT_PRJ_AAAAAAAABL'
  end

  namespaces_project_namespace :projectFoxtrotSubgroupA_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Foxtrot Subgroup A'
    path 'project-foxtrot-subgroup-a'
    description 'Project Foxtrot Subgroup A description'
    parent_id ActiveRecord::FixtureSet.identify(:group_foxtrot_subgroupA, :uuid)
    puid 'INXT_PRJ_AAAAAAAABM'
  end

  namespaces_project_namespace :user27_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Personal Project 1'
    path 'personal-project-1'
    description 'Personal Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:user27_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:user27, :uuid)
    puid 'INXT_PRJ_AAAAAAAABN'
  end

  namespaces_project_namespace :projectHotel_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Hotel'
    path 'project-hotel'
    description 'Project Hotel description'
    parent_id ActiveRecord::FixtureSet.identify(:group_hotel, :uuid)
    puid 'INXT_PRJ_AAAAAAAABO'
  end

  namespaces_project_namespace :project_jeff_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Uncounted'
    path 'project-uncounted'
    description 'Project Uncounted description'
    parent_id ActiveRecord::FixtureSet.identify(:jeff_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAABP'
  end

  namespaces_project_namespace :project33_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 33'
    path 'project-33'
    description 'Project 33 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_thirteen, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAABQ'
  end

  namespaces_project_namespace :project34_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 34'
    path 'project-34'
    description 'Project 34 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_fourteen, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAABR'
  end

  namespaces_project_namespace :project35_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 35'
    path 'project-35'
    description 'Project 35 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_fifteen, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAABS'
  end

  namespaces_project_namespace :project37_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 37'
    path 'project-37'
    description 'Project 37 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
    puid 'INXT_PRJ_AAAAAAACBC'
  end

  namespaces_project_namespace :project38_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 38'
    path 'project-38'
    description 'Project 38 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_seventeen, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAACBF'
  end

  namespaces_project_namespace :user29_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'User 29 Project 1'
    path 'project-1'
    description 'Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:user29_namespace, :uuid)
    puid 'INXT_PRJ_AAAAAAACBD'
  end

  namespaces_project_namespace :project_janitor_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project EndToEnd'
    path 'project-end_to_end'
    description 'Project EndToEnd description'
    parent_id ActiveRecord::FixtureSet.identify(:janitor_doe_group, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:janitor_doe, :uuid)
    puid 'INXT_PRJ_ABAAAAAAAA'
  end

  namespaces_project_namespace :empty_project_namespace do
    type 'Project'
    metadata_summary({})
    name 'Empty Project'
    path 'empty-project'
    description 'Project that does not contain any samples'
    parent_id ActiveRecord::FixtureSet.identify(:empty_group, :uuid)
    puid 'INXT_PRJ_AAAAAAACBE'
  end

  namespaces_project_namespace :projectIndia_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project India'
    path 'project-india'
    description 'Project India description'
    parent_id ActiveRecord::FixtureSet.identify(:group_india, :uuid)
    puid 'INXT_PRJ_AAAAAAAABT'
  end

  namespaces_project_namespace :projectIndia1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project India 1'
    path 'project-india-1'
    description 'Project India 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_india_subgroup1, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    puid 'INXT_PRJ_AAAAAAAABU'
  end

  namespaces_project_namespace :projectJuliett_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Juliett'
    path 'project-juliett'
    description 'Project Juliett description'
    parent_id ActiveRecord::FixtureSet.identify(:group_juliett, :uuid)
    puid 'INXT_PRJ_AAAAAAAABV'
  end

  namespaces_project_namespace :projectJuliett1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Juliett 1'
    path 'project-juliett-1'
    description 'Project Juliett 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:group_juliett_subgroup1, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    puid 'INXT_PRJ_AAAAAAAABW'
  end

  namespaces_project_namespace :projectMike_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Mike'
    path 'project-mike'
    description 'Project Mike description'
    parent_id ActiveRecord::FixtureSet.identify(:group_mike, :uuid)
    puid 'INXT_PRJ_AAAAAAAABX'
  end

  namespaces_project_namespace :projectMikeA_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Mike A'
    path 'project-mike-a'
    description 'Project Mike A description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_mike_a, :uuid)
    puid 'INXT_PRJ_AAAAAAAABY'
  end

  namespaces_project_namespace :projectMikeB_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Mike B'
    path 'project-mike-b'
    description 'Project Mike B description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_mike_b, :uuid)
    puid 'INXT_PRJ_AAAAAAAABZ'
  end

  namespaces_project_namespace :projectMetadata_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Metadata'
    path 'project-metadata'
    description 'Project Metadata description'
    parent_id ActiveRecord::FixtureSet.identify(:group_metadata, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    metadata_summary({ 'example_date' => 3, 'example_float' => 3, 'example_integer' => 3 })
    puid 'INXT_PRJ_AAAAAAAACA'
  end

  namespaces_project_namespace :metadata_doe_projectMetadata2_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Metadata 2'
    path 'project-metadata-2'
    description 'Project Metadata 2 description'
    parent_id ActiveRecord::FixtureSet.identify(:metadata_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    metadata_summary({ 'example_date' => 3, 'example_float' => 3, 'example_integer' => 3 })
    puid 'INXT_PRJ_AAAAAAAACB'
  end

  namespaces_project_namespace :project_group_sample_transfer_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Group Sample Transfer'
    path 'project-group-sample-transfer'
    description 'Project Group Sample Transfer description'
    parent_id ActiveRecord::FixtureSet.identify(:group_sample_transfer, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAACC'
  end

  namespaces_project_namespace :project_group_sample_transfer_target_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Group Sample Transfer Target'
    path 'project-group-sample-transfer-target'
    description 'Project Group Sample Transfer Target description'
    parent_id ActiveRecord::FixtureSet.identify(:group_sample_transfer_target, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAACD'
  end

  namespaces_project_namespace :project_group_sample_actions_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Group Sample Actions'
    path 'project-group-sample-actions'
    description 'Project Group Sample Actions description'
    parent_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACE'
  end

  namespaces_project_namespace :project_subgroup_sample_actions_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Subgroup Sample Actions'
    path 'project-subgroup-sample-actions'
    description 'Subgroup Sample Actions description'
    parent_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACF'
  end

  namespaces_project_namespace :project_shared_group_sample_actions_owner_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Shared Group Sample Actions Owner'
    path 'project-shared-group-sample-actions-owner'
    description 'Project Shared Group Sample Actions Owner description'
    parent_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_owner, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACG'
  end

  namespaces_project_namespace :project_shared_group_sample_actions_maintainer_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Shared Group Sample Actions Maintainer'
    path 'project-shared-group-sample-actions-maintainer'
    description 'Project Shared Group Sample Actions Maintainer description'
    parent_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_maintainer, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACH'
  end

  namespaces_project_namespace :project_shared_group_sample_actions_analyst_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Shared Group Sample Actions Analyst'
    path 'project-shared-group-sample-actions-analyst'
    description 'Project Shared Group Sample Actions Analyst description'
    parent_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_analyst, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACI'
  end

  namespaces_project_namespace :project_shared_group_sample_actions_guest_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Shared Group Sample Actions Guest'
    path 'project-shared-group-sample-actions-guest'
    description 'Project Shared Group Sample Actions Guest description'
    parent_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_guest, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_PRJ_AAAAAAAACJ'
  end

  namespaces_project_namespace :projectUser31_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project 1'
    path 'project-1'
    description 'Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:user31_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:user31, :uuid)
    puid 'INXT_PRJ_AAAAAAAACK'
  end

  namespaces_project_namespace :project_chunked_samples_namespace do
    type 'Project'
    metadata_summary({})
    name 'Project Chunked Samples'
    path 'project-chunked-samples'
    description 'Project Chunked Samples description'
    parent_id ActiveRecord::FixtureSet.identify(:chunked_samples_doe_namespace, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:chunked_samples_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAACL'
  end

  namespaces_project_namespace :public_subgroup1_project1_namespace do
    type 'Project'
    metadata_summary({})
    name 'Public Group 1 Subgroup 1 Project 1'
    path 'public-subgroup-1-project-1'
    description 'Project Subgroup 1 Project 1 description'
    parent_id ActiveRecord::FixtureSet.identify(:public_group1, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    puid 'INXT_PRJ_AAAAAAAACY'
    send(:public, true) # `public` column name collides with Ruby's `public` keyword
  end

  namespaces_project_namespace :snvphyl_project_namespace do
    type 'Project'
    metadata_summary({})
    name 'SNVPhyl Project'
    path 'snvphyl-project'
    description 'SNVPhyl Project description'
    parent_id ActiveRecord::FixtureSet.identify(:snvphyl_group, :uuid)
    owner_id ActiveRecord::FixtureSet.identify(:snvphyl_user, :uuid)
    metadata_summary({ 'metadata_1' => 2, 'metadata_2' => 2, 'metadata_3' => 2, 'metadata_4' => 2, 'metadata_5' => 2,
                       'metadata_6' => 2, 'metadata_7' => 2, 'metadata_8' => 2 })
    puid 'INXT_PRJ_AAAAAAAACZ'
  end
end
