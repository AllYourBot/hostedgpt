test('runAfter can been declared and it returns a TimeoutService', async() => {
  const timeout = runAfter(1000, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
  timeout.stop()
})

test('runAfter executed starts out false', async() => {
  const timeout = runAfter(1000, () => 'hello')
  expect(timeout.executed).toStrictEqual(false)
  timeout.stop()
})

test('runEvery can been declared and it returns a TimeoutService', async() => {
  const timeout = runEvery(1000, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
  timeout.stop()
})
