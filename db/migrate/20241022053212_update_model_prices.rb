class UpdateModelPrices < ActiveRecord::Migration[7.1]
  def up
    [
      # Constant was removed in a later PR
      # [LanguageModel::BEST_GPT, LanguageModel::BEST_MODEL_INPUT_PRICES[LanguageModel::BEST_GPT], LanguageModel::BEST_MODEL_OUTPUT_PRICES[LanguageModel::BEST_GPT]],

      ["gpt-4o", 250, 1000],
    ].each do |api_name, input_token_cost_per_million, output_token_cost_per_million|
      million = BigDecimal(1_000_000)
      input_token_cost_cents = input_token_cost_per_million/million
      output_token_cost_cents = output_token_cost_per_million/million

      LanguageModel.where(api_name: api_name).update_all(
        input_token_cost_cents: input_token_cost_cents,
        output_token_cost_cents: output_token_cost_cents,
      )
    end

    # add new model too
    User.find_each do |user|
      open_ai_api_service = user.api_services.find_or_create_by!(url: APIService::URL_OPEN_AI, driver: :openai, name: "OpenAI")

      [
        ["gpt-4o-2024-08-06", "GPT-4o Omni Multimodal (2024-08-06)", true, open_ai_api_service, 250, 1000],
      ].each do |api_name, name, supports_images, api_service, input_token_cost_per_million, output_token_cost_per_million|
        unless user.language_models.exists?(api_name: api_name) # don't add if it already exists
          million = BigDecimal(1_000_000)
          input_token_cost_cents = input_token_cost_per_million/million
          output_token_cost_cents = output_token_cost_per_million/million

          LanguageModel.skip_callback(:save, :after, :update_best_language_model_for_api_service)

          begin
            user.language_models.create!(
              api_name: api_name,
              name: name,
              supports_images: supports_images,
              api_service: api_service,
              supports_tools: true,
              input_token_cost_cents: input_token_cost_cents,
              output_token_cost_cents: output_token_cost_cents,
            )
          ensure
            LanguageModel.set_callback(:save, :after, :update_best_language_model_for_api_service)
          end
        end
      end
    end

  end

  def down
    # nothing to do
  end
end
