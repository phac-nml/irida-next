# frozen_string_literal: true

require 'view_component_test_case'

class NextflowComponentTest < ViewComponentTestCase
  test 'default' do
    workflow = Irida::Pipeline.new(
      {
        'name' => 'phac-nml/iridanextexample',
        'description' => 'This is a test workflow',
        'url' => 'https://nf-co.re/testpipeline'
      },
      { 'name' => '2.0.0' },
      Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
      Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json')
    )

    render_inline NextflowComponent.new(
      workflow:,
      samples: [samples(:sample1), samples(:sample2), samples(:sample3)],
      url: 'https://nf-co.re/testpipeline',
      namespace_id: 'SDSDDFDSFDS',
      fields: %w[metadata_1 metadata_2 metadata_3]
    )

    assert_selector 'form' do
      assert_selector 'h1', text: 'phac-nml/iridanextexample', count: 1
      assert_selector '.samplesheet-table .table-column:first-child .table-td', count: 3
      assert_selector 'input[type=text][name="workflow_execution[name]"]'
    end
  end

  test 'with values' do
    instance = AutomatedWorkflowExecution.new(created_by: users(:john_doe),
                                              name: 'Test Instance',
                                              namespace: projects(:project1).namespace,
                                              workflow_params: {
                                                platform: 'illumina',
                                                min_reads: '1000',
                                                skip_mlst: 'false',
                                                kraken2_db: 'PATH_TO_DB',
                                                run_kraken: 'true',
                                                mash_sketch: '',
                                                mh_min_kmer: '10',
                                                skip_checkm: 'false',
                                                skip_report: 'false',
                                                skip_staramr: 'false',
                                                target_depth: '100',
                                                dehosting_idx: '',
                                                long_read_opt: 'nanopore',
                                                skip_abricate: 'false',
                                                skip_mobrecon: 'false',
                                                flye_read_type: 'hq',
                                                fp_dedup_reads: 'false',
                                                skip_polishing: 'false',
                                                skip_subtyping: 'false',
                                                metagenomic_run: 'false',
                                                fp_polyg_min_len: '10',
                                                fp_polyx_min_len: '10',
                                                hybrid_unicycler: 'true',
                                                fp_average_quality: '25',
                                                fp_qualified_phred: '15',
                                                nanopore_chemistry: '',
                                                skip_depth_sampling: 'false',
                                                qt_min_contig_length: '1000',
                                                ba_min_conting_length: '200',
                                                skip_raw_read_metrics: 'false',
                                                fp_illumina_length_max: '400',
                                                fp_illumina_length_min: '35',
                                                skip_version_gathering: 'false',
                                                fp_complexity_threshold: '20',
                                                fp_cut_tail_window_size: '4',
                                                fp_cut_tail_mean_quality: '15',
                                                fp_single_end_length_min: '1000',
                                                skip_ont_header_cleaning: 'true',
                                                skip_metagenomic_detection: 'false',
                                                skip_species_classification: 'false',
                                                fp_unqualified_precent_limit: '40'
                                              })

    workflow = Irida::Pipeline.new({
                                     url: 'https://github.com/phac-nml/mikrokondo',
                                     name: 'phac-nml/mikrokondo',
                                     description: 'Mikrokondo pipeline'
                                   }, '0.1.2',
                                   Rails.root.join('test/fixtures/files/nextflow/mikrokondo/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    render_inline NextflowComponent.new(
      workflow:,
      samples: [],
      url: 'https://nf-co.re/testpipeline',
      namespace_id: 'SDSDDFDSFDS',
      fields: %w[metadata_1 metadata_2 metadata_3],
      instance:
    )

    # rubocop:disable Layout/LineLength
    assert_selector 'form' do
      assert_selector ' input[name="workflow_execution[name]"][value="Test Instance"]', count: 1
      assert_selector 'input[name="workflow_execution[workflow_params][kraken2_db]"][value="PATH_TO_DB"]', count: 1
      assert_selector 'input[type="radio"][name="workflow_execution[workflow_params][run_kraken]"][value="true"][checked="checked"]',
                      count: 1
      assert_no_selector 'input[type="radio"][name="workflow_execution[workflow_params][run_kraken]"][value="false"][checked="checked"]'

      assert_selector 'input[type="radio"][name="workflow_execution[workflow_params][skip_depth_sampling]"][value="false"][checked="checked"]',
                      count: 1
      assert_no_selector 'input[type="radio"][name="workflow_execution[workflow_params][skip_depth_sampling]"][value="true"][checked="checked"]'
    end
    # rubocop:enable Layout/LineLength
  end
end
