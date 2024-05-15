test('simplest case', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox. He jumped over the lazy dog.")).toEqual(["The quick brown fox. ", "He jumped over the lazy dog."])
})

test('normal ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox... He jumped over the lazy dog.")).toEqual(["The quick brown fox... ", "He jumped over the lazy dog."])
})

test('space before ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox ... He jumped over the lazy dog.")).toEqual(["The quick brown fox ... ", "He jumped over the lazy dog."])
})

test('spaced out ellipsis', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox. . . He jumped over the lazy dog.")).toEqual(["The quick brown fox... ", "He jumped over the lazy dog."])
})

test('spaced out ellipsis with space before', async() => {
  expect(SpeechService.splitIntoThoughts("The quick brown fox . . . He jumped over the lazy dog.")).toEqual(["The quick brown fox ... ", "He jumped over the lazy dog."])
})