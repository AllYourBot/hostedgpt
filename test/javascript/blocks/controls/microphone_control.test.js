let microphone

beforeEach(() => {
  microphone = new MicrophoneControl()
})

afterEach(() => {
  microphone.finalize()
})

test('new creates a MicrophoneService', () => {
  expect(microphone.$.microphoneService.class).toBe(MicrophoneService)
})

test('enable and disable changes status, on, and off', () => {
  expect(microphone.status).toBe('off')
  microphone.Enable()
  expect(microphone.status).toBe('on')
  expect(microphone.on).toBe(true)
  microphone.Disable()
  expect(microphone.status).toBe('off')
  expect(microphone.on).toBe(false)
})

test('when sound is heard, the volume changes and silence is recorded', async() => {
  microphone.$.microphoneService.onVolumeChanged(10)
  expect(microphone.volume).toBe(10)
  await sleep(0.5)
  expect(microphone.msOfSilence).toBeGreaterThan(0)
})