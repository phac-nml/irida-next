# frozen_string_literal: true

# Application Mailer
class ApplicationMailer < ActionMailer::Base
  prepend_view_path Rails.root.join('app/views/mailers')
  default from: 'from@example.com'
  layout 'mailer'
end
