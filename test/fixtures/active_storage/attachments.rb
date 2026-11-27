# frozen_string_literal: true

FixtureBot.define do
  # Every row has `name "file"`, and almost every blob label follows the
  # `"#{row_name}_blob"` convention, so both get a default generator here;
  # the handful of rows whose blob label doesn't follow that convention
  # (e.g. renamed/legacy files) still set `blob_id` explicitly to override it.
  active_storage_attachment.name { 'file' }
  active_storage_attachment.blob_id { |fixture| ActiveRecord::FixtureSet.identify(:"#{fixture.key}_blob", :uuid) }

  # Many `attachments` rows are named after the `Attachment` fixture they point at, with a
  # `_file...` suffix describing the file itself (e.g. `:attachment1_file_test_file_A_fastq`
  # points at `attachment(:attachment1)`), so `record_id`/`record_type` get a default generator
  # here that strips everything from the first `_file` onward. Rows whose `Attachment`/
  # `DataExport` label doesn't follow that convention still call `record` explicitly to
  # override it.
  active_storage_attachment.record_id do |fixture|
    label = fixture.key.to_s.sub(/_file.*\z/, '')
    FixtureBot::Key::Uuid.generate(:attachments, label)
  end
  active_storage_attachment.record_type { 'Attachment' }

  active_storage_attachment :attachment1_file_test_file_A_fastq

  active_storage_attachment :attachment2_file_test_file_B_fastq

  active_storage_attachment :attachment3_file_test_file_5_fasta

  active_storage_attachment :attachmentA_file_test_file_fastq

  active_storage_attachment :attachmentB_file_test_file_fastq

  active_storage_attachment :attachmentC_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD1_file_test_file_fastq

  active_storage_attachment :attachmentPEREV1_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD2_file_test_file_fastq

  active_storage_attachment :attachmentPEREV2_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD3_file_test_file_fastq

  active_storage_attachment :attachmentPEREV3_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD4_file_test_file_fastq

  active_storage_attachment :attachmentPEREV4_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD5_file_test_file_fastq

  active_storage_attachment :attachmentPEREV5_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD6_file_test_file_fastq

  active_storage_attachment :attachmentPEREV6_file_test_file_fastq

  active_storage_attachment :attachmentPEFWD7_file_test_file_fastq

  active_storage_attachment :attachmentPEREV7_file_test_file_fastq

  active_storage_attachment :attachmentD_file_test_file_fastq

  active_storage_attachment :attachmentE_file_test_file_fastq do
    blob_id ActiveRecord::FixtureSet.identify(:attachmentE_gz_file_test_file_fastq_blob, :uuid)
  end

  active_storage_attachment :attachmentF_file_test_file_fastq do
    blob_id ActiveRecord::FixtureSet.identify(:attachmentF_gz_file_test_file_fastq_blob, :uuid)
  end

  active_storage_attachment :attachmentG_file_test_file_fastq

  active_storage_attachment :attachmentH_file_test_file_fastq

  active_storage_attachment :attachmentI_file_test_file_fastq

  active_storage_attachment :attachmentJ_file_test_file_fastq

  active_storage_attachment :data_export_1_test_export do
    record data_export(:data_export_one)
  end

  active_storage_attachment :workflow_execution_completed_output do
    record attachment(:workflow_execution_completed_output_attachment)
  end

  active_storage_attachment :samples_workflow_execution_completed_output do
    record attachment(:samples_workflow_execution_completed_output_attachment)
  end

  active_storage_attachment :samples_shared_workflow_execution_completed_output do
    record attachment(:samples_shared_workflow_execution_completed_output_attachment)
  end

  active_storage_attachment :samples_group_shared_workflow_execution_completed_output do
    record attachment(:samples_group_shared_workflow_execution_completed_output_attachment)
  end

  active_storage_attachment :data_export_7_test_export do
    record data_export(:data_export_seven)
  end

  active_storage_attachment :data_export_8_test_export do
    record data_export(:data_export_eight)
  end

  active_storage_attachment :data_export_9_test_export do
    record data_export(:data_export_nine)
  end

  active_storage_attachment :data_export_11_test_export do
    record data_export(:data_export_eleven)
  end

  active_storage_attachment :data_export_12_test_export do
    record data_export(:data_export_twelve)
  end

  active_storage_attachment :data_export_13_test_export do
    record data_export(:data_export_thirteen)
  end

  active_storage_attachment :attachmentEndToEndFWD_file_test_file_fastq

  active_storage_attachment :attachmentEndToEndREV_file_test_file_fastq

  active_storage_attachment :attachmentSample43_file_test_file_fastq do
    record attachment(:attachmentPEFWD43)
    blob_id ActiveRecord::FixtureSet.identify(:attachment43Sample_file_test_fileA_fastq_blob, :uuid)
  end

  active_storage_attachment :attachmentSample43_file_test_file_A_fastq do
    record attachment(:attachmentPEREV43)
    blob_id ActiveRecord::FixtureSet.identify(:attachment43Sample_file_test_fileB_fastq_blob, :uuid)
  end

  active_storage_attachment :sample22_test_file_fastq_fwd do
    record attachment(:sample22AttachmentFastqFWD)
  end

  active_storage_attachment :sample22_test_file_fastq_rev do
    record attachment(:sample22AttachmentFastqREV)
  end

  active_storage_attachment :sample22_test_file_fasta do
    record attachment(:sample22AttachmentFasta)
  end

  active_storage_attachment :sample22_test_file_text do
    record attachment(:sample22AttachmentText)
  end

  active_storage_attachment :project1_attachment1_file_test_file_fastq do
    record attachment(:project1Attachment1)
  end

  active_storage_attachment :project1_attachment2_file_test_file_A_fastq do
    record attachment(:project1Attachment2)
    blob_id ActiveRecord::FixtureSet.identify(:project1_attachment2_file_data_export_8_csv_blob, :uuid)
  end

  active_storage_attachment :group1_attachment1_file_test_file_fastq do
    record attachment(:group1Attachment1)
  end

  active_storage_attachment :group1_attachment2_file_test_file_A_fastq do
    record attachment(:group1Attachment2)
    blob_id ActiveRecord::FixtureSet.identify(:group1_attachment2_file_data_export_8_csv_blob, :uuid)
  end

  active_storage_attachment :gasclustering_test_file_json do
    record attachment(:gasclusteringAttachment)
  end

  active_storage_attachment :attachment_csv do
    record attachment(:attachmentCSV)
  end

  active_storage_attachment :attachment_text do
    record attachment(:attachmentText)
  end

  active_storage_attachment :attachment_json do
    record attachment(:attachmentJSON)
  end

  active_storage_attachment :attachment_spreadsheet do
    record attachment(:attachmentSpreadsheet)
    blob_id ActiveRecord::FixtureSet.identify(:attachment_spreadsheet, :uuid)
  end

  active_storage_attachment :attachment_image do
    record attachment(:attachmentImage)
    blob_id ActiveRecord::FixtureSet.identify(:attachment_image, :uuid)
  end

  active_storage_attachment :attachment_tsv do
    record attachment(:attachmentTSV)
  end

  active_storage_attachment :workflow_execution_group_shared_output_attachment

  active_storage_attachment :workflow_execution_shared_with_project_output_attachment

  active_storage_attachment :sample32_json_attachment do
    record attachment(:sample32JsonAttachment)
    blob_id ActiveRecord::FixtureSet.identify(:attachment_json_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_1_file_A_fastq do
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_1_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_1_file_B_fastq do
    record attachment('sample_preparation_test_attachment_1B')
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_1B_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_2_file_A_fastq do
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_2_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_2_file_B_fastq do
    record attachment('sample_preparation_test_attachment_2B')
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_2B_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_3_file_A_fastq do
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_3_blob, :uuid)
  end

  active_storage_attachment :sample_preparation_test_attachment_3_file_B_fastq do
    record attachment('sample_preparation_test_attachment_3B')
    blob_id ActiveRecord::FixtureSet.identify(:sample_preparation_test_attachment_3B_blob, :uuid)
  end

  active_storage_attachment :group16_attachment_csv do
    record attachment(:group16AttachmentCSV)
    blob_id ActiveRecord::FixtureSet.identify(:attachment_csv_blob, :uuid)
  end

  active_storage_attachment :snvphyl_sample1_attachment_fwd_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1_attachment_fwd_blob, :uuid)
  end

  active_storage_attachment :snvphyl_sample1_attachment_rev_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1_attachment_rev_blob, :uuid)
  end

  active_storage_attachment :snvphyl_sample1_attachment_ref_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_sample1_attachment_ref_blob, :uuid)
  end

  active_storage_attachment :snvphyl_sample2_attachment_fwd_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_sample2_attachment_fwd_blob, :uuid)
  end

  active_storage_attachment :snvphyl_sample2_attachment_rev_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_sample2_attachment_rev_blob, :uuid)
  end

  active_storage_attachment :snvphyl_project_attachment_ref_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_project_attachment_ref_blob, :uuid)
  end

  active_storage_attachment :snvphyl_group_attachment_ref_file do
    blob_id ActiveRecord::FixtureSet.identify(:snvphyl_group_attachment_ref_blob, :uuid)
  end
end
