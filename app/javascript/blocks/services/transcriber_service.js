import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attrReader_listening
  attrAccessor_onSound

  new() {
    $.intendedState = 'ended'
    $.state = 'ended'
    $.recognizer = null
    $.previousWords = ""
    $.waitForNewThought = false

    _initSpeechRecognizer()
    if ($.recognizer) {
      $.recognizer.onstart = () => _onStart()
      $.recognizer.onend = () => _onEnd()
      $.recognizer.onerror = (e) => _onError(e)
      $.recognizer.onresult = (event) => _onResult(event)
    }
  }

  _initSpeechRecognizer() {
    if ('webkitSpeechRecognition' in w)
      $.recognizer = new w.webkitSpeechRecognition()
    else if ('SpeechRecognition' in w)
      $.recognizer = new w.SpeechRecognition()

    if ($.recognizer) {
      $.recognizer.continuous = true
      // Indicate a locale code such as 'fr-FR', 'en-US', to use a particular language for the speech recognition
      $.recognizer.lang = "" // blank uses system's default language
      $.recognizer.interimResults = true
    }
  }

  async start()   { $.intendedState = 'started';  return await _executeStart() }
  async restart() { $.intendedState = 'started';  return await _executeRestart() }
  end()           { $.intendedState = 'ended';    _executeEnd() }
  get listening() { $.state == 'started' }
  get ended()     { $.state == 'ended' }


  // Exeuctors

  async _executeStart() {
    if (!$.recognizer) return

    if ($.state != 'started') {
      try {
        $.recognizer.start() // triggers _onStart() callback
      } catch(e) {
        return Promise.resolve(false)
      }

      return new Promise((resolve) => {
        const checkState = () => {
          if ($.state === 'started')
            resolve(true)
          else if ($.state === 'rejected')
            resolve(false)
          else
            runAfter(1, () => checkState())
        }
        checkState()
      })
      // return a promise that loop forever, every 200 ms checking if $.state == 'started' and then the promise resolves when it is

    } else
      _onStart()
  }

  log_executeRestart
  _executeRestart() {
    if (!$.recognizer) return
    $.waitForNewThought = true

    if ($.state == 'started')
      _executeEnd() // will eventually trigger _onStart() b/c of intendedState
    else if ($.state == 'ended')
      _executeStart()
    else
      _onStart()
  }

  _executeEnd() {
    if (!$.recognizer) return
    $.recognizer.abort()
  }

  _executeIntendedState() {
    if ($.intendedState == 'started') _executeStart()
    if ($.intendedState == 'ended')   _executeEnd()
  }

  // After state change

  _onStart() {
    $.state = 'started' // we may not intend this but we're here
    if ($.intendedState != 'started') _executeIntendedState()
  }

  _onEnd() {
    if ($.state == 'rejected') return

    $.state = 'ended' // we may not intend this but we're here, ensures recognizer will restart
    if ($.intendedState != 'ended') _executeIntendedState()
  }

  _onError(e) {
    if (e.error == 'not-allowed') {
      $.state = 'rejected'
      $.intendedState = 'rejected'
      return
    }

    _executeIntendedState()
  }

  _onResult(event) {
    let transcript = ""
    if (_isNewThought(event)) { $.previousWords = ""; $.waitForNewThought = false }
    if ($.waitForNewThought) return

    for (let i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) {
        transcript += _adjustedTranscript(event.results[i][0].transcript)
        $.previousWords = event.results[i][0].transcript
      }
      if ($.onSound) $.onSound()
    }
    transcript = transcript.trim()

    if (transcript.length <= 1) return

    SpeakTo.Transcriber.with.words(transcript)
  }

  _adjustedTranscript(transcript) {
    // A bug in the speech recognition library on Pixel Chrome causes it to keep repeating all of
    // what it has heard with each addition rather than just returning the additional words it heard.
    // Strip those repeated words off.
    if (transcript.startsWith($.previousWords))
      return transcript.slice($.previousWords.length)
    else
      return transcript
  }

  _isNewThought(event) {
    return event.resultIndex == 0
  }
}
