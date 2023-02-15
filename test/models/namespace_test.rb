# frozen_string_literal: true

require 'test_helper'

class NamespaceTest < ActiveSupport::TestCase
  test "cannot create with nil type" do
    namespace = Namespace.new(name: 'base', path: 'base')
    assert_not namespace.valid?, 'namespace is valid without a type'
    assert_not_nil namespace.errors[:type], 'no validation error for type present'
  end
end
