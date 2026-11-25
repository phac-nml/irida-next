# frozen_string_literal: true

require 'test_helper'

module EntraId
  class ScopedTokenTest < ActiveSupport::TestCase
    test 'active? is always true' do
      token = ScopedToken.new({ 'scp' => 'access_as_user' })

      assert token.active?
    end

    test 'integration? is always true so last-used-ip tracking is skipped' do
      token = ScopedToken.new({ 'scp' => 'access_as_user' })

      assert token.integration?
    end

    test 'scopes includes only known IRIDA Next API scopes from the scp claim' do
      token = ScopedToken.new({ 'scp' => 'access_as_user api read_api some_other_scope' })

      assert_equal %w[api read_api], token.scopes
    end

    test 'scopes is empty when the scp claim only grants access_as_user' do
      token = ScopedToken.new({ 'scp' => 'access_as_user' })

      assert_empty token.scopes
    end

    test 'scopes is empty when the scp claim is missing' do
      token = ScopedToken.new({})

      assert_empty token.scopes
    end
  end
end
