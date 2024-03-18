# frozen_string_literal: true

# Application Mailer
class ApplicationMailer < ActionMailer::Base
  append_view_path Rails.root.join('app/views/mailers')
  default from: email_address_with_name('irida_next@test.com', 'IRIDA Next')
  layout 'mailer'
end
