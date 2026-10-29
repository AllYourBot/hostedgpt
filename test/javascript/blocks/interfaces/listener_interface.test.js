beforeEach(() => {
  initializeInterfaces()
  Speaker.$.audioService.playRandomlyEvery(6, 10, ['typing1', 'typing2', 'typing3'])
})

afterEach(() => {
  Speaker.$.audioService.stopLooping()
  Transcriber.$.dismissPoller?.end()
  Transcriber.$.silenceService.stop()
})

test('Dismiss stops the typing sounds', async() => {
  Listener.$.processing = true
  Transcriber.$.active = true
  await Dismiss.Listener()
  expect(Listener.dismissed).toStrictEqual(true)
  expect(Speaker.$.audioService.$.loopHandler.cleared).toStrictEqual(true)
})

test('Disable stops the typing sounds', async() => {
  Listener.$.processing = true
  await Disable.Listener()
  expect(Listener.disabled).toStrictEqual(true)
  expect(Speaker.$.audioService.$.loopHandler.cleared).toStrictEqual(true)
})

test('Disable stops the speaker mid-sentence so the next reply can still be read aloud', async() => {
  Listener.$.processing = true
  Speaker.$.audioService.$.speaking = true
  Speaker.$.audioService.$.queue.push({ index: 0, words: 'Unread.', generated: true, errored: false })

  await Disable.Listener()

  expect(Speaker.$.audioService.$.speaking).toStrictEqual(false)
  expect(Speaker.$.audioService.$.queue.length).toEqual(0)
})
