# frozen_string_literal: true

# FixtureBot recompiles test/fixtures/**/*.rb into test/fixtures/**/*.yml on every test
# run (triggered by `require "fixturebot/minitest"`). A relative time value computed at
# *compile* time (e.g. `3.hours.ago`) would therefore bake in a different literal value
# every run, making the compiled, git-tracked YAML change (and show up as a dirty
# working tree) every time someone runs the tests.
#
# To avoid this while still preserving real relative-time behaviour (e.g. "this token
# expires 10 days from now"), fixture files set timestamp columns that need to track
# real time to a *literal string containing an ERB tag* (e.g.
# `expires_at '<%= 10.days.from_now.to_date %>'`), instead of computing the value in the
# DSL. FixtureBot writes that literal text as-is into the compiled YAML (so the compiled
# file itself never changes), and Rails' standard fixture loader evaluates the ERB fresh
# every time fixtures are loaded for a test run -- exactly like the hand-written YAML
# fixtures did before this migration.
#
# Timestamp columns that were previously just `Time.zone.now` (i.e. "whenever this
# fixture happens to be created") are omitted entirely instead, since Rails' fixture
# loader automatically fills unset `created_at`/`updated_at` columns with the current
# time.

FixtureBot.require 'test/fixtures/**/*.rb'
