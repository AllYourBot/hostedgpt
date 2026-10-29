let obj0, obj1, queue

beforeEach(() => {
  obj0 = {i: 0, name: "Keith"}
  obj1 = {i: 1, name: "Steve"}
  queue = new QueueService([obj0, obj1])
})

test('all returns the array', async() => {
  expect(queue.all).toStrictEqual([obj0, obj1])
})

test('at returns a specific element', async () => {
  expect(queue.at(1)).toStrictEqual(obj1)
})

test('push adds to the array and at retrieves', async () => {
  obj2 = {i: 2, name: "Bob"}
  queue.push(obj2)
  expect(queue.length).toEqual(3)
  expect(queue.at(2)).toEqual(obj2)
})

test('reset clears the array', async () => {
  queue.reset()
  expect(queue.length).toEqual(0)
  expect(queue.all).toEqual([])
})

test('queueRequest marks a job errored with the last failure after three attempts', async () => {
  const originalSpeechService = SpeechService
  let attempts = 0
  SpeechService = class { async audioFromOpenAI() { attempts++; throw new Error('Service is currently unavailable') } }

  try {
    await queue.queueRequest(0, "Keith")
  } finally {
    SpeechService = originalSpeechService
  }

  expect(attempts).toEqual(3)
  expect(obj0.errored).toStrictEqual(true)
  expect(obj0.error).toEqual('Service is currently unavailable')
})

describe('when the server has no voice to speak with', () => {
  let originalSpeechService, attempts

  beforeEach(() => {
    originalSpeechService = SpeechService
    attempts = 0
    SpeechService = class { async audioFromOpenAI() {
      attempts++
      throw Object.assign(new Error('No OpenAI key'), { serverVoiceUnavailable: true })
    } }
  })

  afterEach(() => { SpeechService = originalSpeechService })

  test('queueRequest stops retrying and hands the job to the browser voice', async () => {
    await queue.queueRequest(0, "Keith")

    expect(attempts).toEqual(1)
    expect(obj0.browserVoice).toStrictEqual(true)
    expect(obj0.generated).toStrictEqual(true)
    expect(obj0.errored).toBeUndefined()
  })

  test('later sentences of the reply skip the server entirely', async () => {
    await queue.queueRequest(0, "Keith")
    await queue.queueRequest(1, "Steve")

    expect(attempts).toEqual(1)
    expect(obj1.browserVoice).toStrictEqual(true)
  })
})
