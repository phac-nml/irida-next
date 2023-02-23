// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "flowbite";
import { Application } from "@hotwired/stimulus";
import layoutController from "./controllers/layout";

const application = Application.start();

application.register("layout", layoutController);
