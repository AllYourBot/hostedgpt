test('simplest case', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox. He jumped over the lazy dog.")).toEqual(["The quick brown fox. ", "He jumped over the lazy dog."])
})

test('normal ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox... He jumped over the lazy dog.")).toEqual(["The quick brown fox... ", "He jumped over the lazy dog."])
})

test('space before ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox ... He jumped over the lazy dog.")).toEqual(["The quick brown fox ... ", "He jumped over the lazy dog."])
})

test('spaced out ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox. . . He jumped over the lazy dog.")).toEqual(["The quick brown fox... ", "He jumped over the lazy dog."])
})

test('spaced out ellipsis with space before', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox . . . He jumped over the lazy dog.")).toEqual(["The quick brown fox ... ", "He jumped over the lazy dog."])
})

describe('audioFromOpenAI when the server rejects the request', () => {
  let status

  beforeEach(() => {
    global.document = { querySelector: () => null }
    global.fetch = async () => ({ ok: false, status, json: async () => ({ message: 'Server message' }) })
  })

  afterEach(() => {
    delete global.document
    delete global.fetch
  })

  test('a 422 means the server has no voice to speak with', async() => {
    status = 422
    const error = await new SpeechService().audioFromOpenAI("Hi.").catch(e => e)

    expect(error.message).toEqual('Server message')
    expect(error.serverVoiceUnavailable).toStrictEqual(true)
  })

  test('other failures are worth retrying', async() => {
    status = 502
    const error = await new SpeechService().audioFromOpenAI("Hi.").catch(e => e)

    expect(error.serverVoiceUnavailable).toStrictEqual(false)
  })
})
