# frozen_string_literal: true

require 'active_storage_test_case'
require 'test_helper'
require 'webmock/minitest'

module WorkflowExecutions
  class CreateServiceTest < ActiveStorageTestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @sample = samples(:sample1)
      @attachment = attachments(:attachment1)
      @samples_workflow_executions_attributes = {
        '0': {
          sample_id: @sample.id,
          samplesheet_params: {
            sample: @sample.puid,
            fastq_1: @attachment.to_global_id
          }
        }
      }
    end

    test 'test create new workflow execution' do
      workflow_params1 = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      workflow_params2 = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs')
        .to_return(body: '{ "run_id": "create_run_1" }',
                   headers: { content_type:
                            'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_1/status')
        .to_return(body: '{ "run_id": "create_run_1", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      # do not perform completion job as this tests scope does not contain blob storage files
      assert_performed_jobs(3, except: [WorkflowExecutionCompletionJob, Turbo::Streams::BroadcastStreamJob]) do
        @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params1).execute
      end

      # don't perform the preparation job as we want to check that the workflow execution is new
      assert_performed_jobs(0, except: [WorkflowExecutionPreparationJob, Turbo::Streams::BroadcastStreamJob]) do
        @workflow_execution2 = WorkflowExecutions::CreateService.new(@user, workflow_params2).execute
      end

      assert_equal 'completing', @workflow_execution.reload.state
      assert_equal 'initial', @workflow_execution2.reload.state

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs')
        .to_return(body: '{ "run_id": "create_run_2" }',
                   headers: { content_type:
                            'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_2/status')
        .to_return(body: '{ "run_id": "create_run_2", "state": "COMPLETE" }',
                   headers: { content_type:
                            'application/json' })

      perform_enqueued_jobs except: WorkflowExecutionCompletionJob do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution2)
      end

      assert_equal 'completing', @workflow_execution2.reload.state
    end

    test 'test create workflow execution completion step' do
      # prep test
      @workflow_execution_completing = workflow_executions(:irida_next_example_completing_a)
      blob_run_directory_a = ActiveStorage::Blob.generate_unique_secure_token
      @workflow_execution_completing.blob_run_directory = blob_run_directory_a
      @workflow_execution_completing.save!

      # create file blobs
      make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/iridanext.output.json',
        blob_run_directory: blob_run_directory_a,
        gzip: true
      )
      make_and_upload_blob(
        filepath: 'test/fixtures/files/blob_outputs/normal/summary.txt',
        blob_run_directory: blob_run_directory_a
      )

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/my_run_id_a/status')
        .to_return(body: '{ "run_id": "create_run_1", "state": "COMPLETE" }',
                   headers: { content_type:
                           'application/json' })

      # start test
      assert_equal 'completing', @workflow_execution_completing.state

      assert_performed_jobs 2, only: [WorkflowExecutionStatusJob, WorkflowExecutionCompletionJob] do
        WorkflowExecutionStatusJob.perform_later(@workflow_execution_completing)
      end

      assert_equal 'completed', @workflow_execution_completing.reload.state
    end

    test 'test create new workflow execution with missing required workflow name' do
      workflow_params = {
        metadata:
          { workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages.include?(
        'Metadata object at root is missing required properties: workflow_name'
      )
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'test create new workflow execution with missing required workflow version' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert @workflow_execution.errors.full_messages
                                .include?('Metadata object at root is missing required properties: workflow_version')
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'test workflow execution canceled' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "create_run_4" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_4/status')
        .to_return(body: '{ "run_id": "run123", "state": "CANCELING" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'initial', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'canceled', @workflow_execution.reload.state
    end

    test 'test workflow execution error' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      stub_request(:post, 'http://www.example.com/ga4gh/wes/v1/runs').to_return(body: '{ "run_id": "create_run_5" }',
                                                                                headers: { content_type:
                                                                                           'application/json' })

      stub_request(:get, 'http://www.example.com/ga4gh/wes/v1/runs/create_run_5/status')
        .to_return(body: '{ "run_id": "create_run_5", "state": "EXECUTOR_ERROR" }',
                   headers: { content_type:
                            'application/json' })

      @workflow_execution = WorkflowExecutions::CreateService.new(
        @user, workflow_params
      ).execute

      assert_equal 'initial', @workflow_execution.state

      perform_enqueued_jobs do
        WorkflowExecutionPreparationJob.perform_now(@workflow_execution)
      end

      assert_equal 'error', @workflow_execution.reload.state
    end

    test 'test create new workflow execution sanitizes params' do
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample',
            workflow_version: '1.0.2' },
        workflow_params:
        {
          assembler: '',
          project_name: 'assembly',
          random_seed: '0'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert_equal '', @workflow_execution.workflow_params['assembler']
      assert_equal 'assembly', @workflow_execution.workflow_params['project_name']
      assert_equal 0, @workflow_execution.workflow_params['random_seed']
      expected_tags = { 'createdBy' => @user.email }
      assert_equal expected_tags, @workflow_execution.tags
      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'test create new workflow execution with workflow name' do
      test_name = 'test_workflow'
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
          {
            input: '/blah/samplesheet.csv',
            outdir: '/blah/output'
          },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        name: test_name,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      @workflow_execution.create_logidze_snapshot!

      assert 'initial', @workflow_execution.state
      assert_equal 1, @workflow_execution.log_data.version
      assert_equal 1, @workflow_execution.log_data.size

      assert_equal test_name, @workflow_execution.name
      expected_tags = { 'createdBy' => @user.email }
      assert_equal expected_tags, @workflow_execution.tags
      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'test create new workflow execution autoset params' do
      test_name = 'test_workflow'
      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
          {
            input: '/blah/samplesheet.csv',
            outdir: '/blah/output'
          },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        name: test_name,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert_not_nil @workflow_execution.workflow_type
      assert_not_nil @workflow_execution.workflow_type_version
      assert_not_nil @workflow_execution.workflow_engine
      assert_not_nil @workflow_execution.workflow_engine_version
      assert_not_nil @workflow_execution.workflow_url
      assert_not_nil @workflow_execution.workflow_engine_parameters

      workflow = Irida::Pipelines.instance.find_pipeline_by('phac-nml/iridanextexample', '1.0.2')
      assert_equal workflow.type, @workflow_execution.workflow_type
      assert_equal workflow.type_version, @workflow_execution.workflow_type_version
      assert_equal workflow.engine, @workflow_execution.workflow_engine
      assert_equal workflow.engine_version, @workflow_execution.workflow_engine_version
      assert_equal workflow.url, @workflow_execution.workflow_url
      assert_equal workflow.version, @workflow_execution.workflow_engine_parameters['-r']

      @workflow_execution.create_logidze_snapshot!

      assert 'initial', @workflow_execution.state
      assert_equal 1, @workflow_execution.log_data.version
      assert_equal 1, @workflow_execution.log_data.size

      assert_equal test_name, @workflow_execution.name
      expected_tags = { 'createdBy' => @user.email }
      assert_equal expected_tags, @workflow_execution.tags
      assert_enqueued_jobs(1, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'create workflow execution with incorrect permissions' do
      user = users(:jane_doe)

      workflow_params = {
        namespace_id: @project.namespace.id,
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: user.id,
        samples_workflow_executions_attributes: @samples_workflow_executions_attributes
      }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::CreateService.new(user, workflow_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :submit_workflow?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.submit_workflow?', name: @project.name),
                   exception.result.message
    end

    test 'create new workflow execution with non matching sample puid in sample sheet' do
      samples_workflow_executions_attributes = {
        '0': {
          sample_id: samples(:sample1).id,
          samplesheet_params: {
            sample: samples(:sample2).puid
          }
        }
      }

      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert_includes @workflow_execution.errors.full_messages,
                      "Samples workflow executions[0] samplesheet params #{I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_puid_error',
                                                                                  property: 'sample')}"
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'create new workflow execution with non matching attachments to sample' do
      samples_workflow_executions_attributes = {
        '0': {
          sample_id: samples(:sample2).id,
          samplesheet_params: {
            sample: samples(:sample2).puid,
            fastq_1: attachments(:attachment1).to_global_id # belongs to :sample1 # rubocop:disable Naming/VariableNumber
          }
        }
      }

      workflow_params = {
        metadata:
          { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params:
        {
          input: '/blah/samplesheet.csv',
          outdir: '/blah/output'
        },
        submitter_id: @user.id,
        namespace_id: @project.namespace.id,
        samples_workflow_executions_attributes: samples_workflow_executions_attributes
      }

      @workflow_execution = WorkflowExecutions::CreateService.new(@user, workflow_params).execute

      assert_includes @workflow_execution.errors.full_messages,
                      "Samples workflow executions[0] samplesheet params #{I18n.t(
                        'validators.workflow_execution_samplesheet_params_validator.sample_attachment_error', property: 'fastq_1'
                      )}"
      assert_enqueued_jobs(0, except: Turbo::Streams::BroadcastStreamJob)
    end
  end
end
