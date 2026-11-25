# frozen_string_literal: true

FixtureBot.define do
  attachment :attachment1 do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    puid 'INXT_ATT_AAAAAAAAAA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :attachment2 do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample1, :uuid)
    puid 'INXT_ATT_AAAAAAAAAB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachment3 do
    metadata({
               'compression' => 'none',
               'format' => 'fasta'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample3, :uuid)
    puid 'INXT_ATT_BAAAAAAAAB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentA do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleA, :uuid)
    puid 'INXT_ATT_AAAAAAAAAC'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment :attachmentB do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleA, :uuid)
    puid 'INXT_ATT_AAAAAAAAAD'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :attachmentC do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleA, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV1, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD1, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV2, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD2, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV3, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD3, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV4, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAI'
  end

  attachment :attachmentPEREV4 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD4, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAI'
  end

  attachment :attachmentPEFWD5 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV5, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAJ'
  end

  attachment :attachmentPEREV5 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD5, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAJ'
  end

  attachment :attachmentE do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
    puid 'INXT_ATT_AAAAAAAAAL'
    created_at '<%= 2.hour.ago %>'
    updated_at '<%= 2.hour.ago %>'
  end

  attachment :attachmentF do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
    puid 'INXT_ATT_AAAAAAAAAM'
    created_at '<%= 1.hour.ago %>'
    updated_at '<%= 1.hour.ago %>'
  end

  attachment :attachmentD do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleB, :uuid)
    puid 'INXT_ATT_AAAAAAAAAK'
    created_at '<%= 3.hour.ago %>'
    updated_at '<%= 3.hour.ago %>'
  end

  attachment :attachmentG do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAN'
  end

  attachment :attachmentH do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAO'
  end

  attachment :attachmentPEFWD6 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV6, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAP'
  end

  attachment :attachmentPEREV6 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD6, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAP'
  end

  attachment :attachmentPEFWD7 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV7, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAQ'
  end

  attachment :attachmentPEREV7 do
    metadata({
               'type' => 'illumina_pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD7, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAQ'
  end

  attachment :attachmentI do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAR'
  end

  attachment :attachmentJ do
    metadata({
               'compression' => 'gzip',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleC, :uuid)
    puid 'INXT_ATT_AAAAAAAAAS'
  end

  attachment :workflow_execution_completed_output_attachment do
    metadata({
               'compression' => 'gzip',
               'format' => 'text'
             })
    attachable_type 'WorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:irida_next_example_completed_with_output, :uuid)
    puid 'INXT_ATT_AAAAAAAAAT'
  end

  attachment :samples_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'none'
             })
    attachable_type 'SamplesWorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:sample46_irida_next_example_completed_with_output, :uuid)
    puid 'INXT_ATT_AAAAAAAAAU'
  end

  attachment :samples_shared_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'SamplesWorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:sample47_workflow_execution_completed_shared2, :uuid)
    puid 'INXT_ATT_AAAAAAAAAV'
  end

  attachment :samples_group_shared_workflow_execution_completed_output_attachment do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'SamplesWorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:sample47_workflow_execution_completed_group_shared2, :uuid)
    puid 'INXT_ATT_AAAAAAAAAW'
  end

  attachment :attachmentEndToEndFWD do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentEndToEndREV, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleEndToEnd, :uuid)
    puid 'INXT_ATT_ABAAAAAAAA'
  end

  attachment :attachmentEndToEndREV do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentEndToEndFWD, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleEndToEnd, :uuid)
    puid 'INXT_ATT_ABAAAAAAAB'
  end

  attachment :attachmentDELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sampleDELETE, :uuid)
    puid 'INXT_ATT_ABAAAAAAAC'
  end

  attachment :attachment_completed_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample_completed_unclean_DELETE, :uuid)
    puid 'INXT_ATT_ABAAAAAAAD'
  end

  attachment :attachment_error_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample_error_unclean_DELETE, :uuid)
    puid 'INXT_ATT_ABAAAAAAAE'
  end

  attachment :attachment_canceled_unclean_DELETE do
    metadata({
               'format' => 'fastq',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample_canceled_unclean_DELETE, :uuid)
    puid 'INXT_ATT_ABAAAAAAAF'
  end

  attachment :attachmentPEREV43 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEFWD43, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample43, :uuid)
    puid 'INXT_ATT_AXDGAAAAAF'
  end

  attachment :attachmentPEFWD43 do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:attachmentPEREV43, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample43, :uuid)
    puid 'INXT_ATT_AXDGAAAAAF'
  end

  attachment :sample22AttachmentFastqFWD do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:sample22AttachmentFastqREV, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample22, :uuid)
    puid 'INXT_ATT_ABAAAAAAAG'
  end

  attachment :sample22AttachmentFastqREV do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'none',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:sample22AttachmentFastqFWD, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample22, :uuid)
    puid 'INXT_ATT_ABAAAAAAAG'
  end

  attachment :sample22AttachmentFasta do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample22, :uuid)
    puid 'INXT_ATT_ABAAAAAAAH'
  end

  attachment :sample22AttachmentText do
    metadata({
               'format' => 'text',
               'compression' => 'none'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample22, :uuid)
    puid 'INXT_ATT_ABAAAAAAAI'
  end

  attachment :project1Attachment1 do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Namespace'
    attachable_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
    puid 'INXT_ATT_ABAAAAAAAK'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :group1Attachment1 do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Namespace'
    attachable_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
    puid 'INXT_ATT_ABAAAAAAAM'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :gasclusteringAttachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample32, :uuid)
    puid 'INXT_ATT_ABAAAAAAAN'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :sample32JsonAttachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:sample32, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:project2_namespace, :uuid)
    puid 'INXT_ATT_ABAAAAAABF'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment :workflow_execution_group_shared_output_attachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable_type 'WorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:workflow_execution_group_shared1, :uuid)
    puid 'INXT_ATT_ABAAAAAABG'
  end

  attachment :workflow_execution_shared_with_project_output_attachment do
    metadata({
               'compression' => 'none',
               'format' => 'json'
             })
    attachable_type 'WorkflowExecution'
    attachable_id ActiveRecord::FixtureSet.identify(:workflow_execution_shared2, :uuid)
    puid 'INXT_ATT_ABAAAAAABH'
  end

  attachment 'sample_preparation_test_attachment_1' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_1', :uuid)
    puid 'INXT_ATT_AAAAAAAAZA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_1B' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_1', :uuid)
    puid 'INXT_ATT_AAAAAAAZZA'
    created_at '<%= 3.hours.ago %>'
    updated_at '<%= 3.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_2' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_2', :uuid)
    puid 'INXT_ATT_AAAAAAAAZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_2B' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_2', :uuid)
    puid 'INXT_ATT_AAAAAAAZZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_3' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_3', :uuid)
    puid 'INXT_ATT_BAAAAAAAZB'
    created_at '<%= 2.hours.ago %>'
    updated_at '<%= 2.hours.ago %>'
  end

  attachment 'sample_preparation_test_attachment_3B' do
    metadata({
               'compression' => 'none',
               'format' => 'fastq'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify('sample_preparation_test_3', :uuid)
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
    attachable_id ActiveRecord::FixtureSet.identify(:group_sixteen, :uuid)
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
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:snvphyl_sample1_attachment_rev, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1, :uuid)
    puid 'INXT_ATT_ABAAAAAABJ'
  end

  attachment :snvphyl_sample1_attachment_rev do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'gzip',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:snvphyl_sample1_attachment_fwd, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1, :uuid)
    puid 'INXT_ATT_ABAAAAAABK'
  end

  attachment :snvphyl_sample1_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1, :uuid)
    puid 'INXT_ATT_ABAAAAAABL'
  end

  attachment :snvphyl_sample2_attachment_fwd do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'forward',
               'compression' => 'gzip',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:snvphyl_sample2_attachment_rev, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_sample2, :uuid)
    puid 'INXT_ATT_ABAAAAAABM'
  end

  attachment :snvphyl_sample2_attachment_rev do
    metadata({
               'type' => 'pe',
               'format' => 'fastq',
               'direction' => 'reverse',
               'compression' => 'gzip',
               'associated_attachment_id' => ActiveRecord::FixtureSet.identify(:snvphyl_sample2_attachment_fwd, :uuid)
             })
    attachable_type 'Sample'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_sample2, :uuid)
    puid 'INXT_ATT_ABAAAAAABN'
  end

  attachment :snvphyl_project_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'Namespace'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_project_namespace, :uuid)
    puid 'INXT_ATT_ABAAAAAABO'
  end

  attachment :snvphyl_group_attachment_ref do
    metadata({
               'type' => 'assembly',
               'format' => 'fasta',
               'compression' => 'gzip'
             })
    attachable_type 'Namespace'
    attachable_id ActiveRecord::FixtureSet.identify(:snvphyl_group, :uuid)
    puid 'INXT_ATT_ABAAAAAABP'
  end
end
