let microphone

beforeEach(() => {
  initializeInterfaces()
})

afterEach(() => {
  Microphone.$.poller?.end()
})

test('new creates a MicrophoneService', () => {
  expect(Microphone.$.microphoneService.class).toBe(MicrophoneService)
})

test('enable and disable changes active, on, and off', async() => {
  expect(Microphone.active).toBe(false)
  expect(Microphone.on).toBe(false)
  expect(Microphone.off).toBe(true)
  await Flip.Microphone.on()
  debugger
  expect(Microphone.active).toBe(true)
  expect(Microphone.on).toBe(true)
  expect(Microphone.off).toBe(false)
  await Flip.Microphone.off()
  debugger
  expect(Microphone.active).toBe(false)
  expect(Microphone.on).toBe(false)
  expect(Microphone.off).toBe(true)
})

test('when sound is heard, the volume changes and silence is recorded', async() => {
  Microphone.$.microphoneService.onVolumeChanged(10)
  expect(Microphone.volume).toBe(10)
  await sleep(0.5)
  expect(Microphone.msOfSilence).toBeGreaterThan(0)
})
