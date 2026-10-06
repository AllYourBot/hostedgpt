class CollectionsController < ApplicationController
  before_action :set_nav_assistants, except: :destroy
  before_action :set_nav_collections, except: :destroy
  before_action :set_collection, only: [:edit, :update, :destroy]

  def index
  end

  def new
    @collection = Collection.new
  end

  def edit
  end

  def create
    @collection = Current.user.collections.new(collection_params)

    if @collection.save
      redirect_to edit_collection_path(@collection), notice: I18n.t("app.flashes.collections.saved"), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @collection.update(collection_params)
      redirect_to edit_collection_path(@collection), notice: I18n.t("app.flashes.collections.saved"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @collection.destroy!
    redirect_to collections_url, notice: I18n.t("app.flashes.collections.deleted"), status: :see_other
  end

  private

  def set_collection
    @collection = Current.user.collections.find_by(id: params[:id])
    if @collection.nil?
      redirect_to collections_url, notice: I18n.t("app.flashes.collections.deleted_full"), status: :see_other
    end
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
