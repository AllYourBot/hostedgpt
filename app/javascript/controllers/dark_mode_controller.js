import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['document']
  static values = { userPreference: String }

  connect() {
    this.setDarkMode(this.userPreferenceValue)
    this.addDarkModeListener()
  }

  toggleDarkMode = (darkMode) => {
    if (this.hasElement) {
      this.element.classList.toggle('dark', darkMode)
      this.element.classList.toggle('light', !darkMode)
    }
  }

  addDarkModeListener() {
    if (this.userPreferenceValue === 'system') {
      window
        .matchMedia('(prefers-color-scheme: dark)')
        .addEventListener('change', (e) => {
          this.toggleDarkMode(e.matches)
        })
    }
  }

  setDarkMode(userPreference) {
    switch (userPreference) {
      case 'light':
        this.toggleDarkMode(false)
        break
      case 'dark':
        this.toggleDarkMode(true)
        break
      default:
        const prefersDarkMode = window.matchMedia(
          '(prefers-color-scheme: dark)'
        ).matches
        this.toggleDarkMode(prefersDarkMode)
    }
  }
}
