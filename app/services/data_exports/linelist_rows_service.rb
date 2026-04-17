# frozen_string_literal: true

module DataExports
  # Builds linelist spreadsheet rows using the same GraphQL-shaped sample field
  # contract as the client-side linelist export worker (PR #1636).
  #
  # Returns an Array of Arrays: the first element is the header row, followed by
  # one data row per sample in the order of +sample_ids+.
  #
  # Fields per row: SAMPLE PUID, SAMPLE NAME, PROJECT PUID, then one column per
  # requested metadata field (uppercased), with blank strings for absent keys.
  class LinelistRowsService
    LINELIST_SAMPLES_QUERY = <<~GRAPHQL
      query LinelistSamples($ids: [ID!]!, $metadataKeys: [String!]) {
        nodes(ids: $ids) {
          id
          __typename
          ... on Sample {
            puid
            name
            project {
              puid
            }
            metadata(keys: $metadataKeys)
          }
        }
      }
    GRAPHQL

    CHUNK_SIZE = 100

    def self.call(sample_ids:, metadata_fields:, current_user:)
      new(sample_ids:, metadata_fields:, current_user:).call
    end

    def initialize(sample_ids:, metadata_fields:, current_user:)
      @sample_ids = Array(sample_ids)
      @metadata_fields = Array(metadata_fields)
      @current_user = current_user
    end

    def call
      samples_by_gid = fetch_samples_by_gid
      rows = [build_header]

      @sample_ids.each do |id|
        gid = to_global_id(id)
        sample = samples_by_gid[gid]
        rows << build_row(sample)
      end

      rows
    end

    private

    def fetch_samples_by_gid
      gids = @sample_ids.map { |id| to_global_id(id) }
      result = {}

      gids.each_slice(CHUNK_SIZE) do |chunk|
        nodes = execute_query(chunk)
        nodes.each do |node|
          next unless node.is_a?(Hash)
          next unless node['__typename'] == 'Sample' && node['id']

          result[node['id']] = node
        end
      end

      result
    end

    def execute_query(gid_chunk)
      response = IridaSchema.execute(
        LINELIST_SAMPLES_QUERY,
        context: { current_user: @current_user },
        variables: { ids: gid_chunk, metadataKeys: @metadata_fields.presence }
      )

      response.dig('data', 'nodes') || []
    end

    def to_global_id(id)
      return id.to_s if id.to_s.start_with?('gid://')

      Sample.find(id).to_global_id.to_s
    end

    def build_header
      fixed = ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID']
      fixed + @metadata_fields.map { |f| f.to_s.upcase }
    end

    def build_row(sample)
      [
        sample_value(sample, 'puid'),
        sample_value(sample, 'name'),
        project_puid(sample),
        *metadata_values(sample)
      ]
    end

    def sample_value(sample, key)
      sample&.dig(key) || ''
    end

    def project_puid(sample)
      sample&.dig('project', 'puid') || ''
    end

    def metadata_values(sample)
      metadata = sample&.dig('metadata') || {}
      @metadata_fields.map { |field| metadata[field.to_s] || '' }
    end
  end
end
