# frozen_string_literal: true

FixtureBot.define do
  sample :sample1 do
    name 'Project 1 Sample 1'
    description 'Sample 1 description.'
    project :project1
    puid 'INXT_SAM_AAAAAAAAAA'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 3.hours.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample2 do
    name 'Project 1 Sample 2'
    description 'Sample 2 description.'
    project :project1
    puid 'INXT_SAM_AAAAAAAAAB'
    created_at '<%= 2.weeks.ago %>'
    updated_at '<%= 2.days.ago %>'
  end

  (3..21).each do |n|
    sample(:"sample#{n}") do
      name "Project 2 Sample #{n}"
      description "Sample #{n} description."
      project :project2
      puid "INXT_SAM_AAAAAAAAA#{((n % 26) + 64).chr}"
      created_at "<%= #{n}.weeks.ago %>"
      updated_at "<%= #{n}.days.ago %>"
    end
  end

  sample :sample22 do
    name 'Project 2 Sample 22'
    description 'Sample 22 description.'
    project :project2
    puid 'INXT_SAM_AAAAAAAAAV'
    created_at '<%= 22.weeks.ago %>'
    updated_at '<%= 22.days.ago %>'
  end

  sample :sample23 do
    name 'Project 4 Sample 23'
    description 'Sample 23 description.'
    project :project4
    puid 'INXT_SAM_AAAAAAAAAW'
    created_at '<%= 23.weeks.ago %>'
    updated_at '<%= 23.days.ago %>'
  end

  sample '1234' do
    name 1234
    description '1234 description.'
    project :project4
    puid 'INXT_SAM_BAAAAAAAAA'
    created_at '<%= 23.weeks.ago %>'
    updated_at '<%= 23.days.ago %>'
  end

  sample :sample24 do
    name 'John Doe Project 2 Sample 1'
    description 'John Doe Project 2 Sample 1 description.'
    project :john_doe_project2
    puid 'INXT_SAM_AAAAAAAAAX'
    created_at '<%= 24.weeks.ago %>'
    updated_at '<%= 24.days.ago %>'
  end

  sample :sample25 do
    name 'Project 25 Sample 1'
    description 'Sample 1 description.'
    project :project25
    puid 'INXT_SAM_AAAAAAAAAY'
    created_at '<%= 25.weeks.ago %>'
    updated_at '<%= 25.days.ago %>'
  end

  sample :sample26 do
    name 'Project 26 Sample 1'
    description 'Sample 1 description.'
    project :project26
    puid 'INXT_SAM_AAAAAAAAAZ'
    created_at '<%= 26.weeks.ago %>'
    updated_at '<%= 26.days.ago %>'
  end

  sample :sample27 do
    name 'Project 26 Sample 2'
    description 'Sample 2 description.'
    project :project26
    puid 'INXT_SAM_AAAAAAAAA2'
    created_at '<%= 27.weeks.ago %>'
    updated_at '<%= 27.days.ago %>'
  end

  sample :sampleA do
    name 'Project A Sample 1'
    description 'Sample 1 description.'
    project :projectA
    puid 'INXT_SAM_AAAAAAAAA3'
    created_at '<%= 28.weeks.ago %>'
    updated_at '<%= 28.days.ago %>'
    attachments_updated_at '<%= 28.hours.ago %>'
  end

  sample :sampleB do
    name 'Project A Sample B'
    description 'Sample B description.'
    project :projectA
    puid 'INXT_SAM_AAAAAAAAA4'
    created_at '<%= 29.weeks.ago %>'
    updated_at '<%= 29.days.ago %>'
    attachments_updated_at '<%= 29.hours.ago %>'
  end

  sample :sampleC do
    name 'Project A Sample C'
    description 'Sample C description.'
    project :projectA
    puid 'INXT_SAM_AAAAAAAAA5'
    created_at '<%= 30.weeks.ago %>'
    updated_at '<%= 30.days.ago %>'
    attachments_updated_at '<%= 30.hours.ago %>'
  end

  sample :sample28 do
    name 'Project 28 Sample 1'
    description 'Sample 1 description.'
    project :project28
    puid 'INXT_SAM_AAAAAAAAA6'
    created_at '<%= 31.weeks.ago %>'
    updated_at '<%= 31.days.ago %>'
    metadata({ 'unique.metadata.field' => 'unique_value', 'metadata field with spaces' => 'spaces value' })
    metadata_provenance({
                          'unique.metadata.field' => { 'id' => 1, 'source' => 'analysis',
                                                       'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadata field with spaces' => { 'id' => 1, 'source' => 'analysis',
                                                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample29 do
    name 'Sample 2'
    description 'Sample 2 description.'
    project :project25
    puid 'INXT_SAM_AAAAAAAAA7'
    created_at '<%= 32.weeks.ago %>'
    updated_at '<%= 32.days.ago %>'
  end

  sample :sample30 do
    name 'Sample 2'
    description 'Sample 2 description.'
    project :project1
    puid 'INXT_SAM_AAAAAAAABA'
    created_at '<%= 33.weeks.ago %>'
    updated_at '<%= 33.days.ago %>'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample31 do
    name 'Sample 2'
    description 'Sample 2 description.'
    project :project26
    puid 'INXT_SAM_AAAAAAAABB'
    created_at '<%= 34.weeks.ago %>'
    updated_at '<%= 34.days.ago %>'
  end

  sample :sample32 do
    name 'Sample 32'
    description 'Sample 32 description.'
    project :project29
    puid 'INXT_SAM_AAAAAAAABC'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :john_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'metadatafield2' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :john_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample33 do
    name 'Sample33'
    description 'Sample 33 description.'
    project :project30
    puid 'INXT_SAM_AAAAAAAABD'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :john_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'metadatafield2' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :john_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample34 do
    name 'Sample 34'
    description 'Sample 34 description.'
    project :project31
    puid 'INXT_SAM_AAAAAAAABE'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample35 do
    name 'Sample 35'
    description 'Sample 35 description.'
    project :project31
    puid 'INXT_SAM_AAAAAAAABF'
  end

  sample :sampleAlpha do
    name 'Sample Alpha'
    description 'Sample Alpha description.'
    project :projectAlpha
    puid 'INXT_SAM_AAAAAAAABG'
    created_at '<%= 35.week.ago %>'
    updated_at '<%= 35.day.ago %>'
  end

  sample :sampleBravo do
    name 'Sample Bravo'
    description 'Sample Bravo description.'
    project :projectBravo
    puid 'INXT_SAM_AAAAAAAABH'
    created_at '<%= 36.week.ago %>'
    updated_at '<%= 36.day.ago %>'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sampleCharlie do
    name 'Sample Charlie'
    description 'Sample Charlie description.'
    project :projectCharlie
    puid 'INXT_SAM_AAAAAAAABI'
    created_at '<%= 37.week.ago %>'
    updated_at '<%= 37.day.ago %>'
  end

  sample :sampleAlpha1 do
    name 'Sample Alpha 1'
    description 'Sample Alpha 1 description.'
    project :projectAlpha1
    puid 'INXT_SAM_AAAAAAAABJ'
    created_at '<%= 38.week.ago %>'
    updated_at '<%= 38.day.ago %>'
  end

  sample :sample36 do
    name 'Sample 36'
    description 'Sample 36 description.'
    project :projectHotel
    puid 'INXT_SAM_AAAAAAAABK'
  end

  sample :sampleJeff do
    name 'Sample Jeff'
    description 'Sample Jeff description.'
    project :projectJeff
    puid 'INXT_SAM_AAAAAAAABL'
  end

  sample :sample37 do
    name 'Project 1 Sample 2'
    description 'Sample with the same name.'
    project :project34
    puid 'INXT_SAM_AAAAAAAABM'
  end

  sample :sample38 do
    name 'Project 35 Sample 1'
    description 'Sample 1 description.'
    project :project35
    puid 'INXT_SAM_AAAAAAAABN'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample39 do
    name 'Project 35 Sample 2'
    description 'Sample 2 description.'
    project :project35
    puid 'INXT_SAM_AAAAAAAABO'
    created_at '<%= 2.weeks.ago %>'
    updated_at '<%= 2.days.ago %>'
  end

  sample :sample40 do
    name 'Project 35 Sample 3'
    description 'Sample 3 description.'
    project :project35
    puid 'INXT_SAM_AAAAAAAABP'
    created_at '<%= 2.weeks.ago %>'
    updated_at '<%= 2.days.ago %>'
  end

  sample :sample41 do
    name 'WorkflowExecutions test sample 1'
    description 'Sample description.'
    project :project36
    puid 'INXT_SAM_AAAAAAAABQ'
    created_at '<%= 2.weeks.ago %>'
    updated_at '<%= 2.days.ago %>'
    metadata({ 'metadatafield1' => 'value1', 'organism' => 'the organism' })
  end

  sample :sample42 do
    name 'WorkflowExecutions test sample 2'
    description 'Sample description.'
    project :project36
    puid 'INXT_SAM_AAAAAAAABR'
    created_at '<%= 2.weeks.ago %>'
    updated_at '<%= 2.days.ago %>'
    metadata({ 'metadatafield2' => 'value2', 'organism' => 'some organism' })
  end

  sample :sample43 do
    name 'Sample 43'
    description 'Sample 43 description.'
    project :project37
    puid 'INXT_SAM_AAAAAAAABS'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
    metadata({ 'insdc_accession' => 'ERR86724108', 'country' => 'Canada' })
  end

  sample :sample44 do
    name 'Sample 44'
    description 'Sample 44 description.'
    project :project37
    puid 'INXT_SAM_AAAAAAAABT'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
    metadata({ 'insdc_accession' => 'ERR31551163', 'country' => 'Moldova' })
  end

  sample :sample45 do
    name 'Sample 45'
    description 'Sample 45 description.'
    project :user29_project1
    puid 'INXT_SAM_AAAAAAAABU'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample46 do
    name 'Sample 46'
    description 'Sample 46 description.'
    project :project37
    puid 'INXT_SAM_AAAAAAAABV'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sampleEndToEnd do
    name 'Sample EndToEnd'
    description 'Sample EndToEnd description.'
    project :project_janitor_end_to_end
    puid 'INXT_SAM_ABAAAAAAAA'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sampleDELETE do
    name 'Sample EndToEnd'
    description 'Sample EndToEnd description.'
    project :project_janitor_DELETE
    puid 'INXT_SAM_ABAAAAAAAB'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample_completed_unclean_DELETE do
    name 'Sample Completed Unclean'
    description 'Sample Completed Unclean description.'
    project :project_janitor_DELETE
    puid 'INXT_SAM_ABAAAAAAAD'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample_error_unclean_DELETE do
    name 'Sample Error Unclean'
    description 'Sample Error Unclean description.'
    project :project_janitor_DELETE
    puid 'INXT_SAM_ABAAAAAAAE'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample_canceled_unclean_DELETE do
    name 'Sample Canceled Unclean'
    description 'Sample Canceled Unclean description.'
    project :project_janitor_DELETE
    puid 'INXT_SAM_ABAAAAAAAF'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  (1..200).each do |n|
    sample(:"bulk_sample#{n}") do
      name "Project 38 Sample #{n}"
      description "Project 38 Sample #{n} description."
      project :project38
      puid "INXT_SAM_AAAAAAAAC#{n}"
      created_at "<%= #{n}.weeks.ago %>"
      updated_at "<%= #{n}.days.ago %>"
    end
  end

  sample :sample47 do
    name 'Sample 47'
    description 'Sample 47 description.'
    project :project22
    puid 'INXT_SAM_AAAAAAAABW'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample48 do
    name 'Sample 48'
    description 'Sample 48 description.'
    project :project22
    puid 'INXT_SAM_AAAAAAAABX'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample49 do
    name 'Sample 49'
    description 'Sample 49 description.'
    project :projectIndia
    puid 'INXT_SAM_AAAAAAAABY'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample50 do
    name 'Sample 50'
    description 'Sample 50 description.'
    project :projectIndia
    puid 'INXT_SAM_AAAAAAAABZ'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample51 do
    name 'Sample 51'
    description 'Sample 51 description.'
    project :projectIndia1
    puid 'INXT_SAM_AAAAAAAADA'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample52 do
    name 'Sample 52'
    description 'Sample 52 description.'
    project :projectJuliett
    puid 'INXT_SAM_AAAAAAAADB'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample53 do
    name 'Sample 53'
    description 'Sample 53 description.'
    project :projectJuliett
    puid 'INXT_SAM_AAAAAAAADC'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample54 do
    name 'Sample 54'
    description 'Sample 54 description.'
    project :projectJuliett1
    puid 'INXT_SAM_AAAAAAAADD'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample55 do
    name 'Sample 55'
    description 'Sample 55 description.'
    project :projectMike
    puid 'INXT_SAM_AAAAAAAADE'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample56 do
    name 'Sample 56'
    description 'Sample 56 description.'
    project :projectMike
    puid 'INXT_SAM_AAAAAAAADF'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample57 do
    name 'Sample 57'
    description 'Sample 57 description.'
    project :projectMikeA
    puid 'INXT_SAM_AAAAAAAADG'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample58 do
    name 'Sample 58'
    description 'Sample 58 description.'
    project :projectMikeA
    puid 'INXT_SAM_AAAAAAAADH'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample59 do
    name 'Sample 59'
    description 'Sample 59 description.'
    project :projectMikeB
    puid 'INXT_SAM_AAAAAAAADI'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample60 do
    name 'Sample 60'
    description 'Sample 60 description.'
    project :projectMikeB
    puid 'INXT_SAM_AAAAAAAADJ'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :sample61 do
    name 'Sample 61'
    description 'Sample 61 description.'
    project :projectMetadata
    puid 'INXT_SAM_AAAAAAAADK'
    metadata({ 'example_date' => '2023-10-17', 'example_float' => '0.01', 'example_integer' => '1' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample62 do
    name 'Sample 62'
    description 'Sample 62 description.'
    project :projectMetadata
    puid 'INXT_SAM_AAAAAAAADL'
    metadata({ 'example_date' => '2023-11-17', 'example_float' => '0.25', 'example_integer' => '25' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample63 do
    name 'Sample 63'
    description 'Sample 63 description.'
    project :projectMetadata
    puid 'INXT_SAM_AAAAAAAADM'
    metadata({ 'example_date' => '2023-12-17', 'example_float' => '0.99', 'example_integer' => '100' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample64 do
    name 'Sample 64'
    description 'Sample 64 description.'
    project :projectMetadata2
    puid 'INXT_SAM_AAAAAAAADN'
    metadata({ 'example_date' => '2023-10-17', 'example_float' => '0.01', 'example_integer' => '1' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample65 do
    name 'Sample 65'
    description 'Sample 65 description.'
    project :projectMetadata2
    puid 'INXT_SAM_AAAAAAAADO'
    metadata({ 'example_date' => '2023-11-17', 'example_float' => '0.25', 'example_integer' => '25' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :sample66 do
    name 'Sample 66'
    description 'Sample 66 description.'
    project :projectMetadata2
    puid 'INXT_SAM_AAAAAAAADP'
    metadata({ 'example_date' => '2023-12-17', 'example_float' => '0.99', 'example_integer' => '100' })
    metadata_provenance({
                          'example_date' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_float' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          },
                          'example_integer' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :metadata_doe),
                            'source' => 'user',
                            'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>'
                          }
                        })
  end

  sample :group_sample_transfer_sample1 do
    name 'Group Sample Transfer 1'
    description 'Group Sample Transfer 1 description.'
    project :projectGroupSampleTransfer
    puid 'INXT_SAM_AAAAAAAADQ'
  end

  sample :group_sample_transfer_sample2 do
    name 'Group Sample Transfer 2'
    description 'Group Sample Transfer 2 description.'
    project :projectGroupSampleTransfer
    puid 'INXT_SAM_AAAAAAAADR'
  end

  sample :group_sample_transfer_sample3 do
    name 'Group Sample Transfer 3'
    description 'Group Sample Transfer 3 description.'
    project :projectGroupSampleTransfer
    puid 'INXT_SAM_AAAAAAAADS'
  end

  sample :sample67 do
    name 'Sample 67'
    description 'Sample 67 description.'
    project :projectGroupSampleActions
    puid 'INXT_SAM_AAAAAAAADT'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample68 do
    name 'Sample 68'
    description 'Sample 68 description.'
    project :projectSubGroupSampleActions
    puid 'INXT_SAM_AAAAAAAADU'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample69 do
    name 'Sample 69'
    description 'Sample 69 description.'
    project :projectSharedGroupSampleActionsOwner
    puid 'INXT_SAM_AAAAAAAADV'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample70 do
    name 'Sample 70'
    description 'Sample 70 description.'
    project :projectSharedGroupSampleActionsMaintainer
    puid 'INXT_SAM_AAAAAAAADW'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample71 do
    name 'Sample 71'
    description 'Sample 71 description.'
    project :projectSharedGroupSampleActionsAnalyst
    puid 'INXT_SAM_AAAAAAAADX'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample72 do
    name 'Sample 72'
    description 'Sample 72 description.'
    project :projectSharedGroupSampleActionsGuest
    puid 'INXT_SAM_AAAAAAAADY'
    metadata({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' })
    metadata_provenance({
                          'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' },
                          'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                'updated_at' => '<%= Time.local(2000,1,1).utc.as_json %>' }
                        })
  end

  sample :sample73 do
    name 'Sample 1'
    description 'Sample 1description.'
    project :projectUser31
    puid 'INXT_SAM_AAAAAAAAGT'
    created_at '<%= 34.weeks.ago %>'
    updated_at '<%= 34.days.ago %>'
  end

  sample 'sample_preparation_test_1' do
    name 'sample_preparation_test_1'
    description 'sample_preparation_test_1 description.'
    project :projectUser32
    puid 'INXT_SAM_AAAAAAAAZA'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 3.hours.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample 'sample_preparation_test_2' do
    name 'sample_preparation_test_2'
    description 'sample_preparation_test_2 description.'
    project :projectUser32
    puid 'INXT_SAM_AAAAAAAAZB'
    created_at '<%= 2.week.ago %>'
    updated_at '<%= 3.hours.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample 'sample_preparation_test_3' do
    name 'sample_preparation_test_3'
    description 'sample_preparation_test_3 description.'
    project :projectUser32
    puid 'INXT_SAM_AAAAAAAAZC'
    created_at '<%= 3.week.ago %>'
    updated_at '<%= 3.hours.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
  end

  sample :snvphyl_sample1 do
    name 'SNVPhyl Sample 1'
    description 'SNVPhyl Sample 1 description.'
    project :snvphyl_project
    puid 'INXT_SAM_AAAAAAAAEA'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
    metadata({
               'metadata_1' => '1.1',
               'metadata_2' => '2.1',
               'metadata_3' => '3.1',
               'metadata_4' => '4.1',
               'metadata_5' => '5.1',
               'metadata_6' => '6.1',
               'metadata_7' => '7.1',
               'metadata_8' => '8.1'
             })
    metadata_provenance({
                          'metadata_1' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_2' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_3' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_4' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_5' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_6' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_7' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_8' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          }
                        })
  end

  sample :snvphyl_sample2 do
    name 'SNVPhyl Sample 2'
    description 'SNVPhyl Sample 2 description.'
    project :snvphyl_project
    puid 'INXT_SAM_AAAAAAAAEB'
    created_at '<%= 1.week.ago %>'
    updated_at '<%= 1.day.ago %>'
    attachments_updated_at '<%= 2.hours.ago %>'
    metadata({
               'metadata_1' => '1.1',
               'metadata_2' => '2.2',
               'metadata_3' => '3.2',
               'metadata_4' => '4.2',
               'metadata_5' => '5.2',
               'metadata_6' => '6.2',
               'metadata_7' => '7.1',
               'metadata_8' => '8.2'
             })
    metadata_provenance({
                          'metadata_1' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_2' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_3' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_4' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_5' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_6' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_7' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          },
                          'metadata_8' => {
                            'id' => FixtureBot::Key::Uuid.generate(:users, :snvphyl_user),
                            'source' => 'user',
                            'updated_at' => '<%= 1.day.ago.to_datetime.as_json %>'
                          }
                        })
  end
end
