# frozen_string_literal: true

FixtureBot.define do
  member :group_one_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_one_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::OWNER
    expires_at '<%= 10.days.from_now %>'
  end

  member :group_one_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 8.days.from_now %>'
  end

  member :group_one_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::ANALYST
    expires_at '<%= 12.days.from_now %>'
  end

  member :group_one_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::GUEST
    expires_at '<%= 12.days.from_now %>'
  end

  (Namespace::MAX_ANCESTORS - 2).times do |n|
    member(:"subgroup#{n + 1}_member_ryan_doe") do
      user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
      created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
      namespace_id ActiveRecord::FixtureSet.identify(:"subgroup#{n + 1}", :uuid)
      access_level Member::AccessLevel::GUEST
    end
  end

  member :subgroup_six_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup6, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_two_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_two, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_two_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_two, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_three_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_three, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_three_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_three, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_three_member_micha_doe do
    user_id ActiveRecord::FixtureSet.identify(:micha_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_three, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_three_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_three, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :subgroup_one_group_three_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_three, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :subgroup_one_group_three_member_micha_doe do
    user_id ActiveRecord::FixtureSet.identify(:micha_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_three, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_one_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_one_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_one_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_one_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_one_member_user_bot_account do
    user_id ActiveRecord::FixtureSet.identify(:user_bot_account0, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::UPLOADER
  end

  member :project1_member_project_automation_bot do
    user_id ActiveRecord::FixtureSet.identify(:project1_automation_bot, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_two_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_two_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
    expires_at '<%= 15.days.from_now %>'
  end

  member :project_two_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 8.days.from_now %>'
  end

  member :project_two_member_jean_doe do
    user_id ActiveRecord::FixtureSet.identify(:jean_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
    expires_at '<%= 12.days.from_now %>'
  end

  member :project_two_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project2_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
    expires_at '<%= 10.days.from_now %>'
  end

  member :project_two_member_james_doe_wo_john_doe_namespace do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_two_member_john_doe_wo_john_doe_namespace do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_two_member_michelle_doe_wo_john_doe_namespace do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_two_member_ryan_doe_wo_john_doe_namespace do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_three_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project3_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_four_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_project4_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_four_member_david_doe do
    user_id ActiveRecord::FixtureSet.identify(:david_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:david_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:david_doe_group_four, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_five_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_five_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_five_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_five_member_micha_doe do
    user_id ActiveRecord::FixtureSet.identify(:micha_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_five, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_twenty_two_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_twenty_two_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_twenty_two_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_two_member_micha_doe do
    user_id ActiveRecord::FixtureSet.identify(:micha_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project22_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :subgroup_one_group_five_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_five, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_six_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_six, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_six_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_six, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_three_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project23_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_four_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project24_namespace, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_four_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project24_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_seven_group_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_seven, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  25.times do |n|
    member(:"group_seven_group_member#{n}") do
      user_id ActiveRecord::FixtureSet.identify(:"user#{n}", :uuid)
      created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
      namespace_id ActiveRecord::FixtureSet.identify(:group_seven, :uuid)
      access_level Member::AccessLevel::ANALYST
    end
  end

  25.times do |n|
    member(:"project_twenty_six_group_member#{n}") do
      user_id ActiveRecord::FixtureSet.identify(:"user#{n}", :uuid)
      created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
      namespace_id ActiveRecord::FixtureSet.identify(:project26_namespace, :uuid)
      access_level Member::AccessLevel::ANALYST
    end
  end

  member :project_twenty_six_group_member25 do
    user_id ActiveRecord::FixtureSet.identify(:user25, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project26_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  [*('a'..'z')].each do |letter|
    member(:"group_#{letter}_member_alpha_bet") do
      user_id ActiveRecord::FixtureSet.identify(:alph_abet, :uuid)
      created_by_id ActiveRecord::FixtureSet.identify(:alph_abet, :uuid)
      namespace_id ActiveRecord::FixtureSet.identify(:"group_#{letter}", :uuid)
      access_level Member::AccessLevel::OWNER
    end
  end

  member :namespace_group_link8_member1 do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_one, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :namespace_group_link_group_two_member1 do
    user_id ActiveRecord::FixtureSet.identify(:user24, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_two, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :namespace_group_link9_member1 do
    user_id ActiveRecord::FixtureSet.identify(:user25, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:namespace_group_link_group_three, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_eight_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_eight, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_eight_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_eight, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_eight_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_eight, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_eight_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_eight, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_nine_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_nine, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_nine_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_nine, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :subgroup_one_group_nine_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_nine, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :subgroup_one_group_nine_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_one_group_nine, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_ten_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_ten, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_ten_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_ten, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_alpha_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_alpha, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_india_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_india, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_juliett_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_juliett, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_kilo_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_kilo, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_lima_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_lima, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_mike_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_mike, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_oscar_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_oscar, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_papa_member_private_ryan do
    user_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_ryan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_papa, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member 'group_eleven_member_user_26' do
    user_id ActiveRecord::FixtureSet.identify(:user26, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:user26, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_eleven, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_twelve_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_twelve_member_jane_doe do
    user_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_twelve, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :project_twenty_nine_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project29_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_twenty_nine_member_jane_doe do
    user_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project29_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_twenty_nine_member_michelle_doe do
    user_id ActiveRecord::FixtureSet.identify(:michelle_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project29_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_thirty_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project30_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_thirty_one_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project31_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_delta_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:private_joan, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_delta, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member 'group_golf_member_user_27' do
    user_id ActiveRecord::FixtureSet.identify(:user27, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:user27, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_golf, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_hotel_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_hotel, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member 'group_hotel_project_one_member_user_28' do
    user_id ActiveRecord::FixtureSet.identify(:user28, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:user28, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_hotel, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_thirteen_member_jane_doe do
    user_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_thirteen, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_thirteen_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_thirteen, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_fourteen_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_fourteen, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_fifteen_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_fifteen, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_fifteen_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_fifteen, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_fifteen_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_fifteen, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_fifteen_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_fifteen, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_sixteen_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_sixteen_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :group_sixteen_member_james_doe do
    user_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:james_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :group_sixteen_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
    access_level Member::AccessLevel::GUEST
  end

  member :group_seventeen_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_seventeen, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_one_member_user30 do
    user_id ActiveRecord::FixtureSet.identify(:user30, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:user30, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:user30_group_one, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_one_member_user_bot_account do
    user_id ActiveRecord::FixtureSet.identify(:user_group_bot_account0, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    access_level Member::AccessLevel::UPLOADER
    expires_at '<%= 20.days.from_now %>'
  end

  member :projectA_member_project_automation_bot do
    user_id ActiveRecord::FixtureSet.identify(:projectA_automation_bot, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_jane_doe do
    user_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_joan_doe do
    user_id ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :projectA_member_ryan_doe do
    user_id ActiveRecord::FixtureSet.identify(:ryan_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid)
    access_level Member::AccessLevel::ANALYST
  end

  member :project_jeff_member_user_bot_account do
    user_id ActiveRecord::FixtureSet.identify(:projectJeff_bot, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_jeff_namespace, :uuid)
    access_level Member::AccessLevel::UPLOADER
  end

  member :empty_group_member_empty_doe do
    user_id ActiveRecord::FixtureSet.identify(:empty_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:empty_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:empty_group, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_jeff_member_jeff_doe do
    user_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_jeff, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_jeff_member_user_bot_account do
    user_id ActiveRecord::FixtureSet.identify(:groupJeff_bot, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_jeff, :uuid)
    access_level Member::AccessLevel::UPLOADER
    expires_at '<%= 20.days.from_now %>'
  end

  member :group_metadata_member_metadata_doe do
    user_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_metadata, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_metadata_member_metadata_doe do
    user_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:metadata_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectMetadata_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_sample_transfer_member_mary_doe do
    user_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sample_transfer, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_sample_transfer_target_member_mary_doe do
    user_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:mary_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sample_transfer_target, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :group_sample_actions_member_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:group_sample_actions, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :shared_group_sample_actions_owner_member_shared_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_owner, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :shared_group_sample_actions_maintainer_member_shared_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_maintainer, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :shared_group_sample_actions_analyst_member_shared_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_analyst, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :shared_group_sample_actions_guest_member_shared_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:shared_sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:shared_group_sample_actions_guest, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :subgroup_sample_actions_group_member_subgroup_sample_actions_doe do
    user_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:subgroup_sample_actions, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :project_1_user_31_member_micha_doe do
    user_id ActiveRecord::FixtureSet.identify(:micha_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:user31, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:projectUser31_namespace, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :project_chunked_samples_member_chunked_samples_doe do
    user_id ActiveRecord::FixtureSet.identify(:chunked_samples_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:chunked_samples_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:project_chunked_samples_namespace, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :public_group_one_member_john_doe do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:public_group1, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :snvphyl_group_member_snvphyl_user do
    user_id ActiveRecord::FixtureSet.identify(:snvphyl_user, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:snvphyl_user, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:snvphyl_group, :uuid)
    access_level Member::AccessLevel::OWNER
  end

  member :clone_test_group_one_member_clone_test_maintainer_one do
    user_id ActiveRecord::FixtureSet.identify(:clone_test_maintainer_one, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:clone_test_maintainer_one, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:clone_test_group_one, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end

  member :clone_test_group_two_member_clone_test_maintainer_two do
    user_id ActiveRecord::FixtureSet.identify(:clone_test_maintainer_two, :uuid)
    created_by_id ActiveRecord::FixtureSet.identify(:clone_test_maintainer_two, :uuid)
    namespace_id ActiveRecord::FixtureSet.identify(:clone_test_group_two, :uuid)
    access_level Member::AccessLevel::MAINTAINER
  end
end
