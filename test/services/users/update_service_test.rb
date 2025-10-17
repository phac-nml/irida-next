# frozen_string_literal: true

require 'test_helper'

module Users
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'update user params' do
      params = { email: 'newemail@email.com', first_name: 'new_first_name', last_name: 'new_last_name' }

      assert_changes lambda {
        [@user.email, @user.first_name, @user.last_name]
      }, to: %w[newemail@email.com new_first_name new_last_name] do
        Users::UpdateService.new(@user, @user, params).execute
      end
    end
  end
end
