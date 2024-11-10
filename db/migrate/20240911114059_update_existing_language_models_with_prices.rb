class UpdateExistingLanguageModelsWithPrices < ActiveRecord::Migration[7.1]
  def up
    [
      # Constant was removed in a later PR
      #
      # [LanguageModel::BEST_GPT, LanguageModel::BEST_MODEL_INPUT_PRICES[LanguageModel::BEST_GPT], LanguageModel::BEST_MODEL_OUTPUT_PRICES[LanguageModel::BEST_GPT]],
      # [LanguageModel::BEST_CLAUDE, LanguageModel::BEST_MODEL_INPUT_PRICES[LanguageModel::BEST_CLAUDE], LanguageModel::BEST_MODEL_OUTPUT_PRICES[LanguageModel::BEST_CLAUDE]],
      # [LanguageModel::BEST_GROQ, LanguageModel::BEST_MODEL_INPUT_PRICES[LanguageModel::BEST_GROQ], LanguageModel::BEST_MODEL_OUTPUT_PRICES[LanguageModel::BEST_GROQ]],

      ["gpt-4o", 500, 1500],
      ["gpt-4o-2024-05-13", 500, 1500],

      ["gpt-4-turbo", 1000, 3000],
      ["gpt-4-turbo-2024-04-09", 1000, 3000],
      ["gpt-4-turbo-preview", 1000, 3000], # not sure on price
      ["gpt-4-0125-preview", 1000, 3000],
      ["gpt-4-1106-preview", 1000, 3000],
      ["gpt-4-vision-preview", 1000, 3000],
      ["gpt-4-1106-vision-preview", 1000, 3000], # not sure on price

      ["gpt-4", 3000, 6000],
      ["gpt-4-0613", 1000, 3000], # not sure on price

      ["gpt-3.5-turbo", 300, 600],
      ["gpt-3.5-turbo-0125", 50, 150],
      ["gpt-3.5-turbo-1106", 100, 200],

      ["claude-3-5-sonnet-20240620",300, 1500],
      ["claude-3-opus-20240229", 1500, 7500],
      ["claude-3-sonnet-20240229", 300, 1500],
      ["claude-3-haiku-20240307", 25, 125],
      ["claude-2.1", 800, 2400],
      ["claude-2.0", 800, 2400],
      ["claude-instant-1.2", 80, 240],

      ["llama3-70b-8192", 59, 79],
      ["llama3-8b-8192", 5, 8],
      ["mixtral-8x7b-32768", 24, 24],
      ["gemma-7b-it", 7, 7],

      ["gpt-3.5-turbo-instruct", 150, 200],
      ["gpt-3.5-turbo-16k-0613", 300, 400],
    ].each do |api_name, input_token_cost_per_million, output_token_cost_per_million|
      million = BigDecimal(1_000_000)
      input_token_cost_cents = input_token_cost_per_million/million
      output_token_cost_cents = output_token_cost_per_million/million

      LanguageModel.where(api_name: api_name).update_all(
        input_token_cost_cents: input_token_cost_cents,
        output_token_cost_cents: output_token_cost_cents,
      )
    end
  end

  def down
    # nothing to do
  end
end
