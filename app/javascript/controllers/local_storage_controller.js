import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  saveToLocalStorage(event) {
    const themeValues = ['light', 'dark'];

    if (themeValues.includes(event.target.value)) {
      document.documentElement.setAttribute('data-theme', event.target.value);
    } else {
      this.setInitialTheme();
    }
  }
}
