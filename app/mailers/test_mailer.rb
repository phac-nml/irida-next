# frozen_string_literal: true

# Test Mailer
class TestMailer < ApplicationMailer
  def test_email
    @user = params[:user]
    mail(to: @user.email, subject: 'TEST')
  end
end
