class Collections::DocumentsController < ApplicationController
  before_action :set_collection

  def create
    document = @collection.documents.new(document_params)

    if document.save
      redirect_to edit_collection_path(@collection), notice: I18n.t("app.flashes.documents.uploaded"), status: :see_other
    else
      redirect_to edit_collection_path(@collection), alert: document.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @collection.documents.find(params[:id]).destroy!
    redirect_to edit_collection_path(@collection), notice: I18n.t("app.flashes.documents.removed"), status: :see_other
  end

  private

  def set_collection
    @collection = Current.user.collections.find(params[:collection_id])
  end

  def document_params
    params.fetch(:document, {}).permit(:file)
  end
end
