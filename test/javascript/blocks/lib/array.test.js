test('sample returns an element of the array', () => {
  const sounds = ['typing1', 'typing2', 'typing3']
  for (let i = 0; i < 20; i++) expect(sounds).toContain(sounds.sample())
})

test('sample eventually returns every element', () => {
  const sounds = ['typing1', 'typing2', 'typing3']
  const seen = new Set()
  for (let i = 0; i < 200; i++) seen.add(sounds.sample())
  expect([...seen].sort()).toStrictEqual(sounds)
})

test('sample of an empty array is undefined', () => {
  expect([].sample()).toBeUndefined()
})
