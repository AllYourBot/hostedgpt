beforeEach(() => {
  initializeInterfaces()
})

test('a finished thought needs only a short silence before it is considered', () => {
  expect(Transcriber._msOfSilenceNeeded('What is the weather in Austin')).toBe(800)
  expect(Transcriber._msOfSilenceNeeded('can you hear me, right?')).toBe(800)
})

test('words trailing off mid-thought need a longer silence', () => {
  expect(Transcriber._msOfSilenceNeeded('I was wondering if')).toBe(2000)
  expect(Transcriber._msOfSilenceNeeded('Tell me about the weather and ')).toBe(2000)
  expect(Transcriber._msOfSilenceNeeded('So, um...')).toBe(2000)
  expect(Transcriber._msOfSilenceNeeded('Well I think I\'m')).toBe(2000)
})

test('trailing words are matched case insensitively', () => {
  expect(Transcriber._msOfSilenceNeeded('Remind me to call Samantha AND')).toBe(2000)
})

test('words that merely contain a trailing word are a finished thought', () => {
  expect(Transcriber._msOfSilenceNeeded('I love my band')).toBe(800)
})

describe('going into standby after silence', () => {
  beforeEach(() => {
    Listener.$.processing = true
    Transcriber.$.active = true
    Uncover.Transcriber()
  })

  afterEach(() => {
    Transcriber.$.dismissPoller?.end()
    Transcriber.$.silenceService.stop()
  })

  test('a pause of several seconds keeps the listener engaged', async() => {
    Transcriber.$.silenceService.$.msOfSilence = 5000
    await sleep(0.5)
    expect(Listener.engaged).toStrictEqual(true)
  })

  test('30 seconds of silence dismisses the listener', async() => {
    Transcriber.$.silenceService.$.msOfSilence = 30001
    await sleep(0.5)
    expect(Listener.dismissed).toStrictEqual(true)
  })
})
