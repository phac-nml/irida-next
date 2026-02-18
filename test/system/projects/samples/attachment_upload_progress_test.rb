# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class AttachmentUploadProgressTest < ApplicationSystemTestCase
      setup do
        Flipper.enable(:sample_attachments_searching)
        @user = users(:john_doe)
        login_as @user
        @sample = samples(:sample2)
        @project = projects(:project1)
        @namespace = groups(:group_one)
      end

      test 'single upload reaches 100 percent on end event' do
        open_upload_dialog

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 101, file: { name: 'single.fastq.gz' } })
        dispatch_upload_event('start', { id: 101, file: { name: 'single.fastq.gz' } })
        dispatch_upload_event('progress', { id: 101, file: { name: 'single.fastq.gz' }, progress: 90 })
        dispatch_upload_event('end', { id: 101, file: { name: 'single.fastq.gz' } })
        dispatch_form_upload_event('end')

        state = upload_state(101)
        assert_equal '100%', state.fetch('text')
        assert_equal '100', state.fetch('ariaValueNow')
        assert_includes state.fetch('rowClass'), 'direct-upload--complete'
      end

      test 'interleaved multi upload reaches 100 percent per row' do
        open_upload_dialog

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 201, file: { name: 'first.fastq.gz' } })
        dispatch_upload_event('initialize', { id: 202, file: { name: 'second.fastq.gz' } })
        dispatch_upload_event('start', { id: 201, file: { name: 'first.fastq.gz' } })
        dispatch_upload_event('progress', { id: 201, file: { name: 'first.fastq.gz' }, progress: 90 })
        dispatch_upload_event('start', { id: 202, file: { name: 'second.fastq.gz' } })
        dispatch_upload_event('progress', { id: 202, file: { name: 'second.fastq.gz' }, progress: 35 })
        dispatch_upload_event('end', { id: 201, file: { name: 'first.fastq.gz' } })
        dispatch_upload_event('progress', { id: 202, file: { name: 'second.fastq.gz' }, progress: 92 })
        dispatch_upload_event('end', { id: 202, file: { name: 'second.fastq.gz' } })
        dispatch_form_upload_event('end')

        state_a = upload_state(201)
        state_b = upload_state(202)

        assert_equal '100%', state_a.fetch('text')
        assert_equal '100%', state_b.fetch('text')
        assert_equal '100', state_a.fetch('ariaValueNow')
        assert_equal '100', state_b.fetch('ariaValueNow')
        assert_includes state_a.fetch('rowClass'), 'direct-upload--complete'
        assert_includes state_b.fetch('rowClass'), 'direct-upload--complete'
      end

      test 'error upload row stays in error state and is not marked complete' do
        open_upload_dialog

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('start', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('progress', { id: 301, file: { name: 'bad.fastq.gz' }, progress: 55 })
        dispatch_upload_event('error', { id: 301, file: { name: 'bad.fastq.gz' }, error: 'forced upload failure' })
        dispatch_upload_event('end', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_form_upload_event('end')

        state = upload_state(301)
        input_state = upload_input_state

        assert_equal '55%', state.fetch('text')
        assert_equal '55', state.fetch('ariaValueNow')
        assert_includes state.fetch('rowClass'), 'direct-upload--error'
        assert_not_includes state.fetch('rowClass'), 'direct-upload--complete'
        assert_equal 'true', input_state.fetch('ariaInvalid')
      end

      test 'failed batch rows are not marked complete after a later successful batch' do
        open_upload_dialog

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 401, file: { name: 'error.fastq.gz' } })
        dispatch_upload_event('initialize', { id: 402, file: { name: 'never-started.fastq.gz' } })
        dispatch_upload_event('start', { id: 401, file: { name: 'error.fastq.gz' } })
        dispatch_upload_event('progress', { id: 401, file: { name: 'error.fastq.gz' }, progress: 44 })
        dispatch_upload_event('error', { id: 401, file: { name: 'error.fastq.gz' }, error: 'forced upload failure' })
        dispatch_upload_event('end', { id: 401, file: { name: 'error.fastq.gz' } })
        dispatch_form_upload_event('end')

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 501, file: { name: 'retry.fastq.gz' } })
        dispatch_upload_event('start', { id: 501, file: { name: 'retry.fastq.gz' } })
        dispatch_upload_event('progress', { id: 501, file: { name: 'retry.fastq.gz' }, progress: 87 })
        dispatch_upload_event('end', { id: 501, file: { name: 'retry.fastq.gz' } })
        dispatch_form_upload_event('end')

        retry_state = upload_state(501)
        previous_error_state = upload_state(401)
        previous_pending_state = upload_state(402)

        assert_equal '100%', retry_state.fetch('text')
        assert_equal '100', retry_state.fetch('ariaValueNow')
        assert_includes retry_state.fetch('rowClass'), 'direct-upload--complete'

        assert_not_includes previous_error_state.fetch('rowClass'), 'direct-upload--complete'
        assert_not_includes previous_pending_state.fetch('rowClass'), 'direct-upload--complete'
        assert_equal '0%', previous_pending_state.fetch('text')
      end

      private

      def open_upload_dialog
        visit namespace_project_sample_url(@namespace, @project, @sample)
        click_on I18n.t('projects.samples.show.upload_files'), match: :first
        assert_selector 'dialog[open] input[data-attachment-upload-target="attachmentsInput"]'
      end

      def dispatch_form_upload_event(name)
        page.execute_script(<<~JS)
          (() => {
            const form = document.querySelector("dialog[open] form");
            form.dispatchEvent(new CustomEvent("direct-uploads:#{name}", { bubbles: true }));
          })();
        JS
      end

      def dispatch_upload_event(name, detail)
        page.execute_script(<<~JS)
          (() => {
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            input.dispatchEvent(
              new CustomEvent("direct-upload:#{name}", {
                bubbles: true,
                detail: #{detail.to_json},
              }),
            );
          })();
        JS
      end

      def upload_state(id)
        page.evaluate_script(<<~JS)
          (() => {
            const row = document.getElementById("direct-upload-#{id}");
            const bar = document.getElementById("direct-upload-progress-#{id}");
            const text = document.getElementById("upload-progress-#{id}");
            return {
              rowClass: row?.className,
              ariaValueNow: bar?.getAttribute("aria-valuenow"),
              text: text?.textContent,
            };
          })();
        JS
      end

      def upload_input_state
        page.evaluate_script(<<~JS)
          (() => {
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            return {
              ariaInvalid: input?.getAttribute("aria-invalid"),
            };
          })();
        JS
      end
    end
  end
end
