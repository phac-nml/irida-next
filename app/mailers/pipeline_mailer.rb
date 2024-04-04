# frozen_string_literal: true

# Pipeline Mailer
class PipelineMailer < ApplicationMailer
  def complete_email
    @user = params[:user]
    mail(to: @user.email, subject: 'Pipeline completed')
  end

  def error_email
    @user = params[:user]
    mail(to: @user.email, subject: 'Pipeline errored')
  end
end
