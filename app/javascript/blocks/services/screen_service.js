import Service from "./service.js"

export default class extends Service {
  logLevel_info
  attr_started   = false
  attr_declined = false

  log_start
  async start() {
    const canIRun = 'getDisplayMedia' in navigator.mediaDevices
    if (!canIRun || $.declined) return false

    try {
      $.media = await navigator.mediaDevices.getDisplayMedia({
        video: { mediaSource: 'screen' }
      })
      $.started = true
    } catch (error) {
      log(`Screenshare declined: ${error}`)
      $.started = false
      $.declined = true
    }

    return $.started
  }

  end() {
    if ($.media) {
      const tracks = $.media.getVideoTracks()
      tracks.forEach(track => track.stop())
      $.media = null
    }
    $.started = false
    $.declined = false
  }

  async takeScreenshot() {
    if (!$.started) return

    const track = $.media.getVideoTracks()[0]
    if (!track || track.readyState === 'ended') {
      log('No screen available or track has ended')
      return null
    }

    try {
      return await this._getFirstFrameAsImage()
    } catch(error) {
      log('Error taking screenshot, trying another approach', error)
      return await this._getImageOfVideo()
    }
  }

  async _getFirstFrameAsImage() {
    const imageCapture = new ImageCapture(track.clone())
    const bitmap = await imageCapture.grabFrame()
    const canvas = document.createElement('canvas')
    canvas.width = bitmap.width
    canvas.height = bitmap.height
    const context = canvas.getContext('2d')
    context.drawImage(bitmap, 0, 0, bitmap.width, bitmap.height)
    return canvas.toDataURL()
  }

  async _getImageOfVideo() {
    let canvas = document.querySelector('canvas')
    if (canvas == null) {
      canvas = document.createElement('canvas')
    }
    const video = document.createElement('video')

    video.autoplay = true
    video.srcObject = $.media

    return new Promise((resolve) => {
      video.onplay = () => {
        canvas.width = video.videoWidth
        canvas.height = video.videoHeight
        const context = canvas.getContext('2d')
        context.drawImage(video, 0, 0)
        const image = canvas.toDataURL()
        resolve(image)
      }
      video.onerror = () => {
        resolve(null)
      }
    })
  }
}