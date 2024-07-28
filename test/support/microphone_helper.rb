module MicrophoneHelper
  private

  def enable_mic
    @enable_mic_element ||= find("#composer").find_target("microphoneEnable", controller: "composer").find("button")
  end

  def disable_mic
    @disable_mic_element ||= find("#composer").find_target("microphoneDisable", controller: "composer")
  end
end
