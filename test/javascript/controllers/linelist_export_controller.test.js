import { beforeEach, describe, expect, it, vi } from "vitest";

const downloadExport = vi.fn();
const xlsxRowsToBlob = vi.fn();

class XlsxLibraryLoadError extends Error {}

vi.mock("controllers/linelist_export/downloader", () => ({
  downloadExport,
  xlsxRowsToBlob,
  XlsxLibraryLoadError,
}));

const buildController = async () => {
  const { default: LinelistExportController } =
    await import("controllers/linelist_export_controller");
  const controller = Object.create(LinelistExportController.prototype);
  controller.saveToServerErrorMessageValue = "Upload failed: %{message}";
  controller.xlsxLoadErrorMessageValue = "Unable to load XLSX.";
  controller.downloadStartedMessageValue = "Download started: %{filename}";
  controller.updateProgress = vi.fn();
  controller.showUploadActions = vi.fn();
  controller.scheduleProgressWindowDismiss = vi.fn();
  controller.hideUploadLink = vi.fn();
  controller.hideUploadActions = vi.fn();
  controller.graphqlUrl = vi.fn(() => "/-/graphql");
  controller.csrfToken = vi.fn(() => "token");
  controller.workerClient = { start: vi.fn(), stop: vi.fn() };
  return controller;
};

describe("linelist_export_controller", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("keeps original XLSX rows for local download after upload fails with a Blob payload", async () => {
    const controller = await buildController();
    const rowsPayload = {
      filename: "linelist.xlsx",
      format: "xlsx",
      content: [["SAMPLE PUID"], ["INXT_SAM_1"]],
    };
    controller._lastCompletedPayload = rowsPayload;

    controller.handleWorkerUploadError({
      filename: "linelist.xlsx",
      format: "xlsx",
      content: new Blob(["uploaded bytes"]),
      message: "network failed",
    });
    await controller.downloadLocalFallback();

    expect(controller._lastCompletedPayload).toBe(rowsPayload);
    expect(downloadExport).toHaveBeenCalledWith(
      "linelist.xlsx",
      rowsPayload.content,
      "xlsx",
    );
  });

  it("retries XLSX upload by converting saved rows to a Blob when no upload payload exists", async () => {
    const controller = await buildController();
    const rowsPayload = {
      filename: "linelist.xlsx",
      format: "xlsx",
      content: [["SAMPLE PUID"], ["INXT_SAM_1"]],
    };
    const blob = new Blob(["xlsx bytes"], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
    controller._lastCompletedPayload = rowsPayload;
    controller._lastUploadPayload = null;
    xlsxRowsToBlob.mockResolvedValue(blob);
    vi.spyOn(controller, "handleServerSave");

    await controller.retryUpload();

    expect(xlsxRowsToBlob).toHaveBeenCalledWith(rowsPayload.content);
    expect(controller.handleServerSave).toHaveBeenCalledWith({
      ...rowsPayload,
      content: blob,
    });
  });

  it("retries with the existing upload Blob after an XLSX upload request fails", async () => {
    const controller = await buildController();
    const rowsPayload = {
      filename: "linelist.xlsx",
      format: "xlsx",
      content: [["SAMPLE PUID"], ["INXT_SAM_1"]],
    };
    const uploadPayload = {
      filename: "linelist.xlsx",
      format: "xlsx",
      content: new Blob(["xlsx bytes"]),
    };
    controller._lastCompletedPayload = rowsPayload;
    controller._lastUploadPayload = uploadPayload;
    vi.spyOn(controller, "handleServerSave");

    await controller.retryUpload();

    expect(xlsxRowsToBlob).not.toHaveBeenCalled();
    expect(controller.handleServerSave).toHaveBeenCalledWith(uploadPayload);
  });

  it("keeps retry actions visible when XLSX conversion fails during retry", async () => {
    const controller = await buildController();
    controller._lastCompletedPayload = {
      filename: "linelist.xlsx",
      format: "xlsx",
      content: [["SAMPLE PUID"], ["INXT_SAM_1"]],
    };
    xlsxRowsToBlob.mockRejectedValue(new XlsxLibraryLoadError());

    await controller.retryUpload();

    expect(controller.updateProgress).toHaveBeenCalledWith(
      "Unable to load XLSX.",
      100,
      true,
    );
    expect(controller.showUploadActions).toHaveBeenCalledOnce();
  });
});
