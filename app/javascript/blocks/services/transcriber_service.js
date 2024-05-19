import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attrAccessor_onTextReceived
  attrReader_listening

  new() {
    $.intendedState = 'ended'
    $.state = 'ended'
    $.recognizer = null

    this._initSpeechRecognizer()
    if ($.recognizer) {
      $.recognizer.onstart = () => _onStart()
      $.recognizer.onend = () => _onEnd()
      $.recognizer.onerror = () => _onError()
      $.recognizer.onresult = (event) => _onResult(event)
    }
  }

  _initSpeechRecognizer() {
    if ('webkitSpeechRecognition' in window)
      $.recognizer = new webkitSpeechRecognition()
    else if ('SpeechRecognition' in window)
      $.recognizer = new SpeechRecognition()

    if ($.recognizer) {
      $.recognizer.continuous = true
      // Indicate a locale code such as 'fr-FR', 'en-US', to use a particular language for the speech recognition
      $.recognizer.lang = "" // blank uses system's default language
    }
  }

  start()         { $.intendedState = 'started';  _executeStart() }
  restart()       { $.intendedState = 'started';  _executeRestart() }
  end()           { $.intendedState = 'ended';    _executeEnd() }
  get listening()  { $.state == 'started' }
  get ended()      { $.state == 'ended' }


  // Exeuctors

  _executeStart() {
    if ($.state != 'started')
      $.recognizer.start() // triggers _onStart() callback
    else
      _onStart()
  }

  _executeRestart() {
    if ($.state == 'started')
      _executeEnd() // will eventually trigger _onStart() b/c of intendedState
    else
      _onStart()
  }

  _executeEnd() {
    $.recognizer.abort()
  }

  _executeIntendedState() {
    if ($.intendedState == 'started') _executeStart()
    if ($.intendedState == 'ended')   _executeEnd()
  }

  // After state change

  log_onStart
  _onStart() {
    $.state = 'started' // we may not intend this but we're here
    if ($.intendedState != 'started') _executeIntendedState()
  }

  log_onEnd
  _onEnd() {
    $.state = 'ended' // we may not intend this but we're here, ensures recognizer will restart
    if ($.intendedState != 'ended') _executeIntendedState()
  }

  log_onError
  _onError() {
    _executeIntendedState()
  }

  _onResult(event) {
    let transcript = ""
    for (let i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) transcript += event.results[i][0].transcript
    }
    transcript = transcript.trim()

    if (transcript.length <= 1) return

    $.onTextReceived(transcript)
  }
}