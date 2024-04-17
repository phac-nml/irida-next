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
      expected_manifest = {
        'type' => 'Samples Export',
        'date' => Date.current.strftime('%Y-%m-%d'),
        'children' =>
        [{
          'name' => project.puid,
          'type' => 'folder',
          'irida-next-type' => 'project',
          'irida-next-name' => 'Project 1',
          'children' =>
          [{
            'name' => sample.puid,
            'type' => 'folder',
            'irida-next-type' => 'sample',
            'irida-next-name' => 'Project 1 Sample 1',
            'children' =>
            [{
              'name' => attachment1.puid,
              'type' => 'folder',
              'irida-next-type' => 'attachment',
              'children' =>
              [{
                'name' => 'test_file.fastq',
                'type' => 'file',
                'metadata' => { 'format' => 'fastq' }
              }]
            },
             {
               'name' => attachment2.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' => [{
                 'name' => 'test_file_A.fastq',
                 'type' => 'file',
                 'metadata' => { 'format' => 'fastq' }
               }]
             }]
          }]
        }]
      }

      assert_equal expected_manifest.to_json, @data_export.manifest
    end

    test 'content of export including paired files' do
      sample_b = samples(:sampleB)

      project = projects(:projectA)
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
        [
          "#{project.puid}/#{sample_b.puid}/#{attachment_fwd1.puid}/#{attachment_fwd1.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_rev1.puid}/#{attachment_rev1.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_fwd2.puid}/#{attachment_fwd2.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_rev2.puid}/#{attachment_rev2.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_fwd3.puid}/#{attachment_fwd3.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_rev3.puid}/#{attachment_rev3.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_d.puid}/#{attachment_d.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_e.puid}/#{attachment_e.file.filename}",
          "#{project.puid}/#{sample_b.puid}/#{attachment_f.puid}/#{attachment_f.file.filename}",
          'manifest.json'
        ]

      expected_manifest = {
        'type' => 'Samples Export',
        'date' => Date.current.strftime('%Y-%m-%d'),
        'children' =>
        [{
          'name' => project.puid,
          'type' => 'folder',
          'irida-next-type' => 'project',
          'irida-next-name' => 'Project A',
          'children' =>
          [{
            'name' => sample_b.puid,
            'type' => 'folder',
            'irida-next-type' => 'sample',
            'irida-next-name' => 'Project A Sample B',
            'children' =>
            [{
              'name' => attachment_fwd1.puid,
              'type' => 'folder',
              'irida-next-type' => 'attachment',
              'children' =>
              [{
                'name' => 'test_file_fwd_1.fastq',
                'type' => 'file',
                'metadata' =>
                {
                  'format' => 'fastq',
                  'direction' => 'forward',
                  'type' => 'pe'
                }
              },
               {
                 'name' => 'test_file_rev_1.fastq',
                 'type' => 'file',
                 'metadata' =>
                 {
                   'format' => 'fastq',
                   'direction' => 'reverse',
                   'type' => 'pe'
                 }
               }]
            },
             {
               'name' => attachment_rev2.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' =>
               [{
                 'name' => 'test_file_fwd_2.fastq',
                 'type' => 'file',
                 'metadata' =>
                 {
                   'format' => 'fastq',
                   'direction' => 'forward', 'type' => 'pe'
                 }
               },
                {
                  'name' => 'test_file_rev_2.fastq',
                  'type' => 'file',
                  'metadata' =>
                 {
                   'format' => 'fastq',
                   'direction' => 'reverse',
                   'type' => 'pe'
                 }
                }]
             },
             {
               'name' => attachment_fwd3.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' =>
              [{
                'name' => 'test_file_fwd_3.fastq',
                'type' => 'file',
                'metadata' =>
                {
                  'format' => 'fastq',
                  'direction' => 'forward',
                  'type' => 'pe'
                }
              },
               { 'name' => 'test_file_rev_3.fastq',
                 'type' => 'file',
                 'metadata' =>
                 {
                   'format' => 'fastq',
                   'direction' => 'reverse',
                   'type' => 'pe'
                 } }]
             },
             { 'name' => attachment_d.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' =>
              [{
                'name' => 'test_file_D.fastq',
                'type' => 'file',
                'metadata' => { 'format' => 'fastq' }
              }] },
             {
               'name' => attachment_e.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' =>
               [{
                 'name' => 'test_file_2.fastq.gz',
                 'type' => 'file',
                 'metadata' => { 'format' => 'fastq' }
               }]
             },
             {
               'name' => attachment_f.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' =>
               [{
                 'name' => 'test_file_14.fastq.gz',
                 'type' => 'file',
                 'metadata' => { 'format' => 'fastq' }
               }]
             }]
          }]
        }]
      }

      DataExports::CreateJob.perform_now(data_export)
      data_export.run_callbacks(:commit)
      export_file = ActiveStorage::Blob.service.path_for(data_export.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert_not expected_files_in_zip.count.positive?
      assert_equal expected_manifest.to_json, data_export.manifest
    end
  end
end
