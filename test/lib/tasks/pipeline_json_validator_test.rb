# frozen_string_literal: true

require 'test_helper'
require 'open3'

class PipelineJsonValidatorTest < ActiveSupport::TestCase
  setup do
    @fixtures_path = Rails.root.join('test/lib/tasks/fixtures')
  end

  test 'validates valid pipeline JSON successfully' do
    valid_file = @fixtures_path.join('valid_pipeline.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            valid_file.to_s, chdir: Rails.root.to_s)

    # Should exit with 0 (success)
    assert_equal 0, status.exitstatus, 'Expected validation to succeed (exit code 0)'

    # Check for success message
    output = stdout + stderr
    assert_includes output, 'JSON file is valid.'
  end

  test 'detects duplicate pipeline versions' do
    duplicate_file = @fixtures_path.join('duplicate_versions.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            duplicate_file.to_s, chdir: Rails.root.to_s)

    # Should exit with 1 (failure)
    assert_equal 1, status.exitstatus, 'Expected validation to fail (exit code 1) due to duplicate versions'

    # Check for duplicate version error
    output = stdout + stderr
    assert_includes output, 'Duplicate pipeline versions [1.0.0] found for pipeline: test/duplicate-versions'
  end

  test 'detects unreachable URLs' do
    unreachable_file = @fixtures_path.join('unreachable_url.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            unreachable_file.to_s, chdir: Rails.root.to_s)

    # Should exit with 1 (failure)
    assert_equal 1, status.exitstatus, 'Expected validation to fail (exit code 1) due to unreachable URLs'

    # Check for URL error
    output = stdout + stderr
    assert_includes output, 'URL is NOT reachable'
  end

  test 'detects missing translations' do
    translation_file = @fixtures_path.join('missing_translations.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            translation_file.to_s, chdir: Rails.root.to_s)

    # Should exit with 1 (failure)
    assert_equal 1, status.exitstatus, 'Expected validation to fail (exit code 1) due to missing translations'

    # Check for translation error
    output = stdout + stderr
    assert_includes output, 'Missing translation keys en'
  end

  test 'detects schema validation errors' do
    schema_file = @fixtures_path.join('schema_errors.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            schema_file.to_s, chdir: Rails.root.to_s)

    # Should exit with 1 (failure)
    assert_equal 1, status.exitstatus, 'Expected validation to fail (exit code 1) due to schema errors'

    # Check for schema error
    output = stdout + stderr
    assert_includes output, 'JSON file is NOT valid according to the schema'
  end

  test 'handles non-existent file gracefully' do
    nonexistent_file = @fixtures_path.join('nonexistent.json')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                            nonexistent_file.to_s, chdir: Rails.root.to_s)

    # Should exit with non-zero (failure)
    assert_not_equal 0, status.exitstatus, 'Expected validation to fail for non-existent file'

    # Check for file error
    output = stdout + stderr
    assert_includes output, 'No such file or directory'
  end

  test 'handles invalid JSON gracefully' do
    invalid_json_file = @fixtures_path.join('invalid_json.json')
    File.write(invalid_json_file, '{ invalid json content')

    begin
      stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'pipeline_json_validator:validate',
                                              invalid_json_file.to_s, chdir: Rails.root.to_s)

      # Should exit with non-zero (failure)
      assert_not_equal 0, status.exitstatus, 'Expected validation to fail for invalid JSON'

      # Check for JSON parsing error
      output = stdout + stderr
      assert_includes output, "expected object key, got 'invalid' at line 1"
    ensure
      File.delete(invalid_json_file) if File.exist?(invalid_json_file) # rubocop:disable Lint/NonAtomicFileOperation
    end
  end
end
