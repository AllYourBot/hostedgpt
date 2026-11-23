require "test_helper"

class Settings::ScheduledPromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @scheduled_prompt = scheduled_prompts(:morning_briefing)
    login_as users(:keith)
  end

  test "should get index" do
    get settings_scheduled_prompts_url
    assert_response :success
    assert_contains_text "div#nav-container", "Scheduled Prompts"
    assert_select "table#scheduled-prompts tbody tr", count: users(:keith).scheduled_prompts.count
    assert_contains_text "#scheduled_prompt_#{@scheduled_prompt.id}", "every weekday at 8am"
    assert_contains_text "#scheduled_prompt_#{@scheduled_prompt.id}", "Samantha"
    assert_select "p#no-scheduled-prompts", false
  end

  test "should get index showing PAUSED for a disabled prompt" do
    @scheduled_prompt.update!(enabled: false)
    get settings_scheduled_prompts_url
    assert_contains_text "#scheduled_prompt_#{@scheduled_prompt.id}", "Paused"
  end

  test "should get index showing WHY a prompt paused after failures" do
    @scheduled_prompt.update!(enabled: false, consecutive_failures: 3)
    get settings_scheduled_prompts_url
    assert_contains_text "#scheduled_prompt_#{@scheduled_prompt.id}", "Paused after 3 failed runs"
  end

  test "should get index WITHOUT a table when the user HAS NO scheduled prompts" do
    get logout_url
    login_as users(:rob)
    get settings_scheduled_prompts_url
    assert_response :success
    assert_select "table", count: 0
    assert_select "p#no-scheduled-prompts", "You have no scheduled prompts."
  end

  test "should get new" do
    get new_settings_scheduled_prompt_url
    assert_response :success
    assert_select "textarea[name=?]", "scheduled_prompt[prompt]"
    assert_select "input[name=?]", "scheduled_prompt[schedule]"
    assert_select "select[name=?] option", "scheduled_prompt[assistant_id]", count: users(:keith).assistants.count
    assert_select "select[name=?] option[selected]", "scheduled_prompt[time_zone]", Time.zone.to_s
  end

  test "should create scheduled prompt" do
    assert_difference "ScheduledPrompt.count", 1 do
      post settings_scheduled_prompts_url, params: { scheduled_prompt: {
        assistant_id: assistants(:keith_claude35).id, prompt: "Weekly recap", schedule: "every friday at 5pm", time_zone: "Eastern Time (US & Canada)"
      } }
    end

    assert_redirected_to settings_scheduled_prompts_url
    assert_equal "Saved", flash[:notice]
    scheduled_prompt = ScheduledPrompt.last
    assert_equal users(:keith), scheduled_prompt.user, "The scheduled prompt should belong to the current user"
    assert_equal assistants(:keith_claude35), scheduled_prompt.assistant
    assert scheduled_prompt.next_run_at.future?, "The first run should be scheduled"
  end

  test "should not create scheduled prompt with an UNRECOGNIZED schedule" do
    assert_no_difference "ScheduledPrompt.count" do
      post settings_scheduled_prompts_url, params: { scheduled_prompt: {
        assistant_id: assistants(:samantha).id, prompt: "Hi", schedule: "sometimes"
      } }
    end
    assert_response :unprocessable_content
    assert_contains_text "body", "isn't a schedule we recognize"
  end

  test "should not create scheduled prompt for ANOTHER USER'S assistant" do
    assert_no_difference "ScheduledPrompt.count" do
      post settings_scheduled_prompts_url, params: { scheduled_prompt: {
        assistant_id: assistants(:rob_gpt4).id, prompt: "Hi", schedule: "every day at noon"
      } }
    end
    assert_response :unprocessable_content
  end

  test "should edit scheduled prompt" do
    get edit_settings_scheduled_prompt_url(@scheduled_prompt)
    assert_response :success
    assert_select "input[name=?][value=?]", "scheduled_prompt[schedule]", "every weekday at 8am"
    assert_select "form[action=?] button#run-now", run_settings_scheduled_prompt_path(@scheduled_prompt)
    assert_select "#paused-for-failures", false, "A healthy prompt should not explain a pause"
  end

  test "should edit a prompt PAUSED AFTER FAILURES with the reason & a link to its latest run" do
    latest = @scheduled_prompt.run!.conversation
    @scheduled_prompt.update!(enabled: false, consecutive_failures: 3)

    get edit_settings_scheduled_prompt_url(@scheduled_prompt)

    assert_response :success
    assert_contains_text "#paused-for-failures", "its last 3 runs failed"
    assert_select "#paused-for-failures a[href=?]", conversation_messages_path(latest), 1, "The notice should link to the latest run"
  end

  test "should update scheduled prompt" do
    patch settings_scheduled_prompt_url(@scheduled_prompt), params: { scheduled_prompt: { schedule: "every day at noon", enabled: "0" } }

    assert_redirected_to settings_scheduled_prompts_url
    @scheduled_prompt.reload
    assert_equal "every day at noon", @scheduled_prompt.schedule
    refute @scheduled_prompt.enabled?, "The prompt should be disabled"
    assert_nil @scheduled_prompt.next_run_at, "A disabled prompt should have no next run"
  end

  test "should destroy scheduled prompt" do
    assert_difference "ScheduledPrompt.count", -1 do
      delete settings_scheduled_prompt_url(@scheduled_prompt)
    end
    assert_redirected_to settings_scheduled_prompts_url
    assert_equal "Deleted", flash[:notice]
  end

  test "on run should post the prompt now, queue the reply & open the new conversation" do
    assert_difference "Conversation.count", 1 do
      assert_enqueued_with(job: GetNextAIMessageJob) do
        post run_settings_scheduled_prompt_url(@scheduled_prompt)
      end
    end

    message = Message.user.last
    assert_equal @scheduled_prompt.prompt, message.content_text
    assert_redirected_to conversation_messages_url(message.conversation, version: message.version)
  end

  test "should redirect with an alert for ANOTHER USER'S scheduled prompt" do
    get logout_url
    login_as users(:rob)

    get edit_settings_scheduled_prompt_url(@scheduled_prompt)
    assert_redirected_to settings_scheduled_prompts_url
    assert_equal "The scheduled prompt could not be found", flash[:alert]
  end
end
