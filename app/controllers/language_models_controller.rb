class LanguageModelsController < ApplicationController
	skip_before_action :authenticate_user!, only: [:index]

	def index
		render json: LanguageModel.all
	end
end
