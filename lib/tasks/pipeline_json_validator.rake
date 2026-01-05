# frozen_string_literal: true

# Rake task to validate pipeline JSON configuration files against a JSON schema
# USAGE:
#  rake pipeline_json_validator:validate path/to/PIPELINES_JSON_CONFIG_FILE
#
#  If no file path is provided as an argument, the task will prompt for user input.
#  Exits with status code 0 if valid, 1 if invalid.
namespace :pipeline_json_validator do # rubocop:disable Metrics/BlockLength
  @errors = []
  @invalid_json = false
  @required_translation_keys = %w[en fr]

  desc 'Validate JSON files against a JSON schema'
  task :validate do # rubocop:disable Rails/RakeEnvironment
    if ARGV[1].nil?
      puts 'Please enter path to pipelines json configuration file to validate:'
      json_file_path_input = $stdin.gets.chomp
    else
      json_file_path_input = ARGV[1]
    end
    json_file_path = Rails.root.join(json_file_path_input)

    json_data = validate_json(json_file_path)

    # Exit early if JSON is malformed
    early_exit if @invalid_json

    puts "Validating JSON file at: #{json_file_path_input} against the schema..."
    validate_schema(json_data)

    # Exit early if schema validation failed
    early_exit if @errors.any?

    puts 'Verifying singular version entries for pipelines...'
    verify_singular_version_entry(json_data)

    puts 'Verifying URLs exist and are reachable...'
    verify_url_exists_and_reachable(json_data)

    puts 'Verifying translations...'
    translation_verification(json_data)

    puts 'Validation results:'
    output_validation_results

    exit(@errors.empty? ? 0 : 1)
  end

  private

  def early_exit
    puts 'Validation results:'
    output_validation_results
    exit(1)
  end

  # Validate that the JSON file is well-formed
  def validate_json(json_file_path)
    JSON.parse(File.read(json_file_path))
  rescue JSON::ParserError => e
    @errors << "Invalid JSON format: #{e.message}"
    @invalid_json = true
    nil
  end

  # Validate pipeline json config against the IRIDA Next pipelines schema
  def validate_schema(json_data)
    schema_path = Rails.root.join('config/schemas/pipelines_schema.json')
    schema = JSON.parse(File.read(schema_path))

    schemer = JSONSchemer.schema(schema)
    result = schemer.validate(json_data).to_a

    return if result.empty?

    @errors << 'JSON file is NOT valid according to the schema'

    result.each do |res|
      @errors << "Error: #{res['error']}"
      @errors << "Error Details: #{res['details']}:"
    end
  end

  # Verify that each pipeline has singular version entries
  def verify_singular_version_entry(json_data)
    json_data.each do |pipeline_key, pipeline_hash|
      next unless pipeline_hash.key?('versions') && pipeline_hash['versions'].is_a?(Array)

      duplicate_pipeline_versions = pipeline_hash['versions'].map { |v| v['name'] }
      counts = duplicate_pipeline_versions.tally
      duplicates_with_counts = counts.select { |_version, count| count > 1 }
      only_duplicates = duplicates_with_counts.keys

      unless only_duplicates.empty?
        @errors << "Duplicate pipeline versions [#{only_duplicates.join(', ')}] found for pipeline: #{pipeline_key}"
      end
    end
  end

  # Verify that each pipeline version URL exists and is reachable
  def verify_url_exists_and_reachable(json_data) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    progressbar = ProgressBar.create(title: 'Checking URLs', total: json_data.size, format: '%t: |%B| %p%% %e')
    json_data.each_value do |pipeline_hash|
      base_url = pipeline_hash['url']

      pipeline_hash['versions'].each do |version|
        next unless version.key?('name')

        filename = 'nextflow_schema.json'
        uri = URI.parse(base_url)
        url = URI("https://raw.githubusercontent.com#{uri.path}/#{version['name']}/#{filename}")

        begin
          response = Net::HTTP.get_response(URI(url))
          unless response.is_a?(Net::HTTPSuccess)
            @errors << "URL is NOT reachable (Status: #{response.code}): #{url}. Please check if version/branch exists at source." # rubocop:disable Layout/LineLength
          end
        rescue StandardError => e
          @errors << "Error reaching URL #{url}: #{e.message}"
        end
      end
      progressbar.increment
    end
  end

  # Verify that all required translation keys are present
  def translation_verification(json_data)
    json_data.each do |pipeline_key, pipeline_hash|
      overrides = pipeline_hash['overrides'] || {}
      # entry level overrides
      check_for_missing_translations(overrides, pipeline_key) unless overrides.nil?
      pipeline_hash['versions'].each do |version|
        overrides = version.key?('overrides') ? version['overrides'] : {}
        # version level overrides
        check_for_missing_translations(overrides, pipeline_key, version) unless overrides.nil?
      end
    end
  end

  def check_for_missing_translations(overrides, pipeline_key, version = nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    definitions = overrides['definitions'] || {}
    definitions.each do |key, definition|
      if definition.key?('title') && definition['title'].is_a?(Hash)
        add_missing_definition_translation_error(key, pipeline_key, definition, 'title', version)
      end

      if definition.key?('description') && definition['description'].is_a?(Hash)
        add_missing_definition_translation_error(key, pipeline_key, definition, 'description', version)
      end

      properties = definition['properties'] || {}
      add_missing_definition_property_translation_error(key, pipeline_key, properties, version) unless properties.empty?
    end
  end

  def add_missing_definition_translation_error(key, pipeline_key, definition, definition_key, version = nil)
    missing_keys = @required_translation_keys - definition[definition_key].keys

    return if missing_keys.empty?

    if version.nil?
      @errors << "Missing translation keys #{missing_keys.join(', ')} in #{key} #{definition_key} for pipeline: #{pipeline_key}" # rubocop:disable Layout/LineLength
    else
      @errors << "Missing translation keys #{missing_keys.join(', ')} in #{key} #{definition_key} for pipeline: #{pipeline_key}, version: #{version['name']}" # rubocop:disable Layout/LineLength
    end
  end

  def add_missing_definition_property_translation_error(key, pipeline_key, properties, version = nil)
    properties.each do |prop_key, property|
      next unless property.is_a?(Hash)

      next unless property.key?('description') && property['description'].is_a?(Hash)

      missing_keys = @required_translation_keys - property['description'].keys
      unless missing_keys.empty?
        if version.nil?
          @errors << "Missing translation keys #{missing_keys.join(', ')} in definition #{key} property #{prop_key} description for pipeline: #{pipeline_key}" # rubocop:disable Layout/LineLength
        else
          @errors << "Missing translation keys #{missing_keys.join(', ')} in definition #{key} property #{prop_key} description for pipeline: #{pipeline_key}, version: #{version['name']}" # rubocop:disable Layout/LineLength
        end
      end
    end
  end

  # Output the validation results
  def output_validation_results
    if @errors.empty?
      puts 'JSON file is valid.'
    else
      @errors.each do |error|
        puts error
      end
    end
  end
end
