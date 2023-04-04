# frozen_string_literal: true

mount Lookbook::Engine, at: '/lookbook' if Rails.env.development?
