# frozen_string_literal: true

require 'test_helper'

module Versioning
  class VersionResolverTest < ActiveSupport::TestCase
    test 'resolves explicit version when valid' do
      version = VersionResolver.resolve(
        version: :v2,
        valid_versions: %i[v1 v2],
        default_version: :v1
      )

      assert_equal :v2, version
    end

    test 'resolves computed default when version is nil' do
      version = VersionResolver.resolve(
        version: nil,
        valid_versions: %i[v1 v2],
        default_version: :v1
      ) { :v2 }

      assert_equal :v2, version
    end

    test 'raises on invalid explicit version' do
      assert_raises(ArgumentError) do
        VersionResolver.resolve(
          version: :v3,
          valid_versions: %i[v1 v2],
          default_version: :v1
        )
      end
    end

    test 'raises when default version is outside valid versions' do
      assert_raises(ArgumentError) do
        VersionResolver.resolve(
          version: nil,
          valid_versions: %i[v1 v2],
          default_version: :v3
        )
      end
    end
  end
end
