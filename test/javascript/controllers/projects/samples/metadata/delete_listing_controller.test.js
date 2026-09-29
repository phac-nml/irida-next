import { afterEach, describe, expect, it } from "vitest";
import {
  startApplication,
  stopApplication,
} from "../../../../helpers/stimulus.js";
import DeleteListingController from "../../../../../../app/javascript/controllers/projects/samples/metadata/delete_listing_controller.js";

describe("projects/samples/metadata DeleteListingController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  it("copies the key and value cells of checked rows into the listing", async () => {
    document.body.innerHTML = `
      <table>
        <tbody id="metadata-table-body">
          <tr class="row-selected">
            <td><input type="checkbox" checked></td>
            <td>key-1</td>
            <td>value-1</td>
          </tr>
          <tr class="row-unselected">
            <td><input type="checkbox"></td>
            <td>key-2</td>
            <td>value-2</td>
          </tr>
        </tbody>
      </table>
      <div data-controller="projects--samples--metadata--delete-listing">
        <table>
          <tbody data-projects--samples--metadata--delete-listing-target="tableBody"></tbody>
        </table>
      </div>`;

    application = startApplication();
    application.register(
      "projects--samples--metadata--delete-listing",
      DeleteListingController,
    );
    await Promise.resolve();

    const listing = document.querySelector(
      "[data-projects--samples--metadata--delete-listing-target='tableBody']",
    );

    expect(listing.rows.length).toBe(1);
    expect(listing.rows[0].className).toBe("row-selected");
    expect(
      Array.from(listing.rows[0].cells).map((cell) => cell.textContent),
    ).toEqual(["key-1", "value-1"]);
  });
});
