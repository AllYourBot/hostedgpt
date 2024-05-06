let microphone

beforeEach(() => {
  Microphone = new MicrophoneControl()
})

afterEach(() => {
  Microphone.finalize()
})

test('new creates a MicrophoneService', () => {
  expect(Microphone.$.microphoneService.class).toBe(MicrophoneService)
})

test('enable and disable changes status, on, and off', () => {
  expect(Microphone.status).toBe('off')
  Microphone.Enable()
  expect(Microphone.status).toBe('on')
  expect(Microphone.on).toBe(true)
  Microphone.Disable()
  expect(Microphone.status).toBe('off')
  expect(Microphone.on).toBe(false)
})

test('when sound is heard, the volume changes and silence is recorded', async() => {
  Microphone.$.microphoneService.onVolumeChanged(10)
  expect(Microphone.volume).toBe(10)
  await sleep(0.5)
  expect(Microphone.msOfSilence).toBeGreaterThan(0)
})