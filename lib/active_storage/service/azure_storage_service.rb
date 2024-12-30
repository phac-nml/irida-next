# frozen_string_literal: true

gem 'azure-blob'

require 'active_support/core_ext/numeric/bytes'
require 'azure/storage/blob'
require 'azure/storage/common/core/auth/shared_access_signature'

module ActiveStorage
  # = Active Storage \Azure Storage \Service
  #
  # Wraps the Microsoft Azure Storage Blob Service as an Active Storage service.
  # See ActiveStorage::Service for the generic API documentation that applies to all services.
  class Service::AzureStorageService < Service
    attr_reader :client, :container, :signer

    def initialize(storage_account_name:, storage_access_key:, container:, public: false, **)
      @client = Azure::Storage::Blob::BlobService.create(storage_account_name:,
                                                         storage_access_key:, **)
      @signer = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(storage_account_name, storage_access_key)
      @container = container
      @public = public
    end

    def upload(key, io, checksum: nil, filename: nil, content_type: nil, disposition: nil, custom_metadata: {}, **)
      instrument(:upload, key:, checksum:) do
        handle_errors do
          if disposition && filename
            content_disposition = content_disposition_with(filename:,
                                                           type: disposition)
          end

          client.create_block_blob(container, key, IO.try_convert(io) || io, content_md5: checksum,
                                                                             content_type:, content_disposition:, metadata: custom_metadata)
        end
      end
    end

    def download(key, &)
      if block_given?
        instrument(:streaming_download, key:) do
          stream(key, &)
        end
      else
        instrument(:download, key:) do
          handle_errors do
            _, io = client.get_blob(container, key)
            io.force_encoding(Encoding::BINARY)
          end
        end
      end
    end

    def download_chunk(key, range)
      instrument(:download_chunk, key:, range:) do
        handle_errors do
          _, io = client.get_blob(container, key, start_range: range.begin,
                                                  end_range: range.exclude_end? ? range.end - 1 : range.end)
          io.force_encoding(Encoding::BINARY)
        end
      end
    end

    def delete(key)
      instrument(:delete, key:) do
        client.delete_blob(container, key)
      rescue Azure::Core::Http::HTTPError => e
        raise unless e.type == 'BlobNotFound'
        # Ignore files already deleted
      end
    end

    def delete_prefixed(prefix)
      instrument(:delete_prefixed, prefix:) do
        marker = nil

        loop do
          results = client.list_blobs(container, prefix:, marker:)

          results.each do |blob|
            client.delete_blob(container, blob.name)
          end

          break unless marker = results.continuation_token.presence
        end
      end
    end

    def exist?(key)
      instrument(:exist, key:) do |payload|
        answer = blob_for(key).present?
        payload[:exist] = answer
        answer
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument(:url, key:) do |payload|
        generated_url = signer.signed_uri(
          uri_for(key), false,
          service: 'b',
          permissions: 'rw',
          expiry: format_expiry(expires_in)
        ).to_s

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(_key, content_type:, checksum:, filename: nil, disposition: nil, custom_metadata: {},
                                  **)
      content_disposition = content_disposition_with(type: disposition, filename:) if filename

      { 'Content-Type' => content_type, 'Content-MD5' => checksum,
        'x-ms-blob-content-disposition' => content_disposition, 'x-ms-blob-type' => 'BlockBlob', **custom_metadata_headers(custom_metadata) }
    end

    def compose(source_keys, destination_key, filename: nil, content_type: nil, disposition: nil, custom_metadata: {})
      content_disposition = content_disposition_with(type: disposition, filename:) if disposition && filename

      client.create_append_blob(
        container,
        destination_key,
        content_type:,
        content_disposition:,
        metadata: custom_metadata
      ).tap do |blob|
        source_keys.each do |source_key|
          stream(source_key) do |chunk|
            client.append_blob_block(container, blob.name, chunk)
          end
        end
      end
    end

    private

    def private_url(key, expires_in:, filename:, disposition:, content_type:, **)
      signer.signed_uri(
        uri_for(key), false,
        service: 'b',
        permissions: 'r',
        expiry: format_expiry(expires_in),
        content_disposition: content_disposition_with(type: disposition, filename:),
        content_type:
      ).to_s
    end

    def public_url(key, **)
      uri_for(key).to_s
    end

    def uri_for(key)
      client.generate_uri("#{container}/#{key}")
    end

    def blob_for(key)
      client.get_blob_properties(container, key)
    rescue Azure::Core::Http::HTTPError
      false
    end

    def format_expiry(expires_in)
      expires_in ? Time.now.utc.advance(seconds: expires_in).iso8601 : nil
    end

    # Reads the object for the given key in chunks, yielding each to the block.
    def stream(key)
      blob = blob_for(key)

      chunk_size = 4.megabytes
      offset = 0

      raise ActiveStorage::FileNotFoundError unless blob.present?

      while offset < blob.properties[:content_length]
        _, chunk = client.get_blob(container, key, start_range: offset, end_range: offset + chunk_size - 1)
        yield chunk.force_encoding(Encoding::BINARY)
        offset += chunk_size
      end
    end

    def handle_errors
      yield
    rescue Azure::Core::Http::HTTPError => e
      case e.type
      when 'BlobNotFound'
        raise ActiveStorage::FileNotFoundError
      when 'Md5Mismatch'
        raise ActiveStorage::IntegrityError
      else
        raise
      end
    end

    def custom_metadata_headers(metadata)
      metadata.transform_keys { |key| "x-ms-meta-#{key}" }
    end
  end
end
