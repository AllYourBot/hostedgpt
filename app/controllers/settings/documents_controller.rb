class Settings::DocumentsController < Settings::ApplicationController
  before_action :set_assistant

  def create
    document = @assistant.documents.new(document_params)

    if document.save
      redirect_to edit_settings_assistant_path(@assistant), notice: I18n.t("app.flashes.documents.uploaded"), status: :see_other
    else
      redirect_to edit_settings_assistant_path(@assistant), alert: document.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @assistant.documents.find(params[:id]).destroy!
    redirect_to edit_settings_assistant_path(@assistant), notice: I18n.t("app.flashes.documents.removed"), status: :see_other
  end

  private

  def set_assistant
    @assistant = Current.user.assistants.find(params[:assistant_id])
  end

  def document_params
    params.fetch(:document, {}).permit(:file)
  end
end
