# frozen_string_literal: true

FixtureBot.define do
  group :group_one do
    type 'Group'
    metadata_summary({})
    name 'Group 1'
    path 'group-1'
    description 'Group 1 description'
    owner :john_doe
    metadata_summary({ 'metadatafield1' => 633, 'metadatafield2' => 106 })
    puid 'INXT_GRP_AAAAAAAAAA'
    attachments_updated_at '<%= 2.hours.ago %>'
    samples_count 25
  end

  group :subgroup1 do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1'
    path 'subgroup-1'
    description 'Subgroup 1 description'
    parent :group_one
    puid 'INXT_GRP_AAAAAAAAAB'
    samples_count 2
  end

  (Namespace::MAX_ANCESTORS - 2).times do |n|
    group(:"subgroup#{n + 2}") do
      type 'Group'
      metadata_summary({})
      name "Subgroup #{n + 2}"
      path "subgroup-#{n + 2}"
      description "Subgroup #{n + 2} description"
      parent :"subgroup#{n + 1}"
      puid "INXT_GRP_AAAAAA#{((n / 26).round + 66).chr}AA#{((n % 26) + 65).chr}"
      samples_count 0
    end
  end

  group :group_two do
    type 'Group'
    metadata_summary({})
    name 'Group 2'
    path 'group-2'
    description 'Group 2 description'
    puid 'INXT_GRP_AAAAAAAAAC'
    samples_count 0
  end

  group :group_three do
    type 'Group'
    metadata_summary({})
    name 'Group 3'
    path 'group-3'
    description 'Group 3 description'
    puid 'INXT_GRP_AAAAAAAAAD'
    samples_count 2
  end

  group :subgroup_one_group_three do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1 Group 3'
    path 'subgroup-1-group-3'
    description 'Subgroup 1 Group 3'
    parent :group_three
    puid 'INXT_GRP_AAAAAAAAAE'
    samples_count 2
  end

  group :david_doe_group_four do
    type 'Group'
    metadata_summary({})
    name 'Group 4'
    path 'group-4'
    description "David's first group"
    puid 'INXT_GRP_AAAAAAAAAF'
    metadata_summary({ 'unique.metadata.field' => 1, 'metadata field with spaces' => 1 })
    samples_count 1
  end

  group :group_five do
    type 'Group'
    metadata_summary({})
    name 'Group 5'
    path 'group-5'
    description 'Group 5 description'
    puid 'INXT_GRP_AAAAAAAAAG'
    samples_count 2
  end

  group :subgroup_one_group_five do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1 Group 5'
    path 'subgroup-1-group-5'
    description 'Subgroup 1 Group 5'
    parent :group_five
    puid 'INXT_GRP_AAAAAAAAAH'
    samples_count 0
  end

  group :group_six do
    type 'Group'
    metadata_summary({})
    name 'Group 6'
    path 'group-6'
    description 'Group 6 description'
    puid 'INXT_GRP_AAAAAAAAAI'
    samples_count 0
  end

  group :subgroup_one_group_six do
    type 'Group'
    metadata_summary({})
    name 'Group 6'
    path 'group-6'
    description 'Subgroup 1 description'
    parent :group_six
    puid 'INXT_GRP_AAAAAAAAAJ'
    samples_count 0
  end

  group :group_seven do
    type 'Group'
    metadata_summary({})
    name 'Group 7'
    path 'group-7'
    description 'Group 7 description'
    puid 'INXT_GRP_AAAAAAAAAK'
    samples_count 0
  end

  group :group_eight do
    type 'Group'
    metadata_summary({})
    name 'Group 8'
    path 'group-8'
    description 'Group 8 description'
    puid 'INXT_GRP_AAAAAAAAAL'
    samples_count 0
  end

  [*('a'..'z')].each_with_index do |letter, index|
    group(:"group_#{letter}") do
      type 'Group'
      metadata_summary({})
      name "Group #{letter.capitalize}"
      path "group-#{letter}"
      description "Group #{letter} description"
      created_at "<%= #{index + 1}.days.ago %>"
      updated_at "<%= #{index + 1}.days.ago %>"
      puid "INXT_GRP_AAAAAAABA#{letter.capitalize}"
      samples_count 0
    end
  end

  group :namespace_group_link_group_one do
    type 'Group'
    metadata_summary({})
    name 'Group One'
    path 'group-one'
    description 'Group One description'
    puid 'INXT_GRP_AAAAAAAAAM'
    samples_count 0
  end

  group :namespace_group_link_group_two do
    type 'Group'
    metadata_summary({})
    name 'Group Two'
    path 'group-two'
    description 'Group Two description'
    puid 'INXT_GRP_AAAAAAAAAN'
    samples_count 0
  end

  group :namespace_group_link_group_three do
    type 'Group'
    metadata_summary({})
    name 'Group Three'
    path 'group-three'
    description 'Group Three description'
    puid 'INXT_GRP_AAAAAAAAAO'
    samples_count 0
  end

  group :group_nine do
    type 'Group'
    metadata_summary({})
    name 'Group 9'
    path 'group-9'
    description 'Group 9 description'
    puid 'INXT_GRP_AAAAAAAAAP'
    samples_count 0
  end

  group :subgroup_one_group_nine do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1 Group 9'
    path 'subgroup-1-group-9'
    description 'Subgroup 1 Group 9 description'
    parent :group_nine
    puid 'INXT_GRP_AAAAAAAAAQ'
    samples_count 0
  end

  group :group_ten do
    type 'Group'
    metadata_summary({})
    name 'Group 10'
    path 'group-10-subgroup-1-group-9'
    description 'Group 10 description'
    parent :subgroup_one_group_nine
    puid 'INXT_GRP_AAAAAAAAAR'
    samples_count 0
  end

  group :group_alpha do
    type 'Group'
    metadata_summary({})
    name 'Group Alpha'
    path 'group-alpha'
    description 'Group Alpha description'
    puid 'INXT_GRP_AAAAAAAAAS'
    samples_count 2
  end

  group :group_bravo do
    type 'Group'
    metadata_summary({})
    name 'Group Bravo'
    path 'group-bravo'
    description 'Group bravo description'
    puid 'INXT_GRP_AAAAAAAAAT'
    samples_count 1
  end

  group :group_charlie do
    type 'Group'
    metadata_summary({})
    name 'Group Charlie'
    path 'group-charlie'
    description 'Group Charlie description'
    puid 'INXT_GRP_AAAAAAAAAU'
    samples_count 1
  end

  group :group_alpha_subgroup1 do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1'
    path 'group-alpha/subgroup-1'
    description 'Subgroup 1 description'
    parent :group_alpha
    puid 'INXT_GRP_AAAAAAAAAV'
    samples_count 1
  end

  group :group_eleven do
    type 'Group'
    metadata_summary({})
    name 'Group 11'
    path 'group-11'
    description 'Group 11 description'
    puid 'INXT_GRP_AAAAAAAAAW'
    samples_count 0
  end

  group :group_twelve do
    type 'Group'
    metadata_summary({})
    name 'Group 12'
    path 'group-12'
    description 'Group 12 description'
    owner :john_doe
    metadata_summary({ 'metadatafield1' => 3, 'metadatafield2' => 3 })
    puid 'INXT_GRP_AAAAAAAAAX'
    samples_count 4
  end

  group :subgroup_twelve_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 12 A'
    path 'subgroup-12-a'
    description 'Subgroup 12 A description'
    owner :john_doe
    parent :group_twelve
    metadata_summary({ 'metadatafield1' => 2, 'metadatafield2' => 2 })
    puid 'INXT_GRP_AAAAAAAAAY'
    samples_count 3
  end

  group :subgroup_twelve_b do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 12 B'
    path 'subgroup-12-b'
    description 'Subgroup 12 B description'
    owner :john_doe
    parent :group_twelve
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_GRP_AAAAAAAAAZ'
    samples_count 1
  end

  group :subgroup_twelve_a_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 12 A A'
    path 'subgroup-12-a-a'
    description 'Subgroup 12 A A description'
    owner :john_doe
    parent :subgroup_twelve_a
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    puid 'INXT_GRP_AAAAAAAAA2'
    samples_count 2
  end

  group :group_delta do
    type 'Group'
    metadata_summary({})
    name 'Group Delta'
    path 'group-delta'
    description 'Group Delta description'
    puid 'INXT_GRP_AAAAAAAAA3'
    samples_count 0
  end

  group :group_delta_subgroupA do
    type 'Group'
    metadata_summary({})
    name 'Subgroup A'
    path 'group-delta/subgroup-a'
    description 'Subgroup A description'
    parent :group_delta
    puid 'INXT_GRP_AAAAAAAAA4'
    samples_count 0
  end

  group :group_echo do
    type 'Group'
    metadata_summary({})
    name 'Group Echo'
    path 'group-echo'
    description 'Group Echo description'
    puid 'INXT_GRP_AAAAAAAAA5'
    samples_count 0
  end

  group :group_echo_subgroupB do
    type 'Group'
    metadata_summary({})
    name 'Subgroup B'
    path 'group-echo/subgroup-b'
    description 'Subgroup B description'
    parent :group_echo
    puid 'INXT_GRP_AAAAAAAAA6'
    samples_count 0
  end

  group :group_foxtrot do
    type 'Group'
    metadata_summary({})
    name 'Group Foxtrot'
    path 'group-foxtrot'
    description 'Group Foxtrot description'
    puid 'INXT_GRP_AAAAAAAAA7'
    samples_count 0
  end

  group :group_foxtrot_subgroupA do
    type 'Group'
    metadata_summary({})
    name 'Subgroup A'
    path 'group-foxtrot/subgroup-a'
    description 'Subgroup A description'
    parent :group_foxtrot
    puid 'INXT_GRP_AAAAAAAABA'
    samples_count 0
  end

  group :group_golf do
    type 'Group'
    metadata_summary({})
    name 'Group Golf'
    path 'group-golf'
    description 'Group Golf description'
    puid 'INXT_GRP_AAAAAAAABB'
    samples_count 0
  end

  group :group_hotel do
    type 'Group'
    metadata_summary({})
    name 'Group Hotel'
    path 'group-hotel'
    description 'Group Hotel description'
    owner :john_doe
    puid 'INXT_GRP_AAAAAAAABC'
    samples_count 1
  end

  group :group_thirteen do
    type 'Group'
    metadata_summary({})
    name 'Group 13'
    path 'group-13'
    description 'Group 13 description'
    puid 'INXT_GRP_AAAAAAAABD'
    samples_count 0
  end

  group :group_fourteen do
    type 'Group'
    metadata_summary({})
    name 'Group 14'
    path 'group-14'
    description 'Group 14 description'
    puid 'INXT_GRP_AAAAAAAABE'
    samples_count 1
  end

  group :group_fifteen do
    type 'Group'
    metadata_summary({})
    name 'Group 15'
    path 'group-15'
    description 'Group 15 description'
    puid 'INXT_GRP_AAAAAAAABF'
    samples_count 3
  end

  group :group_sixteen do
    type 'Group'
    metadata_summary({})
    name 'Group 16'
    path 'group-16'
    description 'Group 16 description'
    owner :john_doe
    puid 'INXT_GRP_AAAAAAAABG'
    samples_count 3
  end

  group :group_seventeen do
    type 'Group'
    metadata_summary({})
    name 'Group 17'
    path 'group-17'
    description 'Group 17 description'
    owner :john_doe
    puid 'INXT_GRP_AAAAAAAABI'
    samples_count 200
  end

  group :user30_group_one do
    type 'Group'
    metadata_summary({})
    name 'User 30 Group 1'
    path 'user-30-group-1'
    description 'Group 1 description'
    owner :user30
    puid 'INXT_GRP_AAAAAAAABH'
    samples_count 0
  end

  group :janitor_doe_group do
    type 'Group'
    metadata_summary({})
    name 'Group EndToEnd'
    path 'group-end_to_end'
    description 'Group 1 description'
    owner :janitor_doe
    puid 'INXT_GRP_ABAAAAAAAA'
    samples_count 0
  end

  group :empty_group do
    type 'Group'
    metadata_summary({})
    name 'Empty Group'
    path 'empty-group'
    description 'Group without any Samples'
    owner :empty_doe
    puid 'INXT_GRP_AAAAAAAABHI'
    samples_count 0
  end

  group :group_jeff do
    type 'Group'
    metadata_summary({})
    name 'Group Jeff'
    path 'group-jeff'
    description 'Group Jeff description'
    owner :jeff_doe
    puid 'INXT_GRP_AAAAAAJEFF'
    samples_count 0
  end

  group :group_india do
    type 'Group'
    metadata_summary({})
    name 'Group India'
    path 'group-india'
    description 'Group India description'
    puid 'INXT_GRP_AAAAAAAACA'
    samples_count 3
  end

  group :group_india_subgroup1 do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1'
    path 'group-india/subgroup-1'
    description 'Subgroup 1 description'
    parent :group_india
    puid 'INXT_GRP_AAAAAAAACB'
    samples_count 1
  end

  group :group_juliett do
    type 'Group'
    metadata_summary({})
    name 'Group Juliett'
    path 'group-juliett'
    description 'Group Juliett description'
    puid 'INXT_GRP_AAAAAAAACC'
    samples_count 3
  end

  group :group_juliett_subgroup1 do
    type 'Group'
    metadata_summary({})
    name 'Subgroup 1'
    path 'group-juliett/subgroup-1'
    description 'Subgroup 1 description'
    parent :group_juliett
    puid 'INXT_GRP_AAAAAAAACD'
    samples_count 1
  end

  group :group_kilo do
    type 'Group'
    metadata_summary({})
    name 'Group Kilo'
    path 'group-kilo'
    description 'Group Kilo description'
    puid 'INXT_GRP_AAAAAAAACE'
    samples_count 0
  end

  group :group_lima do
    type 'Group'
    metadata_summary({})
    name 'Group Lima'
    path 'group-lima'
    description 'Group Lima description'
    puid 'INXT_GRP_AAAAAAAACF'
    samples_count 0
  end

  group :group_mike do
    type 'Group'
    metadata_summary({})
    name 'Group Mike'
    path 'group-mike'
    description 'Group Mike description'
    puid 'INXT_GRP_AAAAAAAACG'
    samples_count 6
  end

  group :subgroup_mike_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Mike A'
    path 'subgroup-mike-a'
    description 'Subgroup Mike A description'
    parent :group_mike
    puid 'INXT_GRP_AAAAAAAACH'
    samples_count 2
  end

  group :subgroup_mike_b do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Mike B'
    path 'subgroup-mike-b'
    description 'Subgroup Mike B description'
    parent :group_mike
    puid 'INXT_GRP_AAAAAAAACI'
    samples_count 2
  end

  group :subgroup_mike_a_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Mike A A'
    path 'subgroup-mike-a-a'
    description 'Subgroup Mike A A description'
    parent :subgroup_mike_a
    puid 'INXT_GRP_AAAAAAAACJ'
    samples_count 0
  end

  group :group_oscar do
    type 'Group'
    metadata_summary({})
    name 'Group Oscar'
    path 'group-oscar'
    description 'Group Oscar description'
    puid 'INXT_GRP_AAAAAAAACK'
    samples_count 0
  end

  group :subgroup_oscar_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Oscar A'
    path 'subgroup-oscar-a'
    description 'Subgroup Oscar A description'
    parent :group_oscar
    puid 'INXT_GRP_AAAAAAAACL'
    samples_count 0
  end

  group :group_papa do
    type 'Group'
    metadata_summary({})
    name 'Group Papa'
    path 'group-papa'
    description 'Group Papa description'
    puid 'INXT_GRP_AAAAAAAACM'
    samples_count 0
  end

  group :subgroup_papa_a do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Papa A'
    path 'subgroup-papa-a'
    description 'Subgroup Papa A description'
    parent :group_papa
    puid 'INXT_GRP_AAAAAAAACN'
    samples_count 0
  end

  group :group_metadata do
    type 'Group'
    metadata_summary({})
    name 'Group Metadata'
    path 'group-metadata'
    description 'Group Metadata description'
    owner :metadata_doe
    metadata_summary({ 'example_date' => 3, 'example_float' => 3, 'example_integer' => 3 })
    puid 'INXT_GRP_AAAAAAAACO'
    samples_count 3
  end

  group :group_sample_transfer do
    type 'Group'
    metadata_summary({})
    name 'Group Sample Transfer'
    path 'group-sample-transfer'
    description 'Group Sample Transfer description'
    owner :mary_doe
    puid 'INXT_GRP_AAAAAAAACP'
    samples_count 3
  end

  group :group_sample_transfer_target do
    type 'Group'
    metadata_summary({})
    name 'Group Sample Transfer Target'
    path 'group-sample-transfer-target'
    description 'Group Sample Transfer Target description'
    owner :mary_doe
    puid 'INXT_GRP_AAAAAAAACQ'
    samples_count 0
  end

  group :group_sample_actions do
    type 'Group'
    metadata_summary({})
    name 'Group Sample Actions'
    path 'group-sample-actions'
    description 'Group Sample Actions description'
    owner :sample_actions_doe
    puid 'INXT_GRP_AAAAAAAACR'
    metadata_summary({ 'metadatafield1' => 2, 'metadatafield2' => 2 })
    samples_count 2
  end

  group :subgroup_sample_actions do
    type 'Group'
    metadata_summary({})
    name 'Subgroup Sample Actions'
    path 'subgroup-sample-actions'
    description 'Subgroup Sample Actions description'
    parent :group_sample_actions
    puid 'INXT_GRP_AAAAAAAACS'
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    samples_count 1
  end

  group :shared_group_sample_actions_owner do
    type 'Group'
    metadata_summary({})
    name 'Shared Group Sample Actions Owner'
    path 'shared-group-sample-actions-owner'
    description 'Shared Group Sample Actions Owner description'
    owner :shared_sample_actions_doe
    puid 'INXT_GRP_AAAAAAAACT'
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    samples_count 1
  end

  group :shared_group_sample_actions_maintainer do
    type 'Group'
    metadata_summary({})
    name 'Shared Group Sample Actions Maintainer'
    path 'shared-group-sample-actions-maintainer'
    description 'Shared Group Sample Actions Maintainer description'
    owner :shared_sample_actions_doe
    puid 'INXT_GRP_AAAAAAAACU'
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    samples_count 1
  end

  group :shared_group_sample_actions_analyst do
    type 'Group'
    metadata_summary({})
    name 'Shared Group Sample Actions Analyst'
    path 'shared-group-sample-actions-analyst'
    description 'Shared Group Sample Actions Analyst description'
    owner :shared_sample_actions_doe
    puid 'INXT_GRP_AAAAAAAACV'
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    samples_count 1
  end

  group :shared_group_sample_actions_guest do
    type 'Group'
    metadata_summary({})
    name 'Shared Group Sample Actions Guest'
    path 'shared-group-sample-actions-guest'
    description 'Shared Group Sample Actions Guest description'
    owner :shared_sample_actions_doe
    puid 'INXT_GRP_AAAAAAAACW'
    metadata_summary({ 'metadatafield1' => 1, 'metadatafield2' => 1 })
    samples_count 1
  end

  (1..10).each do |n|
    group(:"public_group#{n}") do
      type 'Group'
      metadata_summary({})
      name "Public Group #{n}"
      send(:public, true) # `public` column name collides with Ruby's `public` keyword
      path "public-group-#{n}"
      description "Public Group #{n} description"
      puid "INXT_GRP_AXATAA#{((n / 26).round + 66).chr}AA#{((n % 26) + 65).chr}"
      samples_count 0
      created_at "<%= #{n + 1}.days.ago %>"
      updated_at "<%= #{n + 1}.days.ago %>"
    end
  end

  group :public_group1_subgroup1 do
    type 'Group'
    metadata_summary({})
    name 'Public Subgroup 1'
    send(:public, true) # `public` column name collides with Ruby's `public` keyword
    path 'public-group-1-subgroup-1'
    description 'Public Subgroup 1 description'
    puid 'INXT_GRP_AXATAABAAL'
    parent :public_group1
    samples_count 0
    created_at '<%= 1.days.ago %>'
    updated_at '<%= 1.days.ago %>'
  end

  group :snvphyl_group do
    type 'Group'
    metadata_summary({})
    name 'SNVPhyl Group'
    path 'snvphyl-group'
    description 'SNVPhyl Group description'
    owner :snvphyl_user
    metadata_summary({ 'metadata_1' => 2, 'metadata_2' => 2, 'metadata_3' => 2, 'metadata_4' => 2, 'metadata_5' => 2,
                       'metadata_6' => 2, 'metadata_7' => 2, 'metadata_8' => 2 })
    puid 'INXT_GRP_AAAAAAAACX'
    attachments_updated_at '<%= 2.hours.ago %>'
    samples_count 2
  end

  group :clone_test_group_one do
    type 'Group'
    metadata_summary({})
    name 'Clone Test Group One'
    path 'clone-test-group-one'
    description 'Group for testing clone with no available projects'
    owner :clone_test_maintainer_one
    puid 'INXT_GRP_AAAAAAAACY'
    samples_count 0
  end

  group :clone_test_group_two do
    type 'Group'
    metadata_summary({})
    name 'Clone Test Group Two'
    path 'clone-test-group-two'
    description 'Group for testing clone with no available destination groups'
    owner :clone_test_maintainer_two
    puid 'INXT_GRP_AAAAAAAACZ'
    samples_count 0
  end
end
