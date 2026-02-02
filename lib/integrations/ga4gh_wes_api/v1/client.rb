# frozen_string_literal: true

module Integrations
  module Ga4ghWesApi
    module V1
      # API Integration with GA4GH WES
      # authentication token should be set in credentials/secrets file as ga4gh_wes:oauth_token
      class Client < Integrations::Ga4ghWesApi::V1::ApiRequester
        def service_info
          get(
            endpoint: 'service-info'
          )
        end

        # Arguments are defined here:
        # https://ga4gh.github.io/workflow-execution-service-schemas/docs/#tag/Workflow-Runs/operation/ListRuns
        # @param page_size [Integer <int64>] Optional
        # @param page_token [String] Optional
        def list_runs(**params)
          get(
            endpoint: 'runs',
            params:
          )
        end

        # Requires some of the following arguments as defined here:
        # https://ga4gh.github.io/workflow-execution-service-schemas/docs/#tag/Workflow-Runs/operation/RunWorkflow
        # @param workflow_params [String]
        # @param workflow_type [String]
        # @param workflow_type_version [String]
        # @param tags [String]
        # @param workflow_engine [String]
        # @param workflow_engine_version [String]
        # @param workflow_engine_parameters [String]
        # @param workflow_url [String]
        # @param workflow_attachment [Array of strings <binary>] Not implimented in V1
        def run_workflow(**params)
          # spec requires empty parameters be defined as empty strings
          base_params = { workflow_params: '',
                          workflow_type: '',
                          workflow_type_version: '',
                          tags: '',
                          workflow_engine: '',
                          workflow_engine_version: '',
                          workflow_engine_parameters: '',
                          workflow_url: '' }
          post(
            endpoint: 'runs',
            data: base_params.merge(params)
          )
        end

        # @param run_id [String] Required
        def get_run_log(run_id)
          get(
            endpoint: "runs/#{run_id}"
          )
        end

        # @param run_id [String] Required
        def get_run_status(run_id)
          get(
            endpoint: "runs/#{run_id}/status"
          )
        end

        # @param run_id [String] Required
        # @param page_size [Integer <int64>] Optional
        # @param page_token [String] Optional
        def list_tasks(run_id, **params)
          get(
            endpoint: "runs/#{run_id}/tasks",
            params:
          )
        end

        # @param run_id [String] Required
        # @param task_id [String] Required
        def get_task(run_id, task_id)
          get(
            endpoint: "runs/#{run_id}/tasks/#{task_id}"
          )
        end

        # @param run_id [String] Required
        def cancel_run(run_id)
          post(
            endpoint: "runs/#{run_id}/cancel"
          )
        end

        # Runs a md5 hash check. The method is used for testing connection with server api
        def run_test_nextflow_md5_job
          run_workflow(
            workflow_type: 'NFL',
            workflow_type_version: 'DSL2',
            workflow_engine: 'nextflow',
            workflow_engine_version: '24.10.3',
            workflow_url: 'https://github.com/jb-adams/md5-nf',
            workflow_params: { file_int: 3 }.to_json
          )
        end
      end
    end
  end
end
