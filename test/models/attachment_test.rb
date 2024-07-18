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
    new_attachment = @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/test_file.fastq').open,
                                                       filename: 'test_file.fastq' })
    assert_not new_attachment.valid?
    assert new_attachment.errors.added?(:file, :checksum_uniqueness)
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

    new_text_attachment_ext_csv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.csv').open,
                                        filename: 'valid.csv' })
    new_text_attachment_ext_csv.save
    assert_equal 'text', new_text_attachment_ext_csv.metadata['format']

    new_text_attachment_ext_tsv =
      @sample.attachments.build(file: { io: Rails.root.join('test/fixtures/files/metadata/valid.tsv').open,
                                        filename: 'valid.tsv' })
    new_text_attachment_ext_tsv.save
    assert_equal 'text', new_text_attachment_ext_tsv.metadata['format']
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
end
