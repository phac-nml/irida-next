# frozen_string_literal: true

# Controller actions for activities
class ActivitiesController < ApplicationController
  respond_to :turbo_stream
  before_action :activity

  def show
    render dialog_component_type.new(activity: @activity, activity_owner: @activity_owner)
  end

  protected

  def activity
    @activity ||= PublicActivity::Activity.find_by(id: params[:id])
    @activity_owner = activity_owner
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

  def activity_owner
    return @activity.owner.email unless @activity.owner.nil?

    if activity_owner.deleted?
      user = User.find_by(id: @activity.owner_id)
      return user.email unless user.nil?
    end

    I18n.t('activerecord.concerns.track_activity.system')
  end
end
