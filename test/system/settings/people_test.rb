require "application_system_test_case"

class Settings::PeopleTest < ApplicationSystemTestCase
  setup do
    @person = people(:keith_registered)
    login_as @person
    visit edit_settings_person_url
  end

  test "should update Person" do
    attr = {
      email: @person.email+"-2",
      first_name: @person.user.first_name+"-2",
      last_name: @person.user.last_name+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]
    fill_in "Password", with: "secret"

    click_text "Save"

    assert_alert "Saved"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys
  end

  test "should update Person without setting the password" do
    attr = {
      email: @person.email+"-2",
      first_name: @person.user.first_name+"-2",
      last_name: @person.user.last_name+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]

    click_text "Save"

    assert_alert "Saved"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys
  end

  test "assistants in the settings sidebar render their service logo avatars" do
    assert_selector "section#menu picture img[src*='groq_logo']" # Groq Llama 3.3
    assert_selector "section#menu picture img[src*='openai_logo']", count: 3 # Samantha, GPT 3.5, OpenAI GPT-4o
    assert_selector "section#menu picture img[src*='claude_logo']", count: 2
    assert_equal "block", page.evaluate_script("getComputedStyle(document.querySelector('section#menu picture')).display")
  end

  test "the AI backends radio columns align across all provider rows" do
    columns = %w[default ruby_llm sdk]
    rows = page.evaluate_script(<<~JS)
      (() => {
        const rows = {};
        for (const el of document.querySelectorAll('input[type=radio][name^="person[backend_choices]"]')) {
          const provider = el.name.split('[')[2].replace('_ai_backend]', '');
          const r = el.getBoundingClientRect();
          rows[provider] = rows[provider] || {};
          rows[provider][el.value || "default"] = Math.round(r.x * 10) / 10;
        }
        return rows;
      })()
    JS

    assert_equal User::Features.derived_backend_names.map { |n| n.to_s.delete_suffix("_ai_backend") }.sort, rows.keys.sort

    # Fixed-width radio columns used to shrink per-row with the label text,
    # sliding every row's columns to different x positions.
    columns.each do |column|
      xs = rows.values.map { |cells| cells.fetch(column) }
      assert (xs.max - xs.min) < 0.5, "the #{column} column is misaligned across provider rows: #{xs.inspect}"
    end
  end
end
