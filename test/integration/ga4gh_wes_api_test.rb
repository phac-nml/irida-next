# frozen_string_literal: true

# disable a bunch of style rules since we want the stubs to give/expect exactly what the server uses
# rubocop:disable Style/StringLiterals, Layout/SpaceInsideHashLiteralBraces, Lint/SymbolConversion, Style/QuotedSymbols, Layout/SpaceAfterColon, Layout/LineLength, Layout/SpaceAfterComma, Metrics/MethodLength

require 'faraday'
require 'json'
require 'test_helper'

class ClientTest < ActionDispatch::IntegrationTest
  # faraday test adapter for stubs
  def client(stubs)
    conn = Faraday.new do |builder|
      builder.adapter :test, stubs
    end
    # conn replaces Integrations::Ga4ghWesApi::V1::ApiConnection.new('example.com').conn
    Integrations::Ga4ghWesApi::V1::Client.new(conn:)
  end

  # def test_get
  #   ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new(url: 'http://localhost:7500/')
  #   ga4gh_client.service_info
  # end

  def test_get_service_info
    given_hash = {"id":"org.ga4gh.demo.wes.test","name":"WES API Test Demo","description":"An open source, community-driven implementation of the GA4GH Workflow Execution Service (WES)API specification.","contactUrl":"mailto:info@ga4gh.org","documentationUrl":"https://github.com/ga4gh/ga4gh-starter-kit-wes","createdAt":"2020-01-15T12:00:00Z","updatedAt":"2020-01-15T12:00:00Z","environment":"test","version":"0.3.2","type":{"group":"org.ga4gh","artifact":"wes","version":"1.0.1"},"organization":{"name":"Global Alliance for Genomics and Health","url":"https://ga4gh.org"},"workflow_type_versions":{"WDL":["1.0"],"NFL":["DSL2"]},"workflow_engine_versions":{"NATIVE":"1.0.0"}}
    expected_hash = { id: 'org.ga4gh.demo.wes.test', name: 'WES API Test Demo', description: 'An open source, community-driven implementation of the GA4GH Workflow Execution Service (WES)API specification.', contactUrl: 'mailto:info@ga4gh.org', documentationUrl: 'https://github.com/ga4gh/ga4gh-starter-kit-wes', createdAt: '2020-01-15T12:00:00Z', updatedAt: '2020-01-15T12:00:00Z', environment: 'test', version: '0.3.2', type: { group: 'org.ga4gh', artifact: 'wes', version: '1.0.1' }, organization: { name: 'Global Alliance for Genomics and Health', url: 'https://ga4gh.org' }, workflow_type_versions: { WDL: ['1.0'], NFL: ['DSL2'] }, workflow_engine_versions: { NATIVE: '1.0.0' } }

    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('service-info') do |env|
      assert_equal '/service-info', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.service_info
    stubs.verify_stubbed_calls
  end

  def test_list_runs
    given_hash = {"runs":[{"run_id":"b187534f-3c36-419c-92d8-bfe16fc23ce6","state":"COMPLETE"},{"run_id":"716ab7b0-cef7-4ae7-b467-26444b4c0579","state":"COMPLETE"}]}
    expected_hash = {runs: [{run_id: "b187534f-3c36-419c-92d8-bfe16fc23ce6", state: "COMPLETE"}, {run_id: "716ab7b0-cef7-4ae7-b467-26444b4c0579", state: "COMPLETE"}]}
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs') do |env|
      assert_equal '/runs', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.list_runs
    stubs.verify_stubbed_calls
  end

  def test_get_run_log
    given_hash = {"run_id":"716ab7b0-cef7-4ae7-b467-26444b4c0579","request":{"workflow_params":{"file_int":3},"workflow_type":"NFL","workflow_type_version":"DSL2","workflow_url":"https://github.com/jb-adams/md5-nf"},"state":"COMPLETE","run_log":{"name":"jb-adams/md5-nf","cmd":["#!/bin/bash -ue","echo \"Running md5 on /data/3.json\" >&2","md5sum /data/3.json | cut -f 1 -d ' '","#!/bin/bash -ue","echo \"Running sha1 on /data/3.json\" >&2","sha1sum /data/3.json | cut -f 1 -d ' '","#!/bin/bash -ue","echo \"Running sha256 on /data/3.json\" >&2","sha256sum /data/3.json | cut -f 1 -d ' '"],"start_time":"2023-10-26T18:45:25Z","end_time":"2023-10-26T18:45:26Z","stdout":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579?workdirs=4b%2F2731fdd09d04750fa0293c0265c503%2Ceb%2F5f7a4827fca53e1a441175e3911756%2Cae%2Fa94b1fbce9eacb9184ec25df376bf0","stderr":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579?workdirs=4b%2F2731fdd09d04750fa0293c0265c503%2Ceb%2F5f7a4827fca53e1a441175e3911756%2Cae%2Fa94b1fbce9eacb9184ec25df376bf0","exit_code":0},"task_logs":[{"name":"md5","cmd":["#!/bin/bash -ue","echo \"Running md5 on /data/3.json\" >&2","md5sum /data/3.json | cut -f 1 -d ' '"],"start_time":"2023-10-26T18:45:25Z","end_time":"2023-10-26T18:45:25Z","stdout":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/4b/2731fdd09d04750fa0293c0265c503","stderr":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/4b/2731fdd09d04750fa0293c0265c503","exit_code":0},{"name":"sha1","cmd":["#!/bin/bash -ue","echo \"Running sha1 on /data/3.json\" >&2","sha1sum /data/3.json | cut -f 1 -d ' '"],"start_time":"2023-10-26T18:45:25Z","end_time":"2023-10-26T18:45:25Z","stdout":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/eb/5f7a4827fca53e1a441175e3911756","stderr":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/eb/5f7a4827fca53e1a441175e3911756","exit_code":0},{"name":"sha256","cmd":["#!/bin/bash -ue","echo \"Running sha256 on /data/3.json\" >&2","sha256sum /data/3.json | cut -f 1 -d ' '"],"start_time":"2023-10-26T18:45:26Z","end_time":"2023-10-26T18:45:26Z","stdout":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/ae/a94b1fbce9eacb9184ec25df376bf0","stderr":"http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/ae/a94b1fbce9eacb9184ec25df376bf0","exit_code":0}],"outputs":{}}
    expected_hash = {run_id: "716ab7b0-cef7-4ae7-b467-26444b4c0579", request: {workflow_params: {file_int: 3}, workflow_type: "NFL", workflow_type_version: "DSL2", workflow_url: "https://github.com/jb-adams/md5-nf"}, state: "COMPLETE", run_log: {name: "jb-adams/md5-nf", cmd: ["#!/bin/bash -ue", "echo \"Running md5 on /data/3.json\" >&2", "md5sum /data/3.json | cut -f 1 -d ' '", "#!/bin/bash -ue", "echo \"Running sha1 on /data/3.json\" >&2", "sha1sum /data/3.json | cut -f 1 -d ' '", "#!/bin/bash -ue", "echo \"Running sha256 on /data/3.json\" >&2", "sha256sum /data/3.json | cut -f 1 -d ' '"], start_time: "2023-10-26T18:45:25Z", end_time: "2023-10-26T18:45:26Z", stdout: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579?workdirs=4b%2F2731fdd09d04750fa0293c0265c503%2Ceb%2F5f7a4827fca53e1a441175e3911756%2Cae%2Fa94b1fbce9eacb9184ec25df376bf0", stderr: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579?workdirs=4b%2F2731fdd09d04750fa0293c0265c503%2Ceb%2F5f7a4827fca53e1a441175e3911756%2Cae%2Fa94b1fbce9eacb9184ec25df376bf0", exit_code: 0}, task_logs: [{name: "md5", cmd: ["#!/bin/bash -ue", "echo \"Running md5 on /data/3.json\" >&2", "md5sum /data/3.json | cut -f 1 -d ' '"], start_time: "2023-10-26T18:45:25Z", end_time: "2023-10-26T18:45:25Z", stdout: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/4b/2731fdd09d04750fa0293c0265c503", stderr: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/4b/2731fdd09d04750fa0293c0265c503", exit_code: 0}, {name: "sha1", cmd: ["#!/bin/bash -ue", "echo \"Running sha1 on /data/3.json\" >&2", "sha1sum /data/3.json | cut -f 1 -d ' '"], start_time: "2023-10-26T18:45:25Z", end_time: "2023-10-26T18:45:25Z", stdout: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/eb/5f7a4827fca53e1a441175e3911756", stderr: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/eb/5f7a4827fca53e1a441175e3911756", exit_code: 0}, {name: "sha256", cmd: ["#!/bin/bash -ue", "echo \"Running sha256 on /data/3.json\" >&2", "sha256sum /data/3.json | cut -f 1 -d ' '"], start_time: "2023-10-26T18:45:26Z", end_time: "2023-10-26T18:45:26Z", stdout: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stdout/716ab7b0-cef7-4ae7-b467-26444b4c0579/ae/a94b1fbce9eacb9184ec25df376bf0", stderr: "http://localhost:7500/ga4gh/wes/v1/logs/nextflow/stderr/716ab7b0-cef7-4ae7-b467-26444b4c0579/ae/a94b1fbce9eacb9184ec25df376bf0", exit_code: 0}], outputs: {}}
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579') do |env|
      assert_equal '/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.get_run_log('716ab7b0-cef7-4ae7-b467-26444b4c0579')
    stubs.verify_stubbed_calls
  end

  # 400
  def test_malformed
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs') do |env|
      assert_equal '/runs', env.url.path
      raise Faraday::BadRequestError.new({status: "malformed",
                                          headers: "",
                                          body: "",
                                          request: {
                                            method: 'get',
                                            url: "/runs"
                                          }})
    end

    cli = client(stubs)
    assert_raise Integrations::ApiExceptions::BadRequestError do
      cli.list_runs
    end
    stubs.verify_stubbed_calls
  end

  # 401
  def test_unauthorized
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/run-id') do |env|
      assert_equal '/runs/run-id', env.url.path
      raise Faraday::UnauthorizedError.new({status: "unauthorized",
                                            headers: "",
                                            body: "",
                                            request: {
                                              method: "get",
                                              url: "/runs/run-id"
                                            }})
    end

    cli = client(stubs)
    assert_raise Integrations::ApiExceptions::UnauthorizedError do
      cli.get_run_log('run-id')
    end
    stubs.verify_stubbed_calls
  end

  # 403
  def test_forbidden
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/run-id') do |env|
      assert_equal '/runs/run-id', env.url.path
      raise Faraday::ForbiddenError.new({status: "forbidden",
                                         headers: "",
                                         body: "",
                                         request: {
                                           method: 'get',
                                           url: '/runs/run-id'
                                         }})
    end

    cli = client(stubs)
    assert_raise Integrations::ApiExceptions::ForbiddenError do
      cli.get_run_log('run-id')
    end
    stubs.verify_stubbed_calls
  end

  # 404
  def test_resource_not_found
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/not-a-run') do |env|
      assert_equal '/runs/not-a-run', env.url.path
      raise Faraday::ResourceNotFound.new({status: "not found",
                                           headers: "",
                                           body: "",
                                           request: {
                                             method: 'get',
                                             url: "/runs/not-a-run"
                                           }})
    end

    cli = client(stubs)
    assert_raise Integrations::ApiExceptions::NotFoundError do
      cli.get_run_log('not-a-run')
    end
    stubs.verify_stubbed_calls
  end

  # 500
  def test_server_error
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/run-id') do |env|
      assert_equal '/runs/run-id', env.url.path
      raise Faraday::ServerError.new({status: "server error",
                                      headers: "",
                                      body: "",
                                      request: {
                                        method: 'get',
                                        url: "/runs/run-id"
                                      }})
    end

    cli = client(stubs)
    assert_raise Integrations::ApiExceptions::ApiError do
      cli.get_run_log('run-id')
    end
    stubs.verify_stubbed_calls
  end

  def test_get_run_status
    given_hash = {"run_id":"716ab7b0-cef7-4ae7-b467-26444b4c0579","state":"COMPLETE"}
    expected_hash = { run_id: "716ab7b0-cef7-4ae7-b467-26444b4c0579", state: "COMPLETE" }
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/status') do |env|
      assert_equal '/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/status', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.get_run_status('716ab7b0-cef7-4ae7-b467-26444b4c0579')
    stubs.verify_stubbed_calls
  end

  def test_cancel_run
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post('/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/cancel') do |env|
      assert_equal '/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/cancel', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' }
      ]
    end

    cli = client(stubs)
    # oddly enough, posting to '/runs/<id>/cancel' does not include a body
    assert_nil cli.cancel_run('716ab7b0-cef7-4ae7-b467-26444b4c0579')
    stubs.verify_stubbed_calls
  end

  def test_get_task
    given_hash = {"name": "task_id","cmd":["string"],"start_time": "string","end_time": "string","stdout": "string","stderr": "string","exit_code": 0,"system_logs":["string"],"id": "string","tes_uri": "string"}
    expected_hash = { name: "task_id", cmd:["string"], start_time: "string", end_time: "string", stdout: "string", stderr: "string", exit_code: 0, system_logs: ["string"], id: "string", tes_uri: "string" }
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/tasks/task_id') do |env|
      assert_equal '/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/tasks/task_id', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.get_task('716ab7b0-cef7-4ae7-b467-26444b4c0579', 'task_id')
    stubs.verify_stubbed_calls
  end

  def test_list_tasks
    given_hash = {"task_logs":[{"name": "string","cmd":["string"],"start_time": "string","end_time": "string","stdout": "string","stderr": "string","exit_code": 0,"system_logs":["string"],"id": "string","tes_uri": "string"}],"next_page_token": "string"}
    expected_hash = { task_logs: [{ name: "string", cmd:["string"], start_time: "string", end_time: "string", stdout: "string", stderr: "string", exit_code: 0, system_logs: ["string"], id: "string", tes_uri: "string"}], next_page_token: "string" }
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/tasks') do |env|
      assert_equal '/runs/716ab7b0-cef7-4ae7-b467-26444b4c0579/tasks', env.url.path
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    cli = client(stubs)
    assert_equal expected_hash, cli.list_tasks('716ab7b0-cef7-4ae7-b467-26444b4c0579')
    stubs.verify_stubbed_calls
  end

  def test_run_test_nextflow_md5_job
    given_hash = {"run_id":"aa5cd004-1fb5-4cc9-84c5-63c0e4956588"}
    expected_hash = { run_id: 'aa5cd004-1fb5-4cc9-84c5-63c0e4956588' }
    stubs = Faraday::Adapter::Test::Stubs.new(strict_mode: true)
    body = {
      workflow_params: {file_int: 3}.to_json,
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      tags: '',
      workflow_engine: 'nextflow',
      workflow_engine_version: '23.10.0',
      workflow_engine_parameters: '',
      workflow_url: 'https://github.com/jb-adams/md5-nf'
    }
    stubs.post('/runs', body) do
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    conn = Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }) do |builder|
      builder.adapter :test, stubs
    end

    cli = Integrations::Ga4ghWesApi::V1::Client.new(conn:)
    assert_equal expected_hash, cli.run_test_nextflow_md5_job

    stubs.verify_stubbed_calls
  end

  def test_run_workflow
    given_hash = {"run_id":"aa5cd004-1fb5-4cc9-84c5-63c0e4956588"}
    expected_hash = { run_id: 'aa5cd004-1fb5-4cc9-84c5-63c0e4956588' }
    stubs = Faraday::Adapter::Test::Stubs.new(strict_mode: true)
    body = {
      workflow_params: {file_int: 3}.to_json,
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      tags: '',
      workflow_engine: 'nextflow',
      workflow_engine_version: '23.10.0',
      workflow_engine_parameters: '',
      workflow_url: 'https://github.com/jb-adams/md5-nf'
    }
    stubs.post('/runs', body) do
      [
        200,
        { 'Content-Type': 'application/json' },
        given_hash
      ]
    end

    conn = Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }) do |builder|
      builder.adapter :test, stubs
    end

    cli = Integrations::Ga4ghWesApi::V1::Client.new(conn:)
    assert_equal expected_hash, cli.run_workflow(
      workflow_type: 'NFL',
      workflow_type_version: 'DSL2',
      workflow_engine: 'nextflow',
      workflow_engine_version: '23.10.0',
      workflow_url: 'https://github.com/jb-adams/md5-nf',
      workflow_params: {file_int: 3}.to_json
    )

    stubs.verify_stubbed_calls
  end
end

# rubocop:enable Style/StringLiterals, Layout/SpaceInsideHashLiteralBraces, Lint/SymbolConversion, Style/QuotedSymbols, Layout/SpaceAfterColon, Layout/LineLength, Layout/SpaceAfterComma, Metrics/MethodLength
