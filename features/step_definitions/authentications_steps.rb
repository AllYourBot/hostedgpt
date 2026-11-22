# frozen_string_literal: true

# Steps for the login page's dark-mode readability, mirroring
# test/system/authentications_test.rb. The color-scheme emulation is scoped
# with the @dark-mode-emulation tag so the teardown hook only clears it for
# scenarios that set it.

Given("the browser prefers dark mode") do
  page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{ name: "prefers-color-scheme", value: "dark" }])
end

Given("I am logged out") do
  visit logout_path
end

Then("the sign up link is much lighter than the dark login background") do
  assert_text "Don't have an account?"

  colors = page.evaluate_script(<<~JS)
    (() => {
      const [r, g, b] = getComputedStyle(document.querySelector("a[href='#{register_path}']")).color.match(/\\d+/g).map(Number)
      return { text: (r + g + b) / 3, background: (() => {
        const [br, bg, bb] = getComputedStyle(document.querySelector("main")).backgroundColor.match(/\\d+/g).map(Number)
        return (br + bg + bb) / 3
      })() }
    })()
  JS

  assert_operator colors["text"] - colors["background"], :>, 100,
    "The Sign up link should be much lighter than the dark login background, but its brightness was #{colors["text"]} on #{colors["background"]}"
end

After("@dark-mode-emulation") do
  begin
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  rescue StandardError
    nil
  end
end
