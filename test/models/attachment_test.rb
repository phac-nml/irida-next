# frozen_string_literal: true

require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  def setup
    @attachment1 = attachments(:attachment1)
    @sample = samples(:sample1)
  end

  test 'valid attachment' do
    assert @attachment1.valid?
  end

  test 'invalid when no file attached' do
    invalid_attachment = @sample.attachments.build
    assert_not invalid_attachment.valid?
    assert invalid_attachment.errors.added?(:file, :blank, validator_type: :attached)
  end

  test 'invalid when file checksum matches another Attachment associated with the Attachable' do
    new_attachment = @sample.attachments.build(
      file: { io: Rails.root.join('test/fixtures/files/test_file_A.fastq').open,
              filename: 'test_file_A.fastq' }
    )
    assert_not new_attachment.valid?
    assert new_attachment.errors.added?(:file, :checksum_uniqueness)
  end

  test 'file checksum matches another Attachment associated with the Attachable but with different filename' do
    assert_equal 2, @sample.attachments.count
    new_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_A.fastq').open,
        filename: 'copy_of_test_file_A.fastq' })
    assert new_attachment.valid?
    @sample.save
    assert_equal 3, @sample.attachments.count
  end

  test 'file checksum differs from another Attachment associated with the Attachable but with same filename' do
    new_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_C.fastq').open,
        filename: 'test_file_A.fastq' })
    assert new_attachment.valid?
    @sample.save
    assert_equal 3, @sample.attachments.count
  end

  test 'metadata fastq file types' do
    new_fastq_attachment_ext_fastq =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_1.fastq').open,
                                        filename: 'test_file_1.fastq' })
    new_fastq_attachment_ext_fastq.save
    assert_equal 'fastq', new_fastq_attachment_ext_fastq.metadata['format']

    new_fastq_attachment_ext_fastq_gz =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_2.fastq.gz').open,
                                        filename: 'test_file_2.fastq.gz' })
    new_fastq_attachment_ext_fastq_gz.save
    assert_equal 'fastq', new_fastq_attachment_ext_fastq_gz.metadata['format']

    new_fastq_attachment_ext_fq =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_3.fq').open,
                                        filename: 'test_file_3.fq' })
    new_fastq_attachment_ext_fq.save
    assert_equal 'fastq', new_fastq_attachment_ext_fq.metadata['format']

    new_fastq_attachment_ext_fq_gz =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_4.fq.gz').open,
                                        filename: 'test_file_4.fq.gz' })
    new_fastq_attachment_ext_fq_gz.save
    assert_equal 'fastq', new_fastq_attachment_ext_fq_gz.metadata['format']
  end

  test 'metadata fasta file types' do
    new_fasta_attachment_ext_fasta =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_5.fasta').open,
                                        filename: 'test_file_5.fasta' })
    new_fasta_attachment_ext_fasta.save
    assert_equal 'fasta', new_fasta_attachment_ext_fasta.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fasta.metadata['type']
    assert new_fasta_attachment_ext_fasta.fasta?

    new_fasta_attachment_ext_fasta_gz =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_6.fasta.gz').open,
                                        filename: 'test_file_6.fasta.gz' })
    new_fasta_attachment_ext_fasta_gz.save
    assert_equal 'fasta', new_fasta_attachment_ext_fasta_gz.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fasta_gz.metadata['type']
    assert new_fasta_attachment_ext_fasta_gz.fasta?

    new_fasta_attachment_ext_fa =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_7.fa').open,
                                        filename: 'test_file_7.fa' })
    new_fasta_attachment_ext_fa.save
    assert_equal 'fasta', new_fasta_attachment_ext_fa.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fa.metadata['type']
    assert new_fasta_attachment_ext_fa.fasta?

    new_fasta_attachment_ext_fa_gz =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_8.fa.gz').open,
                                        filename: 'test_file_8.fa.gz' })
    new_fasta_attachment_ext_fa_gz.save
    assert_equal 'fasta', new_fasta_attachment_ext_fa_gz.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fa_gz.metadata['type']
    assert new_fasta_attachment_ext_fa_gz.fasta?

    new_fasta_attachment_ext_fna =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_9.fna').open,
                                        filename: 'test_file_9.fna' })
    new_fasta_attachment_ext_fna.save
    assert_equal 'fasta', new_fasta_attachment_ext_fna.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fna.metadata['type']
    assert new_fasta_attachment_ext_fna.fasta?

    new_fasta_attachment_ext_fna_gz =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_10.fna.gz').open,
                                        filename: 'test_file_10.fna.gz' })
    new_fasta_attachment_ext_fna_gz.save
    assert_equal 'fasta', new_fasta_attachment_ext_fna_gz.metadata['format']
    assert_equal 'assembly', new_fasta_attachment_ext_fna_gz.metadata['type']
    assert new_fasta_attachment_ext_fna_gz.fasta?
  end

  test 'metadata text file types' do
    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_14.txt').open,
                                        filename: 'test_file_14.txt' })
    new_text_attachment_ext_txt.save
    assert_equal 'text', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_rtf =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_13.rtf').open,
                                        filename: 'test_file_13.rtf' })
    new_text_attachment_ext_rtf.save
    assert_equal 'text', new_text_attachment_ext_rtf.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_15.txt.gz').open,
                                        filename: 'test_file_15.txt.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'text', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_16.rtf.gz').open,
                                        filename: 'test_file_16.rtf.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'text', new_text_attachment_ext_txt.metadata['format']
  end

  test 'metadata csv file types' do
    new_text_attachment_ext_csv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.csv').open,
                                        filename: 'valid.csv' })
    new_text_attachment_ext_csv.save
    assert_equal 'csv', new_text_attachment_ext_csv.metadata['format']

    new_text_attachment_ext_csv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.csv.gz').open,
                                        filename: 'valid.csv.gz' })
    new_text_attachment_ext_csv.save
    assert_equal 'csv', new_text_attachment_ext_csv.metadata['format']
  end

  test 'metadata tsv file types' do
    new_text_attachment_ext_tsv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.tsv').open,
                                        filename: 'valid.tsv' })
    new_text_attachment_ext_tsv.save
    assert_equal 'tsv', new_text_attachment_ext_tsv.metadata['format']

    new_text_attachment_ext_tsv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.tsv.gz').open,
                                        filename: 'valid.tsv.gz' })
    new_text_attachment_ext_tsv.save
    assert_equal 'tsv', new_text_attachment_ext_tsv.metadata['format']
  end

  test 'metadata spreadsheet file types' do
    new_spreadsheet_attachment_ext_xls =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.xls').open,
                                        filename: 'valid.xls' })
    new_spreadsheet_attachment_ext_xls.save
    assert_equal 'spreadsheet', new_spreadsheet_attachment_ext_xls.metadata['format']

    new_spreadsheet_attachment_ext_xlsx =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.xlsx').open,
                                        filename: 'valid.xlsx' })
    new_spreadsheet_attachment_ext_xlsx.save
    assert_equal 'spreadsheet', new_spreadsheet_attachment_ext_xlsx.metadata['format']
  end

  test 'metadata json file types' do
    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_17.json').open,
                                        filename: 'test_file_17.json' })
    new_text_attachment_ext_txt.save
    assert_equal 'json', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_18.json.gz').open,
                                        filename: 'test_file_18.json.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'json', new_text_attachment_ext_txt.metadata['format']
  end

  test 'metadata genbank file types' do
    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.gbk').open,
                                        filename: 'sequence.gbk' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.gbk.gz').open,
                                        filename: 'sequence.gbk.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.gbf').open,
                                        filename: 'sequence.gbf' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.gbf.gz').open,
                                        filename: 'sequence.gbf.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.genbank').open,
                                        filename: 'sequence.genbank' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']

    new_text_attachment_ext_txt =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/sequence.genbank.gz').open,
                                        filename: 'sequence.genbank.gz' })
    new_text_attachment_ext_txt.save
    assert_equal 'genbank', new_text_attachment_ext_txt.metadata['format']
  end

  test 'metadata unknown file types' do
    new_unknown_attachment_ext_docx =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_11.docx').open,
                                        filename: 'test_file_11.docx' })
    new_unknown_attachment_ext_docx.save
    assert_equal 'unknown', new_unknown_attachment_ext_docx.metadata['format']

    new_unknown_attachment_ext_pdf =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file_12.pdf').open,
                                        filename: 'test_file_12.pdf' })
    new_unknown_attachment_ext_pdf.save
    assert_equal 'unknown', new_unknown_attachment_ext_pdf.metadata['format']
  end

  test '#destroy does not destroy the ActiveStorage::Attachment' do
    assert_no_difference('ActiveStorage::Attachment.count') do
      @attachment1.destroy
    end
  end

  test '#destroy is a soft deletion and sets deleted_at' do
    assert_nil @attachment1.deleted_at
    @attachment1.destroy
    assert_not_nil @attachment1.deleted_at
  end

  test 'fastq?' do
    unknown_attachment = attachments(:workflow_execution_completed_output_attachment)
    assert @attachment1.fastq?
    assert_not unknown_attachment.fastq?
  end

  test 'associated_attachment' do
    attachment_fwd = attachments(:attachmentPEFWD1)
    attachment_rev = attachments(:attachmentPEREV1)

    assert_equal attachment_rev, attachment_fwd.associated_attachment
    assert_nil @attachment1.associated_attachment
  end

  test 'previewable? returns true for previewable formats' do
    # Test a few sample formats from PREVIEWABLE_TYPES

    # FASTQ file should be previewable
    fastq_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_1.fastq').open,
        filename: 'test_file_1.fastq' })
    fastq_attachment.save
    assert fastq_attachment.previewable?

    # Text file should be previewable
    text_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_14.txt').open,
        filename: 'test_file_14.txt' })
    text_attachment.save
    assert text_attachment.previewable?

    # JSON file should be previewable
    json_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_17.json').open,
        filename: 'test_file_17.json' })
    json_attachment.save
    assert json_attachment.previewable?
  end

  test 'previewable? returns false for non-previewable formats' do
    # PDF should not be previewable (unknown format)
    pdf_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_12.pdf').open,
        filename: 'test_file_12.pdf' })
    pdf_attachment.save
    assert_not pdf_attachment.previewable?

    # DOCX should not be previewable (unknown format)
    docx_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_11.docx').open,
        filename: 'test_file_11.docx' })
    docx_attachment.save
    assert_not docx_attachment.previewable?
  end

  test 'copyable? returns true for copyable formats' do
    # Test a few sample formats from COPYABLE_TYPES

    # FASTQ file should be copyable
    fastq_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_1.fastq').open,
        filename: 'test_file_1.fastq' })
    fastq_attachment.save
    assert fastq_attachment.copyable?

    # Text file should be copyable
    text_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_14.txt').open,
        filename: 'test_file_14.txt' })
    text_attachment.save
    assert text_attachment.copyable?

    # JSON file should be copyable
    json_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_17.json').open,
        filename: 'test_file_17.json' })
    json_attachment.save
    assert json_attachment.copyable?
  end

  test 'copyable? returns false for non-copyable formats' do
    # PDF should not be copyable (not in COPYABLE_TYPES)
    pdf_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/test_file_12.pdf').open,
        filename: 'test_file_12.pdf' })
    pdf_attachment.save
    assert_not pdf_attachment.copyable?

    # Spreadsheet should not be copyable (not in COPYABLE_TYPES)
    spreadsheet_attachment = @sample.attachments.build(file:
      { io: Rails.root.join('test/fixtures/files/metadata/valid.xlsx').open,
        filename: 'valid.xlsx' })
    spreadsheet_attachment.save
    assert_not spreadsheet_attachment.copyable?
  end
end
