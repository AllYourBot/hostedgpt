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
