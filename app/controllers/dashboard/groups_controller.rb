# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    def index
      @groups = authorized_scope(Group, type: :relation).order(updated_at: :desc)
    end
  end
end
