# frozen_string_literal: true

#
# Rake task to validate JSON files against a JSON schema
namespace :pipeline_json_validator do # rubocop:disable Metrics/BlockLength
  @errors = []

  desc 'Validate JSON files against a JSON schema'
  task validate: :environment do
    puts 'Please enter path to pipelines json file to validate:'
    json_file_path_input = $stdin.gets.chomp
    json_file_path = Rails.root.join(json_file_path_input)
    json_data = JSON.parse(File.read(json_file_path))

    puts "Validating JSON file at: #{json_file_path_input} against the schema..."
    validate_schema(json_data)

    puts 'Verifying singular version entries and URL reachability...'
    verify_singular_version_entry(json_data)
    verify_url_reachable(json_data)

    puts 'Displaying validation results...'
    output_validation_results

    exit(@errors.empty? ? 0 : 1)
  end

  def validate_schema(json_data)
    schema_path = Rails.root.join('config/schemas/pipelines_schema.json')
    schema = JSON.parse(File.read(schema_path))

    # Validate pipeline json against schema
    schemer = JSONSchemer.schema(schema)
    result = schemer.validate(json_data).to_a

    unless result.empty?
      @errors << 'JSON file is NOT valid according to the schema'
      # @errors << result

      result.each do |res|
        @errors << "Error: #{res['error']}"
        @errors << "Error Details: #{res['details']}:"
      end
    end

    json_data
  end

  def verify_singular_version_entry(json_data)
    json_data.each do |pipeline_key, pipeline_hash|
      duplicate_pipeline_versions = pipeline_hash['versions'].map { |v| v['name'] }
      counts = duplicate_pipeline_versions.tally
      duplicates_with_counts = counts.select { |_version, count| count > 1 }
      only_duplicates = duplicates_with_counts.keys

      @errors << "Duplicate pipeline versions [#{only_duplicates.join(', ')}] found for pipeline: #{pipeline_key}"
    end
  end

  def verify_url_reachable(json_data) # rubocop:disable Metrics/MethodLength
    json_data.each do |pipeline_key, pipeline_hash|
      base_url = pipeline_hash['url']

      pipeline_hash['versions'].each do |version|
        url = base_url
        if version.key?('name')
          url = "#{url}/tree/#{version['name']}"
          begin
            response = Net::HTTP.get_response(URI(url))
            unless response.is_a?(Net::HTTPSuccess)
              @errors << "URL is NOT reachable (Status: #{response.code}): #{url}. Please check if version/branch exists at source." # rubocop:disable Layout/LineLength
            end
          rescue StandardError => e
            @errors << "Error reaching URL #{url}: #{e.message}"
          end
        else
          @errors << "No URL found for pipeline: #{pipeline_key} version: #{version}"
        end
      end
    end
  end

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
