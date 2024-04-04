# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/pipeline_mailer
class PipelineMailerPreview < ActionMailer::Preview
  def complete_email
    PipelineMailer.with(user: User.first).complete_email
  end

  def error_email
    PipelineMailer.with(user: User.first).error_email
  end
end
