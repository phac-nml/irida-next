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
        assert_equal success_text, state.fetch('text')
        assert_empty state.fetch('ariaValueNow')
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

        assert_equal success_text, state_a.fetch('text')
        assert_equal success_text, state_b.fetch('text')
        assert_empty state_a.fetch('ariaValueNow')
        assert_empty state_b.fetch('ariaValueNow')
        assert_includes state_a.fetch('rowClass'), 'direct-upload--complete'
        assert_includes state_b.fetch('rowClass'), 'direct-upload--complete'
      end

      test 'error upload row stays in error state and is not marked complete' do
        open_upload_dialog

        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('start', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('progress', { id: 301, file: { name: 'bad.fastq.gz' }, progress: 55 })
        inject_direct_upload_hidden_input('signed-id-before-error')
        assert_equal 1, hidden_direct_upload_input_count
        dispatch_upload_event('error', { id: 301, file: { name: 'bad.fastq.gz' }, error: 'forced upload failure' })
        dispatch_upload_event('end', { id: 301, file: { name: 'bad.fastq.gz' } })
        dispatch_form_upload_event('end')

        state = upload_state(301)
        input_state = upload_input_state
        upload_alert_state = upload_error_alert_state

        # Error shows descriptive message, progress bar hidden
        assert_equal error_text, state.fetch('text')
        assert_empty state.fetch('ariaValueNow')
        assert_includes state.fetch('rowClass'), 'direct-upload--error'
        assert_not_includes state.fetch('rowClass'), 'direct-upload--complete'
        assert_equal 'true', input_state.fetch('ariaInvalid')
        assert_equal false, upload_alert_state.fetch('hidden')
        assert_includes upload_alert_state.fetch('text'), retry_upload_text
        assert_equal 0, hidden_direct_upload_input_count
      end

      test 'server submit error keeps completed uploads and does not require re-upload' do
        open_upload_dialog

        assign_upload_input_files(['single.fastq.gz'])
        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 601, file: { name: 'single.fastq.gz' } })
        dispatch_upload_event('start', { id: 601, file: { name: 'single.fastq.gz' } })
        dispatch_upload_event('progress', { id: 601, file: { name: 'single.fastq.gz' }, progress: 90 })
        inject_direct_upload_hidden_input('signed-id-success')
        dispatch_upload_event('end', { id: 601, file: { name: 'single.fastq.gz' } })
        dispatch_form_upload_event('end')

        assert_equal 1, hidden_direct_upload_input_count
        assert_equal 0, upload_input_file_count

        dispatch_turbo_submit_end(false)
        form_alert_state = form_error_alert_state

        assert_equal false, form_alert_state.fetch('hidden')
        assert_includes form_alert_state.fetch('text'), form_submit_failed_text
        assert_equal 1, hidden_direct_upload_input_count
        assert_equal 0, upload_input_file_count
      end

      test 'partial batch preserves hidden input for successful upload when another fails' do
        open_upload_dialog

        assign_upload_input_files(['good.fastq.gz', 'bad.fastq.gz'])
        dispatch_form_upload_event('start')
        dispatch_upload_event('initialize', { id: 701, file: { name: 'good.fastq.gz' } })
        dispatch_upload_event('initialize', { id: 702, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('start', { id: 701, file: { name: 'good.fastq.gz' } })
        dispatch_upload_event('progress', { id: 701, file: { name: 'good.fastq.gz' }, progress: 90 })
        inject_direct_upload_hidden_input('signed-id-good')
        dispatch_upload_event('end', { id: 701, file: { name: 'good.fastq.gz' } })
        dispatch_upload_event('start', { id: 702, file: { name: 'bad.fastq.gz' } })
        dispatch_upload_event('error', { id: 702, file: { name: 'bad.fastq.gz' }, error: 'forced failure' })
        dispatch_upload_event('end', { id: 702, file: { name: 'bad.fastq.gz' } })
        dispatch_form_upload_event('end')

        good_state = upload_state(701)
        bad_state = upload_state(702)
        alert_state = upload_error_alert_state

        # Successful upload row stays complete
        assert_equal success_text, good_state.fetch('text')
        assert_includes good_state.fetch('rowClass'), 'direct-upload--complete'

        # Failed upload row shows error
        assert_equal error_text, bad_state.fetch('text')
        assert_includes bad_state.fetch('rowClass'), 'direct-upload--error'

        # Hidden input for the successful upload is preserved for form re-submit
        assert_equal 1, hidden_direct_upload_input_count
        assert_equal 1, upload_input_file_count

        # Error alert is shown
        assert_equal false, alert_state.fetch('hidden')
        assert_includes alert_state.fetch('text'), retry_upload_text
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

        assert_equal success_text, retry_state.fetch('text')
        assert_empty retry_state.fetch('ariaValueNow')
        assert_includes retry_state.fetch('rowClass'), 'direct-upload--complete'

        assert_not_includes previous_error_state.fetch('rowClass'), 'direct-upload--complete'
        assert_equal error_text, previous_error_state.fetch('text')
        assert_not_includes previous_pending_state.fetch('rowClass'), 'direct-upload--complete'
        assert_includes previous_pending_state.fetch('rowClass'), 'direct-upload--error'
        assert_equal error_text, previous_pending_state.fetch('text')
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
              ariaValueNow: bar?.getAttribute("aria-valuenow") || "",
              text: text?.textContent?.trim() || null,
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

      def inject_direct_upload_hidden_input(value)
        page.execute_script(<<~JS)
          (() => {
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            const hidden = document.createElement("input");
            hidden.type = "hidden";
            hidden.name = input.name;
            hidden.value = #{value.to_json};
            input.insertAdjacentElement("beforebegin", hidden);
          })();
        JS
      end

      def hidden_direct_upload_input_count
        page.evaluate_script(<<~JS)
          (() => {
            const form = document.querySelector("dialog[open] form");
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            const hiddenInputs = form?.querySelectorAll("input[type='hidden']") || [];
            return Array.from(hiddenInputs).filter((hiddenInput) => {
              return hiddenInput.name === input?.name && hiddenInput.value !== "";
            }).length;
          })();
        JS
      end

      def upload_input_file_count
        page.evaluate_script(<<~JS)
          (() => {
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            return input?.files?.length || 0;
          })();
        JS
      end

      def upload_error_alert_state
        page.evaluate_script(<<~JS)
          (() => {
            const alert = document.querySelector(
              "dialog[open] [data-attachment-upload-target='uploadErrorAlert']",
            );
            return {
              hidden: alert?.classList.contains("hidden"),
              text: alert?.textContent?.trim() || null,
            };
          })();
        JS
      end

      def form_error_alert_state
        page.evaluate_script(<<~JS)
          (() => {
            const alert = document.querySelector(
              "dialog[open] [data-attachment-upload-target='formErrorAlert']",
            );
            return {
              hidden: alert?.classList.contains("hidden"),
              text: alert?.textContent?.trim() || null,
            };
          })();
        JS
      end

      def assign_upload_input_files(filenames)
        page.execute_script(<<~JS)
          (() => {
            const input = document.querySelector(
              "dialog[open] input[data-attachment-upload-target='attachmentsInput']",
            );
            const dataTransfer = new DataTransfer();
            #{filenames.to_json}.forEach((filename) => {
              dataTransfer.items.add(new File(["test"], filename, { type: "application/octet-stream" }));
            });
            input.files = dataTransfer.files;
          })();
        JS
      end

      def dispatch_turbo_submit_end(success)
        page.execute_script(<<~JS)
          (() => {
            const form = document.querySelector("dialog[open] form");
            form.dispatchEvent(
              new CustomEvent("turbo:submit-end", {
                bubbles: true,
                detail: { success: #{success} },
              }),
            );
          })();
        JS
      end

      def success_text
        I18n.t('common.upload.uploaded_successfully')
      end

      def error_text
        I18n.t('common.upload.failed')
      end

      def retry_upload_text
        I18n.t('common.upload.upload_failed_retry')
      end

      def form_submit_failed_text
        I18n.t('common.upload.form_submit_failed')
      end
    end
  end
end
