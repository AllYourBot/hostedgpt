let timeout

// runAfter

beforeEach(() => {
  timeout = null
})

afterEach(() => {
  if (timeout) timeout.end()
})

test('runAfter can been declared, it returns a TimeoutService', async() => {
  timeout = runAfter(1, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
})

test('runAfter runs and sets the executed flag', async() => {
  let counter = 0
  timeout = runAfter(1, () => { counter += 1 })
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  await sleep(4)
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBe(1)
})

test('runAfter can be run early and sets the flag', async () => {
  let counter = 0
  timeout = runAfter(1, () => {counter += 1})
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  timeout.run()
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBe(1)
})

test('runAfter end cleared flag', async() => {
  timeout = runAfter(1, () => 'hello')
  expect(timeout.cleared).toStrictEqual(false)
  timeout.end()
  expect(timeout.cleared).toStrictEqual(true)
})

test('runAfter type is correct', async() => {
  timeout = runAfter(1, () => 'hello')
  expect(timeout.type).toBe('setTimeout')
})

// runEvery

test('runEvery can been declared and it returns a TimeoutService', async() => {
  timeout = runEvery(1, () => 'hello')
  expect(timeout.constructor).toBe(TimeoutService)
})

test('runEvery runs and sets the executed flag', async() => {
  let counter = 0
  timeout = runEvery(1, () => counter += 1)
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  await sleep(3)
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBeGreaterThan(1)
})

test('runEvery runs early and sets the executed flag', async () => {
  let counter = 0
  timeout = runEvery(1, () => counter += 1)
  expect(timeout.executed).toStrictEqual(false)
  expect(counter).toBe(0)

  timeout.run()
  expect(timeout.executed).toStrictEqual(true)
  expect(counter).toBeGreaterThan(0)
})

test('runEvery end cleared flag', async() => {
  timeout = runEvery(1, () => {})
  expect(timeout.cleared).toStrictEqual(false)
  timeout.end()
  expect(timeout.cleared).toStrictEqual(true)
})

test('runEvery type is correct', async() => {
  timeout = runEvery(1, () => {})
  expect(timeout.type).toBe('setInterval')
})

// runEveryBetween

test('runEveryBetween keeps running at intervals within the range until ended', async() => {
  let counter = 0
  timeout = runEveryBetween(0.1, 0.2, () => { counter += 1 })

  await sleep(0.7)
  expect(counter).toBeGreaterThanOrEqual(3)
  expect(counter).toBeLessThanOrEqual(7)

  timeout.end()
  const counterWhenEnded = counter
  await sleep(0.4)
  expect(counter).toBe(counterWhenEnded)
})

test('runEveryBetween stops rescheduling when ended from within its own function', async() => {
  let counter = 0
  timeout = runEveryBetween(0.05, 0.1, () => { counter += 1; timeout.end() })

  await sleep(0.4)
  expect(counter).toBe(1)
  expect(timeout.cleared).toStrictEqual(true)
})
