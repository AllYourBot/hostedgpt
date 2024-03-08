// runAfter

test('runAfter can been declared, it returns a TimeoutService', async() => {
  const timeout = runAfter(1000, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
  timeout.stop()
})

test('runAfter executed flag', async() => {
  let counter = 0
  const timeout = runAfter(3, () => counter += 1)
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  await sleep(5)
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBe(1)
  timeout.stop()
})

test('runAfter cleared flag', async() => {
  const timeout = runAfter(1000, () => 'hello')
  expect(timeout.cleared).toStrictEqual(false)
  timeout.stop()
  expect(timeout.cleared).toStrictEqual(true)
})

test('runAfter type is correct', async() => {
  const timeout = runAfter(1000, () => 'hello')
  expect(timeout.type).toBe('setTimeout')
  timeout.stop()
})

// runEvery

test('runEvery can been declared and it returns a TimeoutService', async() => {
  const timeout = runEvery(1000, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
  timeout.stop()
})

test('runEvery executed flag', async() => {
  let counter = 0
  const timeout = runEvery(2, () => counter += 1)
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  await sleep(5)
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBeGreaterThan(1)
  timeout.stop()
})

test('runEvery cleared flag', async() => {
  const timeout = runEvery(1000, () => 'hello')
  expect(timeout.cleared).toStrictEqual(false)
  timeout.stop()
  expect(timeout.cleared).toStrictEqual(true)
})

test('runEvery type is correct', async() => {
  const timeout = runEvery(1000, () => 'hello')
  expect(timeout.type).toBe('setInterval')
  timeout.stop()
})