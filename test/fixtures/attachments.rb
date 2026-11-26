# frozen_string_literal: true

FixtureBot.define do
  attachment.metadata { { 'compression' => 'none', 'format' => 'fastq' } }

  attachment :attachment1 do
    attachable sample(:sample1)
    puid 'INXT_ATT_AAAAAAAAAA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :attachment2 do
    attachable sample(:sample1)
    puid 'INXT_ATT_AAAAAAAAAB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachment3 do
    metadata({
               'compression' => 'none',
               'format' => 'fasta'
             })
    attachable sample(:sample3)
    puid 'INXT_ATT_BAAAAAAAAB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentA do
    attachable sample(:sampleA)
    puid 'INXT_ATT_AAAAAAAAAC'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :attachmentB do
    attachable sample(:sampleA)
    puid 'INXT_ATT_AAAAAAAAAD'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentC do
    attachable sample(:sampleA)
    puid 'INXT_ATT_AAAAAAAAAE'
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 1.hour.ago %>'
  end

  attachment :attachmentPEFWD1 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV1)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAF'
    created_at '<%= 4.hour.ago %>'
    updated_at '<%= 4.hour.ago %>'
  end

  attachment :attachmentPEREV1 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD1)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAF'
    created_at '<%= 4.hour.ago %>'
    updated_at '<%= 4.hour.ago %>'
  end

  attachment :attachmentPEFWD2 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV2)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAG'
    created_at '<%= 3.hour.ago %>'
    updated_at '<%= 3.hour.ago %>'
  end

  attachment :attachmentPEREV2 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD2)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAG'
    created_at '<%= 3.hour.ago %>'
    updated_at '<%= 3.hour.ago %>'
  end

  attachment :attachmentPEFWD3 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV3)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAH'
    created_at '<%= 2.hour.ago %>'
    updated_at '<%= 2.hour.ago %>'
  end

  attachment :attachmentPEREV3 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD3)
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAH'
    created_at '<%= 2.hour.ago %>'
    updated_at '<%= 2.hour.ago %>'
  end

  attachment :attachmentPEFWD4 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV4)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAI'
    # sampleC has several fastq pairs (4, 5, 6) that share an auto-filled `created_at`;
    # `Attachment.recent` (used to pick the default samplesheet fastq selection) then falls back
    # to an id-based tie-break, which is unstable across fixture regeneration. Stagger them so
    # attachmentPEFWD6 deterministically remains the most recent/default selection.
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentPEREV4 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD4)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAI'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentPEFWD5 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV5)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAJ'
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 1.hour.ago %>'
  end

  attachment :attachmentPEREV5 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD5)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAJ'
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 1.hour.ago %>'
  end

  attachment :attachmentE do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAL'
    created_at '<%= 2.hour.ago %>'
    updated_at '<%= 2.hour.ago %>'
  end

  attachment :attachmentF do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAM'
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 1.hour.ago %>'
  end

  attachment :attachmentD do
    attachable sample(:sampleB)
    puid 'INXT_ATT_AAAAAAAAAK'
    created_at '<%= 3.hour.ago %>'
    updated_at '<%= 3.hour.ago %>'
  end

  attachment :attachmentG do
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAN'
  end

  attachment :attachmentH do
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAO'
  end

  attachment :attachmentPEFWD6 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV6)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAP'
  end

  attachment :attachmentPEREV6 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD6)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAP'
  end

  attachment :attachmentPEFWD7 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV7)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAQ'
    # see attachmentPEFWD4/5 comment: stagger sampleC's fastq pairs so attachmentPEFWD6 remains
    # the deterministic default samplesheet fastq selection
    created_at '<%= 30.minutes.ago %>'
    updated_at '<%= 30.minutes.ago %>'
  end

  attachment :attachmentPEREV7 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD7)
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAQ'
    created_at '<%= 30.minutes.ago %>'
    updated_at '<%= 30.minutes.ago %>'
  end

  attachment :attachmentI do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAR'
  end

  attachment :attachmentJ do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable sample(:sampleC)
    puid 'INXT_ATT_AAAAAAAAAS'
  end

  attachment :workflow_execution_completed_output_attachment do
    metadata({
               'compression' => 'gzip',
               'format' => 'text'
             })
    attachable workflow_execution(:irida_next_example_completed_with_output)
    puid 'INXT_ATT_AAAAAAAAAT'
  end

  attachment :samples_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'none'
             })
    attachable samples_workflow_execution(:sample46_irida_next_example_completed_with_output)
    puid 'INXT_ATT_AAAAAAAAAU'
  end

  attachment :samples_shared_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable samples_workflow_execution(:sample47_workflow_execution_completed_shared2)
    puid 'INXT_ATT_AAAAAAAAAV'
  end

  attachment :samples_group_shared_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable samples_workflow_execution(:sample47_workflow_execution_completed_group_shared2)
    puid 'INXT_ATT_AAAAAAAAAW'
  end

  attachment :attachmentEndToEndFWD do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentEndToEndREV)
             })
    attachable sample(:sampleEndToEnd)
    puid 'INXT_ATT_ABAAAAAAAA'
  end

  attachment :attachmentEndToEndREV do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentEndToEndFWD)
             })
    attachable sample(:sampleEndToEnd)
    puid 'INXT_ATT_ABAAAAAAAB'
  end

  attachment :attachmentDELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable sample(:sampleDELETE)
    puid 'INXT_ATT_ABAAAAAAAC'
  end

  attachment :attachment_completed_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable sample(:sample_completed_unclean_DELETE)
    puid 'INXT_ATT_ABAAAAAAAD'
  end

  attachment :attachment_error_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable sample(:sample_error_unclean_DELETE)
    puid 'INXT_ATT_ABAAAAAAAE'
  end

  attachment :attachment_canceled_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable sample(:sample_canceled_unclean_DELETE)
    puid 'INXT_ATT_ABAAAAAAAF'
  end

  attachment :attachmentPEREV43 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEFWD43)
             })
    attachable sample(:sample43)
    puid 'INXT_ATT_AXDGAAAAAF'
  end

  attachment :attachmentPEFWD43 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :attachmentPEREV43)
             })
    attachable sample(:sample43)
    puid 'INXT_ATT_AXDGAAAAAF'
  end

  attachment :sample22AttachmentFastqFWD do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :sample22AttachmentFastqREV)
             })
    attachable sample(:sample22)
    puid 'INXT_ATT_ABAAAAAAAG'
  end

  attachment :sample22AttachmentFastqREV do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments, :sample22AttachmentFastqFWD)
             })
    attachable sample(:sample22)
    puid 'INXT_ATT_ABAAAAAAAG'
  end

  attachment :sample22AttachmentFasta do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'none'
             })
    attachable sample(:sample22)
    puid 'INXT_ATT_ABAAAAAAAH'
  end

  attachment :sample22AttachmentText do
    metadata({
               'format' => 'text',
               'compression' => 'none'
             })
    attachable sample(:sample22)
    puid 'INXT_ATT_ABAAAAAAAI'
  end

  attachment :project1Attachment1 do
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    puid 'INXT_ATT_ABAAAAAAAJ'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :project1Attachment2 do
    metadata({
               'compression' => 'none',
               'format' => 'csv'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
    puid 'INXT_ATT_ABAAAAAAAK'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :group1Attachment1 do
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    puid 'INXT_ATT_ABAAAAAAAL'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :group1Attachment2 do
    metadata({
               'compression' => 'none',
               'format' => 'csv'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
    puid 'INXT_ATT_ABAAAAAAAM'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :gasclusteringAttachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable sample(:sample32)
    puid 'INXT_ATT_ABAAAAAAAN'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :sample32JsonAttachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable sample(:sample32)
    puid 'INXT_ATT_ABAAAAAAAO'
    created_at '<%= 1.hours.ago %>'
    updated_at '<%= 1.hours.ago %>'
  end

  attachment :attachmentCSV do
    metadata({
               'compression' => 'none',
               'format' => 'csv'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABA'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentText do
    metadata({
               'compression' => 'none',
               'format' => 'text'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentJSON do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABC'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentSpreadsheet do
    metadata({
               'compression' => 'none',
               'format' => 'spreadsheet'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABD'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentImage do
    metadata({
               'compression' => 'none',
               'format' => 'image'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABE'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentTSV do
    metadata({
               'compression' => 'none',
               'format' => 'tsv'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project2_namespace)
    puid 'INXT_ATT_ABAAAAAABF'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :workflow_execution_group_shared_output_attachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable workflow_execution(:workflow_execution_group_shared1)
    puid 'INXT_ATT_ABAAAAAABG'
  end

  attachment :workflow_execution_shared_with_project_output_attachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable workflow_execution(:workflow_execution_shared2)
    puid 'INXT_ATT_ABAAAAAABH'
  end

  attachment 'sample_preparation_test_attachment_1' do
    attachable sample('sample_preparation_test_1')
    puid 'INXT_ATT_AAAAAAAAZA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_1B' do
    attachable sample('sample_preparation_test_1')
    puid 'INXT_ATT_AAAAAAAZZA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_2' do
    attachable sample('sample_preparation_test_2')
    puid 'INXT_ATT_AAAAAAAAZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_2B' do
    attachable sample('sample_preparation_test_2')
    puid 'INXT_ATT_AAAAAAAZZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_3' do
    attachable sample('sample_preparation_test_3')
    puid 'INXT_ATT_BAAAAAAAZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_3B' do
    attachable sample('sample_preparation_test_3')
    puid 'INXT_ATT_BAAAAAAZZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :group16AttachmentCSV do
    metadata({
               'compression' => 'none',
               'format' => 'csv'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:groups, :group_sixteen)
    puid 'INXT_ATT_ABAAAAAABI'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :snvphyl_sample1_attachment_fwd do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'gzip',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments,
                                                                            :snvphyl_sample1_attachment_rev)
             })
    attachable sample(:snvphyl_sample1)
    puid 'INXT_ATT_ABAAAAAABJ'
  end

  attachment :snvphyl_sample1_attachment_rev do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'gzip',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments,
                                                                            :snvphyl_sample1_attachment_fwd)
             })
    attachable sample(:snvphyl_sample1)
    puid 'INXT_ATT_ABAAAAAABK'
  end

  attachment :snvphyl_sample1_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable sample(:snvphyl_sample1)
    puid 'INXT_ATT_ABAAAAAABL'
  end

  attachment :snvphyl_sample2_attachment_fwd do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'gzip',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments,
                                                                            :snvphyl_sample2_attachment_rev)
             })
    attachable sample(:snvphyl_sample2)
    puid 'INXT_ATT_ABAAAAAABM'
  end

  attachment :snvphyl_sample2_attachment_rev do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'gzip',
               'associated_attachment_id' => FixtureBot::Key::Uuid.generate(:attachments,
                                                                            :snvphyl_sample2_attachment_fwd)
             })
    attachable sample(:snvphyl_sample2)
    puid 'INXT_ATT_ABAAAAAABN'
  end

  attachment :snvphyl_project_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :snvphyl_project_namespace)
    puid 'INXT_ATT_ABAAAAAABO'
  end

  attachment :snvphyl_group_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'Namespace'
    attachable_id FixtureBot::Key::Uuid.generate(:groups, :snvphyl_group)
    puid 'INXT_ATT_ABAAAAAABP'
  end
end
