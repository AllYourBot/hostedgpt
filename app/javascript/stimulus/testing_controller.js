import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["model", "test", "url","token"]

  update_link_language_model(event) {
    const link = event.currentTarget;
    const href = link.href.split('?')[0];
    link.href = href + "?model=" + this.modelTarget.value
  }

  update_link_api_service(event) {
    const link = event.currentTarget;
    const href = link.href.split('?')[0];
    link.href = href + "?url=" + this.urlTarget.value + "&token=" + this.tokenTarget.value
    console.log("Link: ", link)
  }

  disable_test_link() {
    const link = this.testTarget;
    link.addEventListener('click', function(event) {
      event.preventDefault();
    });
  }
}
