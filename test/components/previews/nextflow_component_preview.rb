# frozen_string_literal: true

class NextflowComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'nextflow_schema.json')
    sample1 = Sample.first
    sample2 = Sample.second

    entry = {
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      url: 'https://github.com/phac-nml/iridanextexample'
    }
    workflow = Irida::Pipeline.new(entry, '1.0.1',
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    render_with_template(locals: {
                           samples: [sample1, sample2],
                           workflow:
                         })
  end

  def with_overrides # rubocop:disable Metrics/MethodLength
    entry = {
      url: 'https://github.com/phac-nml/mikrokondo',
      name: 'phac-nml/mikrokondo',
      description: {
        en: 'Mikrokondo pipeline',
        fr: 'Pipeline Mikrokondo'
      },
      overrides: {
        definitions: {
          databases_and_pre_computed_files: {
            title: {
              en: 'Databases and Pre-Computed Files',
              fr: 'Bases de données et fichiers pré-calculés'
            },
            description: {
              en: 'The location of databases used by mikrokondo',
              fr: "L'emplacement des bases de données utilisées par mikrokondo"
            },
            properties: {
              kraken2_db: {
                type: 'string',
                description: {
                  en: 'Kraken2 database',
                  fr: 'Base de données Kraken2'
                },
                enum: [
                  %w[
                    DBNAME
                    PATH_TO_DB
                  ],
                  %w[
                    ANOTHER_DB
                    ANOTHER_PATH
                  ]
                ]
              }
            }
          }
        }
      },
      versions: [
        {
          name: '0.2.0',
          automatable: true
        }
      ]
    }.with_indifferent_access

    workflow = Irida::Pipeline.new(entry, '0.2.0',
                                   Rails.root.join('test/fixtures/files/nextflow/mikrokondo/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    render_with_template(locals: {
                           workflow:
                         })
  end

  # @param schema_file select :schema_file_options
  def with_values(schema_file: 'mikrokondo/nextflow_schema.json')
    entry = {
      url: 'https://github.com/phac-nml/mikrokondo',
      name: 'phac-nml/mikrokondo',
      description: 'Mikrokondo pipeline'
    }
    workflow = Irida::Pipeline.new(entry, '0.1.2',
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))
    render_with_template(
      locals: {
        workflow:,
        instance: create_instance
      }
    )
  end

  private

  def create_instance # rubocop:disable Metrics/MethodLength
    AutomatedWorkflowExecution.new(created_by: User.first,
                                   name: 'Test Instance',
                                   namespace: Project.first.namespace,
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
  end

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('nextflow_schema')
    end
  end
end
