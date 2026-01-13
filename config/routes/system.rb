# frozen_string_literal: true

scope '-' do
  scope 'system' do
    authenticate :user, ->(user) { user.system? } do
      mount GoodJob::Engine => 'good_job'
    end
  end
end
