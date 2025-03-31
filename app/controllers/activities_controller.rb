# frozen_string_literal: true

# Controller actions for activities
class ActivitiesController < ApplicationController
  respond_to :turbo_stream
  before_action :activity

  def show
    render dialog_component_type.new(@activity)
  end

  protected

  def activity
    @activity ||= PublicActivity::Activity.find_by(id: params[:id])
  end

  def dialog_component_type
    type = params[:dialog_type]

    case type
    when 'samples_transfer'
      Activities::Dialogs::SampleTransferActivityDialogComponent
    when 'samples_clone'
      Activities::Dialogs::SampleCloneActivityDialogComponent
    when 'samples_destroy'
      Activities::Dialogs::SampleDestroyActivityDialogComponent
    end
  end
end
