# frozen_string_literal: true

FixtureBot.define do
  member.user_id { FixtureBot::Key::Uuid.generate(:users, :john_doe) }
  member.created_by_id { FixtureBot::Key::Uuid.generate(:users, :john_doe) }
  member.access_level { Member::AccessLevel::OWNER }

  member :group_one_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
  end

  member :group_one_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    expires_at '<%= 10.days.from_now %>'
  end

  member :group_one_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 8.days.from_now %>'
  end

  member :group_one_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    access_level Member::AccessLevel::ANALYST
    expires_at '<%= 12.days.from_now %>'
  end

  member :group_one_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    access_level Member::AccessLevel::GUEST
    expires_at '<%= 12.days.from_now %>'
  end

  (Namespace::MAX_ANCESTORS - 2).times do |n|
    member(:"subgroup#{n + 1}_member_ryan_doe") do
      user :ryan_doe
      namespace_id FixtureBot::Key::Uuid.generate(:groups, :"subgroup#{n + 1}")
      access_level Member::AccessLevel::GUEST
    end
  end

  member :subgroup_six_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup6)
  end

  member :group_two_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_two)
  end

  member :group_two_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_two)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_three_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_three)
  end

  member :group_three_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_three)
  end

  member :group_three_member_micha_doe do
    user :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_three)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_three_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_three)
    access_level Member::AccessLevel::GUEST
  end

  member :subgroup_one_group_three_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_three)
  end

  member :subgroup_one_group_three_member_micha_doe do
    user :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_three)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_one_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
  end

  member :project_one_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_one_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    access_level Member::AccessLevel::GUEST
  end

  member :project_one_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_one_member_user_bot_account do
    user :user_bot_account0
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    access_level Member::AccessLevel::UPLOADER
  end

  member :project1_member_project_automation_bot do
    user :project1_automation_bot
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_two_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
  end

  member :project_two_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    expires_at '<%= 15.days.from_now %>'
  end

  member :project_two_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 8.days.from_now %>'
  end

  member :project_two_member_jean_doe do
    user :jean_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 12.days.from_now %>'
  end

  member :project_two_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project2_namespace)
    access_level Member::AccessLevel::GUEST
    expires_at '<%= 10.days.from_now %>'
  end

  member :project_two_member_james_doe_wo_john_doe_namespace do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
  end

  member :project_two_member_john_doe_wo_john_doe_namespace do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
  end

  member :project_two_member_michelle_doe_wo_john_doe_namespace do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_two_member_ryan_doe_wo_john_doe_namespace do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    access_level Member::AccessLevel::GUEST
  end

  member :project_three_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project3_namespace)
  end

  member :project_four_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :john_doe_project4_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_four_member_david_doe do
    user :david_doe
    created_by :david_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :david_doe_group_four)
  end

  member :group_five_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
  end

  member :group_five_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
  end

  member :group_five_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
    access_level Member::AccessLevel::GUEST
  end

  member :group_five_member_micha_doe do
    user :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_five)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_twenty_two_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
  end

  member :project_twenty_two_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
  end

  member :project_twenty_two_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_two_member_micha_doe do
    user :micha_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project22_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :subgroup_one_group_five_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_five)
  end

  member :group_six_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_six)
  end

  member :group_six_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_six)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_three_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project23_namespace)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_four_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project24_namespace)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_four_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project24_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_seven_group_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_seven)
  end

  25.times do |n|
    member(:"group_seven_group_member#{n}") do
      user :"user#{n}"
      namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_seven)
      access_level Member::AccessLevel::ANALYST
    end
  end

  25.times do |n|
    member(:"project_twenty_six_group_member#{n}") do
      user :"user#{n}"
      namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project26_namespace)
      access_level Member::AccessLevel::ANALYST
    end
  end

  member :project_twenty_six_group_member25 do
    user :user25
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project26_namespace)
  end

  [*('a'..'z')].each do |letter|
    member(:"group_#{letter}_member_alpha_bet") do
      user :alph_abet
      created_by :alph_abet
      namespace_id FixtureBot::Key::Uuid.generate(:groups, :"group_#{letter}")
    end
  end

  member :namespace_group_link8_member1 do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_one)
  end

  member :namespace_group_link_group_two_member1 do
    user :user24
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_two)
  end

  member :namespace_group_link9_member1 do
    user :user25
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :namespace_group_link_group_three)
  end

  member :group_eight_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_eight)
  end

  member :group_eight_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_eight)
  end

  member :group_eight_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_eight)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_eight_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_eight)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_nine_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_nine)
  end

  member :group_nine_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_nine)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :subgroup_one_group_nine_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_nine)
  end

  member :subgroup_one_group_nine_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_one_group_nine)
  end

  member :group_ten_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_ten)
  end

  member :group_ten_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_ten)
    access_level Member::AccessLevel::GUEST
  end

  member :group_alpha_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_alpha)
  end

  member :group_india_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_india)
  end

  member :group_juliett_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_juliett)
  end

  member :group_kilo_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_kilo)
  end

  member :group_lima_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_lima)
  end

  member :group_mike_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_mike)
  end

  member :group_oscar_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_oscar)
  end

  member :group_papa_member_private_ryan do
    user :private_ryan
    created_by :private_ryan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_papa)
  end

  member 'group_eleven_member_user_26' do
    user :user26
    created_by :user26
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_eleven)
  end

  member :group_twelve_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
  end

  member :group_twelve_member_jane_doe do
    user :jane_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_twelve)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_nine_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project29_namespace)
  end

  member :project_twenty_nine_member_jane_doe do
    user :jane_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project29_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_twenty_nine_member_michelle_doe do
    user :michelle_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project29_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_thirty_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project30_namespace)
  end

  member :project_thirty_one_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project31_namespace)
  end

  member :group_delta_member_joan_doe do
    user :private_joan
    created_by :private_joan
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_delta)
  end

  member 'group_golf_member_user_27' do
    user :user27
    created_by :user27
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_golf)
    access_level Member::AccessLevel::GUEST
  end

  member :group_hotel_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_hotel)
  end

  member 'group_hotel_project_one_member_user_28' do
    user :user28
    created_by :user28
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_hotel)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_thirteen_member_jane_doe do
    user :jane_doe
    created_by :jane_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_thirteen)
  end

  member :group_thirteen_member_james_doe do
    user :james_doe
    created_by :jane_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_thirteen)
    access_level Member::AccessLevel::GUEST
  end

  member :group_fourteen_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_fourteen)
  end

  member :group_fifteen_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_fifteen)
  end

  member :group_fifteen_member_joan_doe do
    user :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_fifteen)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_fifteen_member_james_doe do
    user :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_fifteen)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_fifteen_member_ryan_doe do
    user :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_fifteen)
    access_level Member::AccessLevel::GUEST
  end

  member :group_sixteen_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
  end

  member :group_sixteen_member_joan_doe do
    user :joan_doe
    created_by :joan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_sixteen_member_james_doe do
    user :james_doe
    created_by :james_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_sixteen_member_ryan_doe do
    user :ryan_doe
    created_by :ryan_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
    access_level Member::AccessLevel::GUEST
  end

  member :group_seventeen_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_seventeen)
  end

  member :group_one_member_user30 do
    user :user30
    created_by :user30
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :user30_group_one)
  end

  member :group_one_member_user_bot_account do
    user :user_group_bot_account0
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    access_level Member::AccessLevel::UPLOADER
    expires_at '<%= 20.days.from_now %>'
  end

  member :projectA_member_project_automation_bot do
    user :projectA_automation_bot
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_jane_doe do
    user :jane_doe
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_joan_doe do
    user :joan_doe
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_ryan_doe do
    user :ryan_doe
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectA_namespace)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_jeff_member_user_bot_account do
    user :projectJeff_bot
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_jeff_namespace)
    access_level Member::AccessLevel::UPLOADER
  end

  member :empty_group_member_empty_doe do
    user :empty_doe
    created_by :empty_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :empty_group)
  end

  member :group_jeff_member_jeff_doe do
    user :jeff_doe
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_jeff)
  end

  member :group_jeff_member_user_bot_account do
    user :groupJeff_bot
    created_by :jeff_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_jeff)
    access_level Member::AccessLevel::UPLOADER
    expires_at '<%= 20.days.from_now %>'
  end

  member :group_metadata_member_metadata_doe do
    user :metadata_doe
    created_by :metadata_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_metadata)
  end

  member :project_metadata_member_metadata_doe do
    user :metadata_doe
    created_by :metadata_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectMetadata_namespace)
  end

  member :group_sample_transfer_member_mary_doe do
    user :mary_doe
    created_by :mary_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_transfer)
  end

  member :group_sample_transfer_target_member_mary_doe do
    user :mary_doe
    created_by :mary_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_transfer_target)
  end

  member :group_sample_actions_member_sample_actions_doe do
    user :sample_actions_doe
    created_by :sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_sample_actions)
  end

  member :shared_group_sample_actions_owner_member_shared_sample_actions_doe do
    user :shared_sample_actions_doe
    created_by :shared_sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_owner)
  end

  member :shared_group_sample_actions_maintainer_member_shared_sample_actions_doe do
    user :shared_sample_actions_doe
    created_by :shared_sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_maintainer)
  end

  member :shared_group_sample_actions_analyst_member_shared_sample_actions_doe do
    user :shared_sample_actions_doe
    created_by :shared_sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_analyst)
  end

  member :shared_group_sample_actions_guest_member_shared_sample_actions_doe do
    user :shared_sample_actions_doe
    created_by :shared_sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :shared_group_sample_actions_guest)
  end

  member :subgroup_sample_actions_group_member_subgroup_sample_actions_doe do
    user :subgroup_sample_actions_doe
    created_by :sample_actions_doe
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :subgroup_sample_actions)
  end

  member :project_1_user_31_member_micha_doe do
    user :micha_doe
    created_by :user31
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :projectUser31_namespace)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_chunked_samples_member_chunked_samples_doe do
    user :chunked_samples_doe
    created_by :chunked_samples_doe
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_chunked_samples_namespace)
  end

  member :public_group_one_member_john_doe do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :public_group1)
  end

  member :snvphyl_group_member_snvphyl_user do
    user :snvphyl_user
    created_by :snvphyl_user
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :snvphyl_group)
  end

  member :clone_test_group_one_member_clone_test_maintainer_one do
    user :clone_test_maintainer_one
    created_by :clone_test_maintainer_one
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :clone_test_group_one)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :clone_test_group_two_member_clone_test_maintainer_two do
    user :clone_test_maintainer_two
    created_by :clone_test_maintainer_two
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :clone_test_group_two)
    access_level Member::AccessLevel::MAINTAINER
  end
end
