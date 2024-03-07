test('start() initializes active and volume values', async() => {
  microphone = new MicrophoneService
  expect(microphone.$.active).toBeUndefined()
  expect(microphone.volume).toBeUndefined()
  await microphone.start()
  expect(microphone.$.active).toBe(true)
  expect(microphone.volume).toBe(0)
})

describe('tests on an instance', () => {
  let microphone

  beforeEach(async() => {
    microphone = new MicrophoneService()
    await microphone.start()
  })

  test('stop() after start makes things inactive', async() => {
    expect(microphone.$.active).toBe(true)
    microphone.stop()
    expect(microphone.$.active).toBe(false)
  })

  test('start() still works after a stop()', async() => {
    microphone.stop()
    expect(microphone.$.active).toBe(false)
    await microphone.start()
    expect(microphone.$.active).toBe(true)
  })

  test('onaudioprocess sets the volume by calling processVolume', async() => {
    expect(microphone.volume).toBe(0)

    const mockEvent = new AudioProcessingEvent() // mocked in test_helper
    microphone.$.audioProcessor.onaudioprocess(mockEvent)

    expect(microphone.volume).toBe(4)
  })
})
