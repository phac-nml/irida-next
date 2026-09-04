import { describe, it, expect, vi } from "vitest";
import { notifyRefreshControllers } from "../../../app/javascript/utilities/refresh.js";

describe("refresh", () => {
  describe("notifyRefreshControllers", () => {
    it("is a no-op when the controller has no refresh outlet", () => {
      const outlet = { ignoreNextRefresh: vi.fn() };

      notifyRefreshControllers({
        hasRefreshOutlet: false,
        refreshOutlets: [outlet],
      });

      expect(outlet.ignoreNextRefresh).not.toHaveBeenCalled();
    });

    it("notifies each refresh outlet that exposes ignoreNextRefresh", () => {
      const firstOutlet = { ignoreNextRefresh: vi.fn() };
      const secondOutlet = { ignoreNextRefresh: vi.fn() };

      notifyRefreshControllers({
        hasRefreshOutlet: true,
        refreshOutlets: [firstOutlet, null, {}, secondOutlet],
      });

      expect(firstOutlet.ignoreNextRefresh).toHaveBeenCalledTimes(1);
      expect(secondOutlet.ignoreNextRefresh).toHaveBeenCalledTimes(1);
    });
  });
});
