class VoiceChannel < ApplicationCable::Channel
  def subscribed
    puts "## CONNECTED params[:room]: #{params[:room]}"
    stream_from params[:room]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
