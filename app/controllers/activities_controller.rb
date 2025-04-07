# frozen_string_literal: true

# Controller actions for activities
class ActivitiesController < ApplicationController
  respond_to :turbo_stream
  before_action :activity
  before_action :activity_owner

  def show
    authorize! trackable, to: :read?

    dialog_component = dialog_component_type
    if dialog_component
      render dialog_component.new(activity: @activity, activity_owner: @activity_owner)
    else
      handle_not_found
    end
  end

  protected

  def handle_not_found
    redirect_back fallback_location: request.referer || root_path,
                  alert: I18n.t('activities.show.error')
  end

  def activity
    @activity ||= PublicActivity::Activity.find_by(id: params[:id])
  end

  def activity_owner
    @activity_owner = @activity.owner.email unless @activity.owner.nil?

    unless @activity.owner_id.nil?
      user = User.only_deleted.find_by(id: @activity.owner_id)
      @activity_owner = user.email unless user.nil?
    end

    @activity_owner ||= I18n.t('activerecord.concerns.track_activity.system')
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

  def trackable
    return @activity.trackable if @activity.trackable.group_namespace?

    @activity.trackable.project
  end
end
