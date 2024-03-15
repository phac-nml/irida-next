# frozen_string_literal: true

require 'test_helper'
module DataExports
  class CreateJobTest < ActiveJob::TestCase
    def setup
      @data_export = data_exports(:data_export_two)
    end

    test 'creating export and updating data_export status' do
      assert @data_export.status = 'processing'
      assert_not @data_export.file.valid?

      assert_difference -> { ActiveStorage::Attachment.count } => +1 do
        DataExports::CreateJob.perform_now(@data_export)
      end

      assert_equal 'ready', @data_export.status
      assert @data_export.file.valid?
      assert_equal "#{@data_export.id}.zip", @data_export.file.filename.to_s
    end

    test 'content of export' do
      sample = samples(:sample1)
      project = projects(:project1)
      attachment1 = attachments(:attachment1)
      attachment2 = attachments(:attachment2)
      expected_files_in_zip = ["#{project.puid}/#{sample.puid}/#{attachment1.puid}/#{attachment1.file.filename}",
                               "#{project.puid}/#{sample.puid}/#{attachment2.puid}/#{attachment2.file.filename}",
                               'manifest.json']
      DataExports::CreateJob.perform_now(@data_export)
      export_file = ActiveStorage::Blob.service.path_for(@data_export.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert_not expected_files_in_zip.count.positive?
    end

    test 'content of export including paired files' do
      sample_a = samples(:sampleA)
      sample_b = samples(:sampleB)

      project = projects(:projectA)
      attachment_a = attachments(:attachmentA)
      attachment_b = attachments(:attachmentB)
      attachment_c = attachments(:attachmentC)
      attachment_fwd1 = attachments(:attachmentPEFWD1)
      attachment_rev1 = attachments(:attachmentPEREV1)
      attachment_fwd2 = attachments(:attachmentPEFWD2)
      attachment_rev2 = attachments(:attachmentPEREV2)
      attachment_fwd3 = attachments(:attachmentPEFWD3)
      attachment_rev3 = attachments(:attachmentPEREV3)
      attachment_d = attachments(:attachmentD)
      attachment_e = attachments(:attachmentE)
      attachment_f = attachments(:attachmentF)

      data_export = data_exports(:data_export_three)
      expected_files_in_zip =
        ["#{project.puid}/#{sample_a.puid}/#{attachment_a.puid}/#{attachment_a.file.filename}",
         "#{project.puid}/#{sample_a.puid}/#{attachment_b.puid}/#{attachment_b.file.filename}",
         "#{project.puid}/#{sample_a.puid}/#{attachment_c.puid}/#{attachment_c.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_fwd1.puid}/#{attachment_fwd1.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_rev1.puid}/#{attachment_rev1.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_fwd2.puid}/#{attachment_fwd2.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_rev2.puid}/#{attachment_rev2.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_fwd3.puid}/#{attachment_fwd3.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_rev3.puid}/#{attachment_rev3.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_d.puid}/#{attachment_d.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_e.puid}/#{attachment_e.file.filename}",
         "#{project.puid}/#{sample_b.puid}/#{attachment_f.puid}/#{attachment_f.file.filename}",
         'manifest.json']
      DataExports::CreateJob.perform_now(data_export)
      sleep 1
      export_file = ActiveStorage::Blob.service.path_for(data_export.file.key)
      sleep 1
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert_not expected_files_in_zip.count.positive?
    end

    test 'test export expiry that does not include holiday' do
      assert_nil @data_export.expires_at
      # Monday -> Thursday
      Timecop.travel(DateTime.new(2024, 3, 11)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 3, 14), @data_export.expires_at.to_date
      end
      # Tuesday -> Friday
      Timecop.travel(DateTime.new(2024, 3, 12)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 3, 15), @data_export.expires_at.to_date
      end
      # Wednesday -> Monday
      Timecop.travel(DateTime.new(2024, 3, 13)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 3, 18), @data_export.expires_at.to_date
      end
      # Thursday -> Tuesday
      Timecop.travel(Date.new(2024, 3, 14)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 3, 19), @data_export.expires_at.to_date
      end
      # Friday -> Wednesday
      Timecop.travel(Date.new(2024, 3, 15)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 3, 20), @data_export.expires_at.to_date
      end
    end

    test 'test export expiry that includes holiday' do
      assert_nil @data_export.expires_at
      # New Year's Day
      Timecop.travel(Date.new(2023, 12, 29)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 1, 4), @data_export.expires_at.to_date
      end
      # Good Friday and Easter Monday
      Timecop.travel(DateTime.new(2024, 3, 28)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 4, 4), @data_export.expires_at.to_date
      end
      # Victoria Day
      Timecop.travel(Date.new(2022, 5, 19)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2022, 5, 25), @data_export.expires_at.to_date
      end
      # Canada Day
      Timecop.travel(Date.new(2024, 6, 28)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 7, 4), @data_export.expires_at.to_date
      end
      # Civic Day
      Timecop.travel(Date.new(2019, 8, 2)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2019, 8, 8), @data_export.expires_at.to_date
      end
      # Labour Day
      Timecop.travel(Date.new(2020, 9, 3)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2020, 9, 9), @data_export.expires_at.to_date
      end
      # National Day for Truth and Reconciliation
      Timecop.travel(Date.new(2024, 9, 27)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2024, 10, 3), @data_export.expires_at.to_date
      end
      # Thanksgiving
      Timecop.travel(Date.new(2022, 10, 7)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2022, 10, 13), @data_export.expires_at.to_date
      end
      # In lieu - Remembrance day on weekend
      Timecop.travel(DateTime.new(2023, 11, 9)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2023, 11, 15), @data_export.expires_at.to_date
      end
      # In lieu - Christmas and Boxing Day occuring on Sat and Sun, respectively
      Timecop.travel(DateTime.new(2021, 12, 24)) do
        DataExports::CreateJob.perform_now(@data_export)
        assert_equal Date.new(2021, 12, 31), @data_export.expires_at.to_date
      end
    end
  end
end
