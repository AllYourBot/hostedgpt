class TestController < ApplicationController
  allow_unauthenticated_access
  before_action :verify_key

  layout "public"

  def voice
  end

  def serenade
    ActionCable.server.broadcast("voice", { command: "pause" })
    `afplay public/ooah.wav; osascript -e 'tell application "System Events" to key code 49 using option down'`
    render plain: "OK"
  end

  def tasks
    case params[:command]
    when "serenade"
      ActionCable.server.broadcast("voice", { command: "pause" })
      `afplay public/ooah.wav; osascript -e 'tell application "System Events" to key code 49 using option down'`
      render plain: "OK"
    end
  end

  def openmeteo
    response = Toolbox.call("openmeteo_"+params[:command], params.slice(
      :state_province_or_region,
      :city,
      :country,
      :date_span_begin,
      :date_span_end,
    ))
    render json: response
  end

  private
  def verify_key
    if params[:key] != "4706"
      head :not_found
    end
  end
end
