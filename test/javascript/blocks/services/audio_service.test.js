let audio

beforeEach(() => {
  audio = new AudioService()
})

afterEach(() => {
  audio.stopLooping()
})

test('playEvery ends the previous loop instead of leaking it', () => {
  audio.playEvery(10, 'thinking')
  const firstLoop = audio.$.loopHandler

  audio.playEvery(10, 'typing1')
  expect(firstLoop.cleared).toStrictEqual(true)
  expect(audio.$.loopHandler.cleared).toStrictEqual(false)
})

test('playRandomlyEvery ends the previous loop', () => {
  audio.playEvery(10, 'thinking')
  const firstLoop = audio.$.loopHandler

  audio.playRandomlyEvery(6, 10, ['typing1', 'typing2', 'typing3'])
  expect(firstLoop.cleared).toStrictEqual(true)
})

test('playRandomlyEvery plays one of the sounds at a slightly varied rate', async() => {
  const played = []
  audio._doThePlaying = (sound, onEnd, rate) => played.push({ sound, rate })

  audio.playRandomlyEvery(0.05, 0.1, ['typing1', 'typing2', 'typing3'])
  await sleep(0.5)

  expect(played.length).toBeGreaterThan(0)
  played.forEach(({ sound, rate }) => {
    expect(['typing1', 'typing2', 'typing3']).toContain(sound)
    expect(rate).toBeGreaterThanOrEqual(0.9)
    expect(rate).toBeLessThanOrEqual(1.1)
  })
})

test('stopLooping ends the loop', () => {
  audio.playRandomlyEvery(6, 10, ['typing1'])
  audio.stopLooping()
  expect(audio.$.loopHandler.cleared).toStrictEqual(true)
})

test('stop ends the loop', () => {
  audio.playEvery(10, 'thinking')
  audio.stop()
  expect(audio.$.loopHandler.cleared).toStrictEqual(true)
})

test('play ends the loop', async() => {
  audio.playEvery(10, 'thinking')
  await audio.play('pop')
  expect(audio.$.loopHandler.cleared).toStrictEqual(true)
})

test('playing a sound sets its playback rate', async() => {
  await audio._doThePlaying('pop', null, 1.05)
  expect(audio.$.playerSource.playbackRate.value).toBe(1.05)
})

test('audio that cannot be decoded still finishes so the speaker does not get stuck', async() => {
  audio.$.player.decodeAudioData = () => Promise.reject(new Error('EncodingError: Unable to decode audio data'))
  let ended = false

  await audio._doThePlaying('pop', () => { ended = true })
  expect(ended).toStrictEqual(true)
  expect(audio.$.playing).toStrictEqual(false)
})

test('a suspended audio context is resumed before playing', async() => {
  let resumed = false
  audio.$.player.state = 'suspended'
  audio.$.player.resume = async() => { resumed = true }

  await audio._doThePlaying('pop')
  expect(resumed).toStrictEqual(true)
})

test('a sentence whose audio failed to generate is skipped so the rest still play', async() => {
  const spoken = []
  audio._speakThenLoop = (index) => spoken.push(index)
  audio.$.queue.push({ index: 0, words: 'First. ', errored: true, generated: false, error: 'Service is currently unavailable' })
  audio.$.queue.push({ index: 1, words: 'Second.', audioUrl: 'blob:second', errored: false, generated: true })

  await audio._speakingLoop('generation')

  expect(spoken).toStrictEqual([1])
})

describe('when a sentence is skipped', () => {
  let said, utterances

  beforeEach(() => {
    said = []
    utterances = []
    audio._speakThenLoop = () => {}
    global.SpeechSynthesisUtterance = class { constructor(text) { this.text = text } }
    w.speechSynthesis = {
      speak: (utterance) => { said.push(utterance.text); utterances.push(utterance) },
      cancel: () => {}
    }
  })

  afterEach(() => {
    delete w.speechSynthesis
    delete global.SpeechSynthesisUtterance
  })

  test('the browser voice says part of the reply could not be read, then the rest plays', async() => {
    const spoken = []
    audio._speakThenLoop = (index) => spoken.push(index)
    audio.$.queue.push({ index: 0, words: 'First. ', errored: true })
    audio.$.queue.push({ index: 1, words: 'Second.', audioUrl: 'blob:second', generated: true, errored: false })

    await audio._speakingLoop('generation')
    expect(said).toStrictEqual(["Sorry, I couldn't read part of that."])
    expect(spoken).toStrictEqual([])

    utterances[0].onend()
    await sleep(0.05)
    expect(spoken).toStrictEqual([1])
  })

  test('the notice is said only once per reply', async() => {
    audio.$.queue.push({ index: 0, words: 'First. ', errored: true })
    audio.$.queue.push({ index: 1, words: 'Second.', errored: true })

    await audio._speakingLoop('generation')
    utterances[0].onend()
    await sleep(0.05)

    expect(said.length).toEqual(1)
  })

  test('stopping cancels the notice without resuming the reply', async() => {
    let cancelled = false
    w.speechSynthesis.cancel = () => { cancelled = true }
    audio.$.queue.push({ index: 0, words: 'First. ', errored: true })

    await audio._speakingLoop('generation')
    const notice = utterances[0]
    audio.stop()

    expect(cancelled).toStrictEqual(true)
    expect(notice.onend).toBeNull()
  })
})

describe('when the server has no voice to speak with', () => {
  let said, utterances

  beforeEach(() => {
    said = []
    utterances = []
    global.SpeechSynthesisUtterance = class { constructor(text) { this.text = text } }
    w.speechSynthesis = {
      speak: (utterance) => { said.push(utterance.text); utterances.push(utterance) },
      cancel: () => {}
    }
  })

  afterEach(() => {
    delete w.speechSynthesis
    delete global.SpeechSynthesisUtterance
  })

  test('each sentence is read by the browser voice, in order', async() => {
    audio.$.queue.push({ index: 0, words: 'First. ', browserVoice: true, generated: true, errored: false })
    audio.$.queue.push({ index: 1, words: 'Second.', browserVoice: true, generated: true, errored: false })

    await audio._speakingLoop('generation')
    expect(said).toStrictEqual(['First. '])

    utterances[0].onend()
    await sleep(0.05)
    expect(said).toStrictEqual(['First. ', 'Second.'])
  })

  test('stopping cancels the browser voice without resuming the reply', async() => {
    let cancelled = false
    w.speechSynthesis.cancel = () => { cancelled = true }
    audio.$.queue.push({ index: 0, words: 'First. ', browserVoice: true, generated: true, errored: false })

    await audio._speakingLoop('generation')
    const utterance = utterances[0]
    audio.stop()

    expect(cancelled).toStrictEqual(true)
    expect(utterance.onend).toBeNull()
  })
})

test('only two sentences are fetched at a time so later ones are not timed out while waiting on the server', async() => {
  const originalSpeechService = SpeechService
  const pending = []
  SpeechService = class {
    audioFromOpenAI(text) { return new Promise(resolve => pending.push({ text, resolve })) }
    cancel() {}
  }
  audio._speakThenLoop = () => {}

  try {
    ['One. ', 'Two. ', 'Three. ', 'Four.'].forEach(words => audio.speakNext(words))
    expect(pending.map(p => p.text)).toStrictEqual(['One. ', 'Two. '])

    pending[0].resolve('blob:one')
    await sleep(0.05)
    expect(pending.map(p => p.text)).toStrictEqual(['One. ', 'Two. ', 'Three. '])
  } finally {
    SpeechService = originalSpeechService
    audio.stop()
  }
})
