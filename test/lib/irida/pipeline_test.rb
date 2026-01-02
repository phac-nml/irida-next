# frozen_string_literal: true

require 'test_helper'

class PipelinesTest < ActiveSupport::TestCase
  test 'automatable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => true, 'executable' => true },
                                   nil,
                                   nil)
    assert pipeline.automatable?
  end

  test 'not automatable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => false, 'executable' => true },
                                   nil,
                                   nil)
    assert_not pipeline.automatable?
  end

  test 'executable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => true, 'executable' => true },
                                   nil,
                                   nil)
    assert pipeline.executable?
  end

  test 'not executable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => false, 'executable' => false },
                                   nil,
                                   nil)
    assert_not pipeline.executable?
  end

  test 'unknown pipeline' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0' },
                                   nil,
                                   nil,
                                   unknown: true)
    assert pipeline.unknown?
  end

  test 'disabled pipeline' do
    pipeline1 = Irida::Pipeline.new('test/pipeline1',
                                    { 'name' => 'Test Pipeline 1', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0' },
                                    nil,
                                    nil,
                                    unknown: true)
    pipeline2 = Irida::Pipeline.new('test/pipeline2',
                                    { 'name' => 'Test Pipeline 2', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0', 'automatable' => true, 'executable' => false },
                                    nil,
                                    nil)
    pipeline3 = Irida::Pipeline.new('test/pipeline3',
                                    { 'name' => 'Test Pipeline 3', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0', 'automatable' => false, 'executable' => true },
                                    nil,
                                    nil)
    assert pipeline1.disabled?
    assert pipeline2.disabled?
    assert pipeline3.disabled?
  end

  test 'pipeline overrides' do
    entry = {
      url: 'https://github.com/phac-nml/mikrokondo',
      name: 'Mikrokondo pipeline',
      description: 'Mikrokondo pipeline example',
      overrides: {
        definitions: {
          databases_and_pre_computed_files: {
            title: 'Databases and Pre-Computed Files',
            description: 'The location of databases used by mikrokondo',
            properties: {
              kraken2_db: {
                type: 'string',
                description: 'Kraken2 database',
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

    pipeline = Irida::Pipeline.new('phac-nml/mikrokondo', entry, { name: '0.2.0' },
                                   Rails.root.join('test/fixtures/files/nextflow/mikrokondo/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    I18n.with_locale :en do
      assert_equal 'Mikrokondo pipeline', pipeline.name
      assert_equal 'Mikrokondo pipeline example', pipeline.description
      assert_equal 'Databases and Pre-Computed Files',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:title]
      assert_equal 'The location of databases used by mikrokondo',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:description]
      assert_equal 'Kraken2 database',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:properties][:kraken2_db][:description]
    end
  end

  test 'pipeline overrides in french' do
    entry = {
      url: 'https://github.com/phac-nml/mikrokondo',
      name: {
        en: 'Mikrokondo pipeline',
        fr: 'Pipeline Mikrokondo'
      },
      description: {
        en: 'Mikrokondo pipeline example',
        fr: 'Exemple Pipeline Mikrokondo'
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

    pipeline = Irida::Pipeline.new('phac-nml/mikrokondo', entry, { name: '0.2.0' },
                                   Rails.root.join('test/fixtures/files/nextflow/mikrokondo/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    I18n.with_locale :en do
      assert_equal 'Mikrokondo pipeline', pipeline.name
      assert_equal 'Mikrokondo pipeline example', pipeline.description
      assert_equal 'Databases and Pre-Computed Files',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:title]
      assert_equal 'The location of databases used by mikrokondo',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:description]
      assert_equal 'Kraken2 database',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:properties][:kraken2_db][:description]
    end

    I18n.with_locale :fr do
      assert_equal 'Pipeline Mikrokondo', pipeline.name
      assert_equal 'Exemple Pipeline Mikrokondo', pipeline.description
      assert_equal 'Bases de données et fichiers pré-calculés',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:title]
      assert_equal "L'emplacement des bases de données utilisées par mikrokondo",
                   pipeline.workflow_params[:databases_and_pre_computed_files][:description]
      assert_equal 'Base de données Kraken2',
                   pipeline.workflow_params[:databases_and_pre_computed_files][:properties][:kraken2_db][:description]
    end
  end

  test 'maximum_run_time at entry level (Irida Next Example Pipeline)' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      settings: {
        min_runtime: 30,
        max_runtime: 150
      }
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.2' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 150, pipeline.maximum_run_time(2)
  end

  test 'minimum_run_time at entry level (Irida Next Example Pipeline)' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      settings: {
        min_runtime: 30,
        max_runtime: 150
      }
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.2' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 30, pipeline.minimum_run_time(2)
  end

  test 'maximum_run_time at version level (1.0.3)' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      settings: {
        min_runtime: 30,
        max_runtime: 150
      }
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3', 'settings' => {
                                     'min_samples' => 2,
                                     'max_samples' => 2,
                                     'max_runtime' => '(30 * SAMPLE_COUNT) + 5',
                                     'status_check_interval' => 45
                                   } },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 65, pipeline.maximum_run_time(2)
  end

  test 'minimum_run_time at version level (1.0.3)' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      settings: {
        min_runtime: 30,
        max_runtime: 150
      }
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3', 'settings' => {
                                     'min_runtime' => '(20 * SAMPLE_COUNT) + 5'
                                   } },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 45, pipeline.minimum_run_time(2)
  end

  test 'status_check_interval default' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.2' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 30, pipeline.status_check_interval
  end

  test 'status_check_interval at version level (1.0.3)' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3', 'settings' => {
                                     'status_check_interval' => 45
                                   } },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 45, pipeline.status_check_interval
  end

  test 'maximum_run_time not set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.2' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_nil pipeline.maximum_run_time(2)
  end

  test 'minimum_run_time not set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.2' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_nil pipeline.minimum_run_time(2)
  end

  test 'minimum_samples set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3', 'settings' => {
                                     'min_samples' => 5
                                   } },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 5, pipeline.minimum_samples
  end

  test 'minimum_samples not set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 0, pipeline.minimum_samples
  end

  test 'maximum_samples set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3', 'settings' => {
                                     'max_samples' => 6
                                   } },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 6, pipeline.maximum_samples
  end

  test 'maximum_samples not set' do
    entry = {
      url: 'https://github.com/phac-nml/iridanextexample',
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline'
    }.with_indifferent_access

    pipeline = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { 'name' => '1.0.3' },
                                   Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json'),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    assert_equal 0, pipeline.maximum_samples
  end
end
