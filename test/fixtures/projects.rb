# frozen_string_literal: true

FixtureBot.define do
  project :project1 do
    creator :john_doe
    namespace :project1_namespace
    samples_count 3
    updated_at '<%= 1.hour.from_now %>'
  end

  project :project2 do
    creator :john_doe
    namespace :project2_namespace
    samples_count 20
  end

  project :john_doe_project2 do
    creator :john_doe
    namespace :john_doe_project2_namespace
    samples_count 1
  end

  project :john_doe_project3 do
    creator :john_doe
    namespace :john_doe_project3_namespace
    samples_count 0
  end

  project :john_doe_project4 do
    creator :john_doe
    namespace :john_doe_project4_namespace
    samples_count 0
  end

  project :project4 do
    creator :john_doe
    namespace :project4_namespace
    samples_count 2
  end

  project :project5 do
    creator :john_doe
    namespace :project5_namespace
    samples_count 0
  end

  project :project6 do
    creator :john_doe
    namespace :project6_namespace
    samples_count 0
  end

  project :project7 do
    creator :john_doe
    namespace :project7_namespace
    samples_count 0
  end

  project :project8 do
    creator :john_doe
    namespace :project8_namespace
    samples_count 0
  end

  project :project9 do
    creator :john_doe
    namespace :project9_namespace
    samples_count 0
  end

  project :project10 do
    creator :john_doe
    namespace :project10_namespace
    samples_count 0
  end

  project :project11 do
    creator :john_doe
    namespace :project11_namespace
    samples_count 0
  end

  project :project12 do
    creator :john_doe
    namespace :project12_namespace
    samples_count 0
  end

  project :project13 do
    creator :john_doe
    namespace :project13_namespace
    samples_count 0
  end

  project :project14 do
    creator :john_doe
    namespace :project14_namespace
    samples_count 0
  end

  project :project15 do
    creator :john_doe
    namespace :project15_namespace
    samples_count 0
  end

  project :project16 do
    creator :john_doe
    namespace :project16_namespace
    samples_count 0
  end

  project :project17 do
    creator :john_doe
    namespace :project17_namespace
    samples_count 0
  end

  project :project18 do
    creator :john_doe
    namespace :project18_namespace
    samples_count 0
  end

  project :project19 do
    creator :john_doe
    namespace :project19_namespace
    samples_count 0
  end

  project :project20 do
    creator :john_doe
    namespace :project20_namespace
    samples_count 0
  end

  project :project21 do
    creator :john_doe
    namespace :project21_namespace
    samples_count 0
  end

  project :project22 do
    creator :john_doe
    namespace :project22_namespace
    samples_count 2
  end

  project :project23 do
    creator :john_doe
    namespace :project23_namespace
    samples_count 0
  end

  project :project24 do
    creator :john_doe
    namespace :project24_namespace
    samples_count 0
  end

  project :project25 do
    creator :john_doe
    namespace :project25_namespace
    samples_count 2
  end

  project :project26 do
    creator :john_doe
    namespace :project26_namespace
    samples_count 3
  end

  project :project32 do
    creator :john_doe
    namespace :project32_namespace
    samples_count 0
  end

  project :projectA do
    creator :jeff_doe
    namespace :projectA_namespace
    samples_count 3
  end

  project :namespace_group_link_group_one_project1 do
    creator :user24
    namespace :namespace_group_link_group_one_project1_namespace
    samples_count 0
  end

  project :namespace_group_link_group_three_project1 do
    creator :user24
    namespace :namespace_group_link_group_three_project1_namespace
    samples_count 0
  end

  project :project28 do
    creator :david_doe
    namespace :project28_namespace
    samples_count 1
  end

  project :project29 do
    creator :john_doe
    namespace :project29_namespace
    samples_count 1
  end

  project :project30 do
    creator :john_doe
    namespace :project30_namespace
    samples_count 1
  end

  project :project31 do
    creator :john_doe
    namespace :project31_namespace
    samples_count 2
  end

  project :projectAlpha do
    creator :private_ryan
    namespace :projectAlpha_namespace
    samples_count 1
  end

  project :projectBravo do
    creator :private_ryan
    namespace :projectBravo_namespace
    samples_count 1
  end

  project :projectCharlie do
    creator :private_ryan
    namespace :projectCharlie_namespace
    samples_count 1
  end

  project :projectAlpha1 do
    creator :private_ryan
    namespace :projectAlpha1_namespace
    samples_count 1
  end

  project :projectDelta do
    creator :private_joan
    namespace :projectDelta_namespace
    samples_count 0
  end

  project :projectEcho do
    creator :private_joan
    namespace :projectEcho_namespace
    samples_count 0
  end

  project :projectDeltaSubgroupA do
    creator :private_joan
    namespace :projectDeltaSubgroupA_namespace
    samples_count 0
  end

  project :projectEchoSubgroupB do
    creator :private_joan
    namespace :projectEchoSubgroupB_namespace
    samples_count 0
  end

  project :projectFoxtrotSubgroupA do
    creator :private_micha
    namespace :projectFoxtrotSubgroupA_namespace
    samples_count 0
  end

  project :project27 do
    creator :user27
    namespace :user27_project1_namespace
    samples_count 0
  end

  project :projectHotel do
    creator :john_doe
    namespace :projectHotel_namespace
    samples_count 1
  end

  project :projectJeff do
    creator :jeff_doe
    namespace :project_jeff_namespace
    samples_count 1
  end

  project :project33 do
    creator :jane_doe
    namespace :project33_namespace
    samples_count 0
  end

  project :project34 do
    creator :john_doe
    namespace :project34_namespace
    samples_count 1
  end

  project :project35 do
    creator :john_doe
    namespace :project35_namespace
    samples_count 3
  end

  project :project36 do
    creator :jeff_doe
    namespace :project_jeff_namespace
    samples_count 2
  end

  project :project37 do
    creator :user21
    namespace :project37_namespace
    samples_count 3
  end

  project :project38 do
    creator :john_doe
    namespace :project38_namespace
    samples_count 200
  end

  project :user29_project1 do
    creator :user29
    namespace :user29_project1_namespace
    samples_count 1
  end

  project :project_janitor_end_to_end do
    creator :janitor_doe
    namespace :project_janitor_namespace
    samples_count 1
  end

  project :project_janitor_DELETE do
    creator :janitor_doe
    namespace :project_janitor_namespace
    samples_count 4
  end

  project :empty_project do
    creator :john_doe
    namespace :empty_project_namespace
    samples_count 0
  end

  project :projectIndia do
    creator :private_ryan
    namespace :projectIndia_namespace
    samples_count 2
  end

  project :projectIndia1 do
    creator :private_ryan
    namespace :projectIndia1_namespace
    samples_count 1
  end

  project :projectJuliett do
    creator :private_ryan
    namespace :projectJuliett_namespace
    samples_count 2
  end

  project :projectJuliett1 do
    creator :private_ryan
    namespace :projectJuliett1_namespace
    samples_count 1
  end

  project :projectMike do
    creator :private_ryan
    namespace :projectMike_namespace
    samples_count 2
  end

  project :projectMikeA do
    creator :private_ryan
    namespace :projectMikeA_namespace
    samples_count 2
  end

  project :projectMikeB do
    creator :private_ryan
    namespace :projectMikeB_namespace
    samples_count 2
  end

  project :projectMetadata do
    creator :metadata_doe
    namespace :projectMetadata_namespace
    samples_count 3
  end

  project :projectMetadata2 do
    creator :metadata_doe
    namespace :metadata_doe_projectMetadata2_namespace
    samples_count 3
  end

  project :projectGroupSampleTransfer do
    creator :mary_doe
    namespace :project_group_sample_transfer_namespace
    samples_count 3
  end

  project :projectGroupSampleTransferTarget do
    creator :mary_doe
    namespace :project_group_sample_transfer_target_namespace
    samples_count 0
  end

  project :projectGroupSampleActions do
    creator :sample_actions_doe
    namespace :project_group_sample_actions_namespace
    samples_count 1
  end

  project :projectSubGroupSampleActions do
    creator :sample_actions_doe
    namespace :project_subgroup_sample_actions_namespace
    samples_count 1
  end

  project :projectSharedGroupSampleActionsOwner do
    creator :shared_sample_actions_doe
    namespace :project_shared_group_sample_actions_owner_namespace
    samples_count 1
  end

  project :projectSharedGroupSampleActionsMaintainer do
    creator :shared_sample_actions_doe
    namespace :project_shared_group_sample_actions_maintainer_namespace
    samples_count 1
  end

  project :projectSharedGroupSampleActionsAnalyst do
    creator :shared_sample_actions_doe
    namespace :project_shared_group_sample_actions_analyst_namespace
    samples_count 1
  end

  project :projectSharedGroupSampleActionsGuest do
    creator :shared_sample_actions_doe
    namespace :project_shared_group_sample_actions_guest_namespace
    samples_count 1
  end

  project :projectUser31 do
    creator :user31
    namespace :projectUser31_namespace
    samples_count 1
  end

  project :projectChunkedSamples do
    creator :chunked_samples_doe
    namespace :project_chunked_samples_namespace
    samples_count 0
  end

  project :projectUser32 do
    creator :user32
    namespace :user32_project1_namespace
    samples_count 3
  end

  project :subgroup1Project1 do
    creator :john_doe
    namespace :public_subgroup1_project1_namespace
    samples_count 0
  end

  project :snvphyl_project do
    creator :snvphyl_user
    namespace :snvphyl_project_namespace
    samples_count 2
  end
end
