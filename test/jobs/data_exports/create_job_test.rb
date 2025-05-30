# frozen_string_literal: true

require 'test_helper'
module DataExports
  class CreateJobTest < ActiveJob::TestCase
    def setup
      @data_export2 = data_exports(:data_export_two)
      @data_export6 = data_exports(:data_export_six)
    end

    test 'creating export and updating data_export status' do
      assert @data_export2.status = 'processing'
      assert_not @data_export2.file.valid?

      assert_difference -> { ActiveStorage::Attachment.count } => +1 do
        DataExports::CreateJob.perform_now(@data_export2)
      end

      assert_equal 'ready', @data_export2.status
      assert @data_export2.file.valid?
      assert_equal "#{@data_export2.id}.zip", @data_export2.file.filename.to_s
    end

    test 'content of sample export' do
      sample = samples(:sample1)
      project = projects(:project1)
      attachment1 = attachments(:attachment1)
      attachment2 = attachments(:attachment2)
      expected_files_in_zip = ["#{project.puid}/#{sample.puid}/#{attachment1.puid}/#{attachment1.file.filename}",
                               "#{project.puid}/#{sample.puid}/#{attachment2.puid}/#{attachment2.file.filename}",
                               'manifest.json',
                               'manifest.txt']
      DataExports::CreateJob.perform_now(@data_export2)
      export_file = ActiveStorage::Blob.service.path_for(@data_export2.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert expected_files_in_zip.empty?
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
                'name' => 'test_file_A.fastq',
                'type' => 'file',
                'metadata' => { 'format' => 'fastq' }
              }]
            },
             {
               'name' => attachment2.puid,
               'type' => 'folder',
               'irida-next-type' => 'attachment',
               'children' => [{
                 'name' => 'test_file_B.fastq',
                 'type' => 'file',
                 'metadata' => { 'format' => 'fastq' }
               }]
             }]
          }]
        }]
      }

      assert_equal expected_manifest.to_json, @data_export2.manifest
    end

    test 'content of sample export simple manifest' do
      sample = samples(:sample1)
      project = projects(:project1)
      attachment1 = attachments(:attachment1)
      attachment2 = attachments(:attachment2)
      expected_files_in_zip = ["#{project.puid}/#{sample.puid}/#{attachment1.puid}/#{attachment1.file.filename}",
                               "#{project.puid}/#{sample.puid}/#{attachment2.puid}/#{attachment2.file.filename}",
                               'manifest.json',
                               'manifest.txt']
      actual_simple_manifest = ''

      DataExports::CreateJob.perform_now(@data_export2)
      export_file = ActiveStorage::Blob.service.path_for(@data_export2.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          actual_simple_manifest = entry.get_input_stream.read.force_encoding('utf-8') if entry.to_s == 'manifest.txt'
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert expected_files_in_zip.empty?

      expected_simple_manifest = [
        'Samples Export',
        Date.current.strftime('%Y-%m-%d').to_s,
        '',
        'contents:',
        '9eb3e2b7-6e20-5324-b6a3-49f44dc33fd8/',
        '└─ INXT_PRJ_AAAAAAAAAA/ (Project 1)',
        '   └─ INXT_SAM_AAAAAAAAAA/ (Project 1 Sample 1)',
        '      ├─ INXT_ATT_AAAAAAAAAA/',
        '      │  └─ test_file_A.fastq',
        '      └─ INXT_ATT_AAAAAAAAAB/',
        '         └─ test_file_B.fastq',
        ''
      ].join("\n")

      assert_equal expected_simple_manifest, actual_simple_manifest
    end

    test 'content of sample export including paired files' do
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
          'manifest.json',
          'manifest.txt'
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
      assert expected_files_in_zip.empty?
      assert_equal expected_manifest.to_json, data_export.manifest
    end

    test 'content of analysis export' do
      workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
      samples_workflow_execution = samples_workflow_executions(:sample46_irida_next_example_completed_with_output)
      sample = samples(:sample46)
      sample_puid = samples_workflow_execution.samplesheet_params['sample']
      expected_files_in_zip = [
        "#{workflow_execution.id}/#{sample_puid}/#{samples_workflow_execution.outputs[0].filename}",
        'manifest.json',
        'manifest.txt',
        "#{workflow_execution.id}/#{workflow_execution.outputs[0].filename}"
      ]
      DataExports::CreateJob.perform_now(@data_export6)
      export_file = ActiveStorage::Blob.service.path_for(@data_export6.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert expected_files_in_zip.empty?
      expected_manifest = {
        'type' => 'Analysis Export',
        'date' => Date.current.strftime('%Y-%m-%d'),
        'children' =>
        [
          { 'name' => workflow_execution.id,
            'type' => 'folder',
            'irida-next-type' => 'workflow_execution',
            'irida-next-name' => workflow_execution.name,
            'children' => [
              {
                'name' => workflow_execution.outputs[0].filename.to_s,
                'type' => 'file'
              },
              {
                'name' => sample_puid,
                'type' => 'folder',
                'irida-next-type' => 'sample',
                'irida-next-name' => sample.name,
                'children' =>
                [
                  {
                    'name' => samples_workflow_execution.outputs[0].filename.to_s,
                    'type' => 'file'
                  }
                ]
              }
            ] }
        ]
      }

      assert_equal expected_manifest.to_json, @data_export6.manifest
      assert_equal 'ready', @data_export6.status
    end

    test 'content of analysis export after sample is deleted' do
      workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
      samples_workflow_execution = samples_workflow_executions(:sample46_irida_next_example_completed_with_output)
      sample = samples(:sample46)
      sample_puid = samples_workflow_execution.samplesheet_params['sample']
      actual_simple_manifest = ''

      expected_files_in_zip = [
        "#{workflow_execution.id}/#{sample_puid}/#{samples_workflow_execution.outputs[0].filename}",
        'manifest.json',
        'manifest.txt',
        "#{workflow_execution.id}/#{workflow_execution.outputs[0].filename}"
      ]

      assert_difference(-> { Sample.count } => -1) do
        sample.destroy
      end

      DataExports::CreateJob.perform_now(@data_export6)
      export_file = ActiveStorage::Blob.service.path_for(@data_export6.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          actual_simple_manifest = entry.get_input_stream.read.force_encoding('utf-8') if entry.to_s == 'manifest.txt'
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert expected_files_in_zip.empty?
      expected_manifest = {
        'type' => 'Analysis Export',
        'date' => Date.current.strftime('%Y-%m-%d'),
        'children' =>
        [
          { 'name' => workflow_execution.id,
            'type' => 'folder',
            'irida-next-type' => 'workflow_execution',
            'irida-next-name' => workflow_execution.name,
            'children' => [
              {
                'name' => workflow_execution.outputs[0].filename.to_s,
                'type' => 'file'
              },
              {
                'name' => sample_puid,
                'type' => 'folder',
                'irida-next-type' => 'sample',
                'irida-next-name' => 'Deleted Sample',
                'children' =>
                [
                  {
                    'name' => samples_workflow_execution.outputs[0].filename.to_s,
                    'type' => 'file'
                  }
                ]
              }
            ] }
        ]
      }

      assert_equal expected_manifest.to_json, @data_export6.manifest

      expected_simple_manifest = [
        'Analysis Export',
        Date.current.strftime('%Y-%m-%d').to_s,
        '',
        'contents:',
        "#{@data_export6.id}/",
        "└─ #{workflow_execution.id}/ (#{workflow_execution.name})",
        "   ├─ #{workflow_execution.outputs[0].filename}",
        "   └─ #{samples_workflow_execution.samplesheet_params['sample']}/ (Deleted Sample)",
        "      └─ #{samples_workflow_execution.outputs[0].filename}",
        ''
      ].join("\n")

      assert_equal expected_simple_manifest, actual_simple_manifest

      assert_equal 'ready', @data_export6.status
    end

    test 'create csv linelist export with project namespace.type and csv content' do
      sample32 = samples(:sample32)
      data_export8 = data_exports(:data_export_eight)
      DataExports::CreateJob.perform_now(data_export8)

      export_file = ActiveStorage::Blob.service.path_for(data_export8.file.key)
      csv_text = File.read(export_file)
      csv = CSV.parse(csv_text, headers: true)
      csv.each do |row|
        assert_equal sample32.puid, row['SAMPLE PUID']
        assert_equal sample32.name, row['SAMPLE NAME']
        assert_equal sample32.project.puid, row['PROJECT PUID']
        assert_equal sample32.metadata['metadatafield1'], row['METADATAFIELD1']
        assert_equal sample32.metadata['metadatafield2'], row['METADATAFIELD2']
      end
    end

    test 'create xlsx linelist export with group namespace.type, empty metadata field and xlsx content' do
      sample32 = samples(:sample32)
      sample33 = samples(:sample33)
      sample34 = samples(:sample34)
      data_export9 = data_exports(:data_export_nine)

      DataExports::CreateJob.perform_now(data_export9)
      export_file = Roo::Spreadsheet.open(ActiveStorage::Blob.service.path_for(data_export9.file.key),
                                          extension: 'xlsx')

      assert_equal ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID', 'METADATAFIELD1', 'NON_EXISTANT_FIELD',
                    'METADATAFIELD2'],
                   export_file.row(1)
      assert_equal [
        sample32.puid,
        sample32.name,
        sample32.project.puid,
        sample32.metadata['metadatafield1'],
        sample32.metadata['non_existant_field'],
        sample32.metadata['metadatafield2']
      ], export_file.row(2)

      assert_equal [
        sample33.puid,
        sample33.name,
        sample33.project.puid,
        sample33.metadata['metadatafield1'],
        sample33.metadata['non_existant_field'],
        sample33.metadata['metadatafield2']
      ], export_file.row(3)

      assert_equal [
        sample34.puid,
        sample34.name,
        sample34.project.puid,
        sample34.metadata['metadatafield1'],
        sample34.metadata['non_existant_field'],
        sample34.metadata['metadatafield2']
      ], export_file.row(4)
    end

    test 'sample export with specified attachment_formats' do
      sample22 = samples(:sample22)
      project = projects(:project2)
      text_attachment = attachments(:sample22AttachmentText)
      fasta_attachment = attachments(:sample22AttachmentFasta)
      data_export = data_exports(:data_export_ten)

      # sample22 contains fastq, fasta and text files, but export specifies only text and fasta files
      assert_equal 4, sample22.attachments.count

      expected_files_in_zip =
        [
          "#{project.puid}/#{sample22.puid}/#{text_attachment.puid}/#{text_attachment.file.filename}",
          "#{project.puid}/#{sample22.puid}/#{fasta_attachment.puid}/#{fasta_attachment.file.filename}",
          'manifest.json',
          'manifest.txt'
        ]

      expected_manifest = {
        'type' => 'Samples Export',
        'date' => Date.current.strftime('%Y-%m-%d'),
        'children' =>
        [{
          'name' => project.puid,
          'type' => 'folder',
          'irida-next-type' => 'project',
          'irida-next-name' => 'Project 2',
          'children' =>
          [{
            'name' => sample22.puid,
            'type' => 'folder',
            'irida-next-type' => 'sample',
            'irida-next-name' => 'Project 2 Sample 22',
            'children' =>
            [{
              'name' => fasta_attachment.puid,
              'type' => 'folder',
              'irida-next-type' => 'attachment',
              'children' =>
              [{
                'name' => fasta_attachment.file.filename,
                'type' => 'file',
                'metadata' =>
                {
                  'format' => 'fasta',
                  'type' => 'assembly'
                }
              }]
            }, {
              'name' => text_attachment.puid,
              'type' => 'folder',
              'irida-next-type' => 'attachment',
              'children' =>
              [{
                'name' => text_attachment.file.filename,
                'type' => 'file',
                'metadata' =>
                {
                  'format' => 'text'
                }
              }]
            }]
          }]
        }]
      }

      DataExports::CreateJob.perform_now(data_export)

      export_file = ActiveStorage::Blob.service.path_for(data_export.file.key)
      Zip::File.open(export_file) do |zip_file|
        zip_file.each do |entry|
          assert expected_files_in_zip.include?(entry.to_s)
          expected_files_in_zip.delete(entry.to_s)
        end
      end
      assert expected_files_in_zip.empty?
      assert_equal expected_manifest.to_json, data_export.manifest
    end

    test 'turbo stream broadcasts' do
      user = users(:john_doe)
      assert_no_turbo_stream_broadcasts [user, :data_exports]

      assert_turbo_stream_broadcasts [user, :data_exports], count: 3 do
        DataExports::CreateJob.perform_now(@data_export2)
      end
    end
  end
end
