require "application_system_test_case"

class AuthenticationsTest < ApplicationSystemTestCase
  teardown do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  test "the sign up link on the login page is readable when the browser prefers dark mode" do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{ name: "prefers-color-scheme", value: "dark" }])
    visit logout_path
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
end
