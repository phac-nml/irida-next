# frozen_string_literal: true

require 'test_helper'

class GlobalSearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable(:global_search)
    @user = users(:john_doe)
    sign_in @user
  end

  teardown do
    Flipper.disable(:global_search)
  end

  test 'should get global search index' do
    get global_search_path, params: { q: 'Project 1' }

    assert_response :success
    assert_select '[data-global-search-version="g1"]'
  end

  test 'should return not found when global search feature flag is disabled' do
    Flipper.disable(:global_search)

    get global_search_path, params: { q: 'Project 1' }

    assert_response :not_found
  end

  test 'suggest should respect selected types' do
    get global_search_suggest_path(format: :json), params: {
      q: 'Project 1',
      types: ['projects']
    }

    assert_response :success

    payload = response.parsed_body
    assert_equal ['projects'], payload['meta']['types']
    assert(payload['results'].all? { |result| result['type'] == 'projects' })
  end

  test 'metadata search is off by default and available when explicitly enabled' do
    get global_search_suggest_path(format: :json), params: {
      q: 'value1',
      types: ['samples']
    }

    assert_response :success
    default_payload = response.parsed_body
    assert_equal [], default_payload['results']

    get global_search_suggest_path(format: :json), params: {
      q: 'value1',
      types: ['samples'],
      match_sources: ['metadata']
    }

    assert_response :success
    metadata_payload = response.parsed_body

    assert metadata_payload['results'].any?
    assert(metadata_payload['results'].all? { |result| result['type'] == 'samples' })
    assert(metadata_payload['results'].all? { |result| result['context_label'].present? })
    assert(metadata_payload['results'].all? { |result| result['context_url'].present? })
    assert metadata_payload['results'].any? do |result|
      result['match_tags'].include?('Metadata key') || result['match_tags'].include?('Metadata value')
    end
  end

  test 'suggest includes accessible automation-bot workflow executions' do
    get global_search_suggest_path(format: :json), params: {
      q: 'automated_workflow_execution',
      types: ['workflow_executions']
    }

    assert_response :success
    payload = response.parsed_body
    titles = payload['results'].pluck('title')

    assert_includes titles, 'automated_workflow_execution'
  end

  test 'suggest only includes current user data exports' do
    get global_search_suggest_path(format: :json), params: {
      q: 'Data Export',
      types: ['data_exports']
    }

    assert_response :success
    payload = response.parsed_body
    titles = payload['results'].pluck('title')

    assert_includes titles, 'Data Export 1'
    assert_not_includes titles, 'Data Export 4'
  end

  test 'uploader users do not receive sample hits' do
    uploader = User.create!(
      email: 'global-search-uploader@localhost',
      password: 'password1',
      first_name: 'Global',
      last_name: 'Uploader'
    )

    Member.create!(
      user: uploader,
      created_by: @user,
      namespace: namespaces_project_namespaces(:project1_namespace),
      access_level: Member::AccessLevel::UPLOADER
    )

    sign_in uploader

    get global_search_suggest_path(format: :json), params: {
      q: 'Project 1 Sample 1',
      types: ['samples'],
      match_sources: ['name']
    }

    assert_response :success
    payload = response.parsed_body

    assert_equal [], payload['results']
  end

  test 'most recent sort applies soft diversity for mixed types' do
    get global_search_suggest_path(format: :json), params: {
      q: 'Project',
      types: %w[projects samples],
      match_sources: ['name'],
      sort: 'most_recent',
      per_type_limit: 20,
      limit: 20
    }

    assert_response :success
    payload = response.parsed_body
    first_ten_types = payload['results'].first(10).pluck('type')

    assert_operator max_streak(first_ten_types), :<=, 4
  end

  private

  def max_streak(values)
    return 0 if values.empty?

    longest = 1
    current = 1

    values.each_cons(2) do |previous, current_value|
      if previous == current_value
        current += 1
        longest = [longest, current].max
      else
        current = 1
      end
    end

    longest
  end
end
