// Import and register all your controllers with explicit imports
// This replaces the lazy loading approach for better tree-shaking with esbuild

import { application } from "controllers/application";

// Controllers are registered with kebab-case identifiers matching their file paths
// To add a new controller:
// 1. Create the controller file (e.g., my_feature_controller.js)
// 2. Add an import statement below (e.g., import MyFeatureController from "./my_feature_controller")
// 3. Register it with application.register("my-feature", MyFeatureController)

import ActionButtonController from "./action_button_controller";
import ActivitiesExtendedDetailsController from "./activities/extended_details_controller";
import AdvancedSearchController from "./advanced_search_controller";
import AttachmentUploadController from "./attachment_upload_controller";
import BreadcrumbController from "./breadcrumb_controller";
import ClipboardController from "./clipboard_controller";
import CollapsibleController from "./collapsible_controller";
import ColourModeController from "./colour_mode_controller";
import ConfirmationController from "./confirmation_controller";
import CopyController from "./copy_controller";
import EditableCellController from "./editable_cell_controller";
import EmailInputController from "./email_input_controller";
import FileUploadController from "./file_upload_controller";
import FiltersController from "./filters_controller";
import FormHiddenInputsController from "./form/hidden_inputs_controller";
import FormJsonSubmissionController from "./form/json_submission_controller";
import GroupsRowController from "./groups/row_controller";
import InfiniteScrollController from "./infinite_scroll_controller";
import LayoutController from "./layout_controller";
import ListFilterController from "./list_filter_controller";
import MetadataFileImportController from "./metadata/file_import_controller";
import MetadataToggleController from "./metadata_toggle_controller";
import NextflowFileController from "./nextflow/file_controller";
import NextflowMetadataController from "./nextflow/metadata_controller";
import NextflowSamplesheetController from "./nextflow/samplesheet_controller";
import PathogenDatepickerCalendarController from "./pathogen/datepicker/calendar_controller";
import PathogenDatepickerInputController from "./pathogen/datepicker/input_controller";
import PathogenTabsController from "./pathogen/tabs_controller";
import PathogenTooltipController from "./pathogen/tooltip_controller";
import ProjectsSamplesAttachmentsFilesController from "./projects/samples/attachments/files_controller";
import ProjectsSamplesAttachmentsSelectedAttachmentsController from "./projects/samples/attachments/selected_attachments_controller";
import ProjectsSamplesCompleteController from "./projects/samples/complete_controller";
import ProjectsSamplesMetadataCompleteController from "./projects/samples/metadata/complete_controller";
import ProjectsSamplesMetadataCreateController from "./projects/samples/metadata/create_controller";
import ProjectsSamplesMetadataDeleteListingController from "./projects/samples/metadata/delete_listing_controller";
import ProjectsSamplesMetadataDestroyController from "./projects/samples/metadata/destroy_controller";
import RefreshController from "./refresh_controller";
import SearchFieldController from "./search_field_controller";
import SelectionController from "./selection_controller";
import SessionstorageAmendFormController from "./sessionstorage_amend_form_controller";
import SidebarItemController from "./sidebar_item_controller";
import SlugifyController from "./slugify_controller";
import SpinnerController from "./spinner_controller";
import SpreadsheetImportController from "./spreadsheet_import_controller";
import TableController from "./table_controller";
import TableSelectionController from "./table_selection_controller";
import TokenController from "./token_controller";
import TreegridController from "./treegrid_controller";
import ViralAlertController from "./viral/alert_controller";
import ViralDialogController from "./viral/dialog_controller";
import ViralDialogTriggerController from "./viral/dialog_trigger_controller";
import ViralDropdownController from "./viral/dropdown_controller";
import ViralFlashController from "./viral/flash_controller";
import ViralSelect2Controller from "./viral/select2_controller";
import ViralSortableListsListController from "./viral/sortable_lists/list_controller";
import ViralSortableListsTwoListsSelectionController from "./viral/sortable_lists/two_lists_selection_controller";
import WorkflowSelectionController from "./workflow_selection_controller";

// Register all controllers with their kebab-case identifiers
application.register("action-button", ActionButtonController);
application.register("activities--extended-details", ActivitiesExtendedDetailsController);
application.register("advanced-search", AdvancedSearchController);
application.register("attachment-upload", AttachmentUploadController);
application.register("breadcrumb", BreadcrumbController);
application.register("clipboard", ClipboardController);
application.register("collapsible", CollapsibleController);
application.register("colour-mode", ColourModeController);
application.register("confirmation", ConfirmationController);
application.register("copy", CopyController);
application.register("editable-cell", EditableCellController);
application.register("email-input", EmailInputController);
application.register("file-upload", FileUploadController);
application.register("filters", FiltersController);
application.register("form--hidden-inputs", FormHiddenInputsController);
application.register("form--json-submission", FormJsonSubmissionController);
application.register("groups--row", GroupsRowController);
application.register("infinite-scroll", InfiniteScrollController);
application.register("layout", LayoutController);
application.register("list-filter", ListFilterController);
application.register("metadata--file-import", MetadataFileImportController);
application.register("metadata-toggle", MetadataToggleController);
application.register("nextflow--file", NextflowFileController);
application.register("nextflow--metadata", NextflowMetadataController);
application.register("nextflow--samplesheet", NextflowSamplesheetController);
application.register("pathogen--datepicker--calendar", PathogenDatepickerCalendarController);
application.register("pathogen--datepicker--input", PathogenDatepickerInputController);
application.register("pathogen--tabs", PathogenTabsController);
application.register("pathogen--tooltip", PathogenTooltipController);
application.register("projects--samples--attachments--files", ProjectsSamplesAttachmentsFilesController);
application.register("projects--samples--attachments--selected-attachments", ProjectsSamplesAttachmentsSelectedAttachmentsController);
application.register("projects--samples--complete", ProjectsSamplesCompleteController);
application.register("projects--samples--metadata--complete", ProjectsSamplesMetadataCompleteController);
application.register("projects--samples--metadata--create", ProjectsSamplesMetadataCreateController);
application.register("projects--samples--metadata--delete-listing", ProjectsSamplesMetadataDeleteListingController);
application.register("projects--samples--metadata--destroy", ProjectsSamplesMetadataDestroyController);
application.register("refresh", RefreshController);
application.register("search-field", SearchFieldController);
application.register("selection", SelectionController);
application.register("sessionstorage-amend-form", SessionstorageAmendFormController);
application.register("sidebar-item", SidebarItemController);
application.register("slugify", SlugifyController);
application.register("spinner", SpinnerController);
application.register("spreadsheet-import", SpreadsheetImportController);
application.register("table", TableController);
application.register("table-selection", TableSelectionController);
application.register("token", TokenController);
application.register("treegrid", TreegridController);
application.register("viral--alert", ViralAlertController);
application.register("viral--dialog", ViralDialogController);
application.register("viral--dialog-trigger", ViralDialogTriggerController);
application.register("viral--dropdown", ViralDropdownController);
application.register("viral--flash", ViralFlashController);
application.register("viral--select2", ViralSelect2Controller);
application.register("viral--sortable-lists--list", ViralSortableListsListController);
application.register("viral--sortable-lists--two-lists-selection", ViralSortableListsTwoListsSelectionController);
application.register("workflow-selection", WorkflowSelectionController);
