# frozen_string_literal: true

FixtureBot.define do
  project :project1 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    samples_count 3
  end

  project :project2 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    samples_count 20
  end

  project :john_doe_project2 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    samples_count 1
  end

  project :john_doe_project3 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project3_namespace, :uuid)
    samples_count 0
  end

  project :john_doe_project4 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project4_namespace, :uuid)
    samples_count 0
  end

  project :project4 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project4_namespace, :uuid)
    samples_count 2
  end

  project :project5 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project5_namespace, :uuid)
    samples_count 0
  end

  project :project6 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project6_namespace, :uuid)
    samples_count 0
  end

  project :project7 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project7_namespace, :uuid)
    samples_count 0
  end

  project :project8 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project8_namespace, :uuid)
    samples_count 0
  end

  project :project9 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project9_namespace, :uuid)
    samples_count 0
  end

  project :project10 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project10_namespace, :uuid)
    samples_count 0
  end

  project :project11 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project11_namespace, :uuid)
    samples_count 0
  end

  project :project12 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project12_namespace, :uuid)
    samples_count 0
  end

  project :project13 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project13_namespace, :uuid)
    samples_count 0
  end

  project :project14 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project14_namespace, :uuid)
    samples_count 0
  end

  project :project15 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project15_namespace, :uuid)
    samples_count 0
  end

  project :project16 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project16_namespace, :uuid)
    samples_count 0
  end

  project :project17 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project17_namespace, :uuid)
    samples_count 0
  end

  project :project18 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project18_namespace, :uuid)
    samples_count 0
  end

  project :project19 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project19_namespace, :uuid)
    samples_count 0
  end

  project :project20 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project20_namespace, :uuid)
    samples_count 0
  end

  project :project21 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project21_namespace, :uuid)
    samples_count 0
  end

  project :project22 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    samples_count 2
  end

  project :project23 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project23_namespace, :uuid)
    samples_count 0
  end

  project :project24 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project24_namespace, :uuid)
    samples_count 0
  end

  project :project25 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project25_namespace, :uuid)
    samples_count 2
  end

  project :project26 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project26_namespace, :uuid)
    samples_count 3
  end

  project :project32 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project32_namespace, :uuid)
    samples_count 0
  end

  project :projectA do
    creator_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    samples_count 3
  end

  project :namespace_group_link_group_one_project1 do
    creator_id ActiveRecord::FixtureSet.identify(:user24, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_one_project1_namespace, :uuid)
    samples_count 0
  end

  project :namespace_group_link_group_three_project1 do
    creator_id ActiveRecord::FixtureSet.identify(:user24, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three_project1_namespace, :uuid)
    samples_count 0
  end

  project :project28 do
    creator_id ActiveRecord::FixtureSet.identify(:david_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project28_namespace, :uuid)
    samples_count 1
  end

  project :project29 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project29_namespace, :uuid)
    samples_count 1
  end

  project :project30 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project30_namespace, :uuid)
    samples_count 1
  end

  project :project31 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project31_namespace, :uuid)
    samples_count 2
  end

  project :projectAlpha do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectAlpha_namespace, :uuid)
    samples_count 1
  end

  project :projectBravo do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectBravo_namespace, :uuid)
    samples_count 1
  end

  project :projectCharlie do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectCharlie_namespace, :uuid)
    samples_count 1
  end

  project :projectAlpha1 do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectAlpha1_namespace, :uuid)
    samples_count 1
  end

  project :projectDelta do
    creator_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectDelta_namespace, :uuid)
    samples_count 0
  end

  project :projectEcho do
    creator_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectEcho_namespace, :uuid)
    samples_count 0
  end

  project :projectDeltaSubgroupA do
    creator_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectDeltaSubgroupA_namespace, :uuid)
    samples_count 0
  end

  project :projectEchoSubgroupB do
    creator_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectEchoSubgroupB_namespace, :uuid)
    samples_count 0
  end

  project :projectFoxtrotSubgroupA do
    creator_id ActiveRecord::FixtureSet.identify(:private_micha, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectFoxtrotSubgroupA_namespace, :uuid)
    samples_count 0
  end

  project :project27 do
    creator_id ActiveRecord::FixtureSet.identify(:user27, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:user27_project1_namespace, :uuid)
    samples_count 0
  end

  project :projectHotel do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectHotel_namespace, :uuid)
    samples_count 1
  end

  project :projectJeff do
    creator_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_jeff_namespace, :uuid)
    samples_count 1
  end

  project :project33 do
    creator_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project33_namespace, :uuid)
    samples_count 0
  end

  project :project34 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project34_namespace, :uuid)
    samples_count 1
  end

  project :project35 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project35_namespace, :uuid)
    samples_count 3
  end

  project :project36 do
    creator_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_jeff_namespace, :uuid)
    samples_count 2
  end

  project :project37 do
    creator_id ActiveRecord::FixtureSet.identify(:user21, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project37_namespace, :uuid)
    samples_count 3
  end

  project :project38 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project38_namespace, :uuid)
    samples_count 200
  end

  project :user29_project1 do
    creator_id ActiveRecord::FixtureSet.identify(:user29, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:user29_project1_namespace, :uuid)
    samples_count 1
  end

  project :project_janitor_end_to_end do
    creator_id ActiveRecord::FixtureSet.identify(:janitor_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_janitor_namespace, :uuid)
    samples_count 1
  end

  project :project_janitor_DELETE do
    creator_id ActiveRecord::FixtureSet.identify(:janitor_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_janitor_namespace, :uuid)
    samples_count 4
  end

  project :empty_project do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:empty_project_namespace, :uuid)
    samples_count 0
  end

  project :projectIndia do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectIndia_namespace, :uuid)
    samples_count 2
  end

  project :projectIndia1 do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectIndia1_namespace, :uuid)
    samples_count 1
  end

  project :projectJuliett do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectJuliett_namespace, :uuid)
    samples_count 2
  end

  project :projectJuliett1 do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectJuliett1_namespace, :uuid)
    samples_count 1
  end

  project :projectMike do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMike_namespace, :uuid)
    samples_count 2
  end

  project :projectMikeA do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMikeA_namespace, :uuid)
    samples_count 2
  end

  project :projectMikeB do
    creator_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMikeB_namespace, :uuid)
    samples_count 2
  end

  project :projectMetadata do
    creator_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMetadata_namespace, :uuid)
    samples_count 3
  end

  project :projectMetadata2 do
    creator_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:metadata_doe_projectMetadata2_namespace, :uuid)
    samples_count 3
  end

  project :projectGroupSampleTransfer do
    creator_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_group_sample_transfer_namespace, :uuid)
    samples_count 3
  end

  project :projectGroupSampleTransferTarget do
    creator_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_group_sample_transfer_target_namespace, :uuid)
    samples_count 0
  end

  project :projectGroupSampleActions do
    creator_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_group_sample_actions_namespace, :uuid)
    samples_count 1
  end

  project :projectSubGroupSampleActions do
    creator_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_subgroup_sample_actions_namespace, :uuid)
    samples_count 1
  end

  project :projectSharedGroupSampleActionsOwner do
    creator_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_owner_namespace, :uuid)
    samples_count 1
  end

  project :projectSharedGroupSampleActionsMaintainer do
    creator_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_maintainer_namespace, :uuid)
    samples_count 1
  end

  project :projectSharedGroupSampleActionsAnalyst do
    creator_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_analyst_namespace, :uuid)
    samples_count 1
  end

  project :projectSharedGroupSampleActionsGuest do
    creator_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_shared_group_sample_actions_guest_namespace, :uuid)
    samples_count 1
  end

  project :projectUser31 do
    creator_id ActiveRecord::FixtureSet.identify(:user31, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectUser31_namespace, :uuid)
    samples_count 1
  end

  project :projectChunkedSamples do
    creator_id ActiveRecord::FixtureSet.identify(:chunked_samples_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_chunked_samples_namespace, :uuid)
    samples_count 0
  end

  project :projectUser32 do
    creator_id ActiveRecord::FixtureSet.identify(:user32, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:user32_project1_namespace, :uuid)
    samples_count 3
  end

  project :subgroup1Project1 do
    creator_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:public_subgroup1_project1_namespace, :uuid)
    samples_count 0
  end

  project :snvphyl_project do
    creator_id ActiveRecord::FixtureSet.identify(:snvphyl_user, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:snvphyl_project_namespace, :uuid)
    samples_count 2
  end
end
