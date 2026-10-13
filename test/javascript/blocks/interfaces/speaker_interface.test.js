beforeEach(() => {
  initializeInterfaces()
})

afterEach(() => {
  Speaker.$.audioService.stopLooping()
})

test('Hush ends any looping sound', () => {
  Loop.Speaker.every(4, 'thinking')
  Hush.Speaker()
  expect(Speaker.$.audioService.$.loopHandler.cleared).toStrictEqual(true)
})

test('typing sounds loop while the listener is engaged', () => {
  Listener.$.processing = true
  Speaker._loopTypingSounds()
  expect(Speaker.$.audioService.$.loopHandler.cleared).toStrictEqual(false)
})

test('typing sounds do not start when the listener was dismissed', () => {
  Listener.$.processing = false
  Speaker._loopTypingSounds()
  expect(Speaker.$.audioService.$.loopHandler).toBeUndefined()
})

test('typing sounds do not start when the listener was disabled', () => {
  Listener.$.processing = null
  Speaker._loopTypingSounds()
  expect(Speaker.$.audioService.$.loopHandler).toBeUndefined()
})
