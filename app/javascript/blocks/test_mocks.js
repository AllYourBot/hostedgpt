if (typeof g === 'undefined') global.g = global

const fn = () => {
  const mockFn = function(...args) {
    mockFn.mock.calls.push(args)
    return mockFn.mock.implementations.length > 0
      ? mockFn.mock.implementations[mockFn.mock.implementations.length - 1].apply(this, args)
      : undefined
  }
  mockFn.mock = { calls: [], implementations: [] }
  mockFn.mockImplementation = (impl) => {
    mockFn.mock.implementations.push(impl)
    return mockFn
  }
  mockFn.mockReturnValue = (value) => mockFn.mockImplementation(() => value)
  mockFn.mockResolvedValue = (value) => mockFn.mockImplementation(() => Promise.resolve(value))
  return mockFn
}

const jest = { fn }

// Mock AudioContext

g.w = {
  mock: true,
  AudioContext: jest.fn().mockImplementation(() => ({
    close: jest.fn(),
    destination: {},

    createMediaStreamSource: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
    }),

    createScriptProcessor: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
      onaudioprocess: null,
    }),

    createAnalyser: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
    }),

    decodeAudioData: jest.fn().mockResolvedValue({
      getChannelData: jest.fn().mockReturnValue(new Float32Array(2048).fill(0.04)),
    }),

    createBufferSource: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
      start: jest.fn(),
      stop: jest.fn(),
      buffer: null
    }),

    createGain: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
      gain: {value: 1}
    }),

    createOscillator: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
      start: jest.fn(),
      stop: jest.fn(),
      frequency: {value: 440}
    }),

    currentTime: 0,
  })),

  SpeechRecognition: jest.fn().mockImplementation(() => ({
    continuous: null,
    lang: null,
    onstart: () => { },
    onend: () => { },
    onerror: () => { },
    onresult: () => { },
    onsoundstart: () => { },
    onspeechstart: () => { },
    onsoundend: () => { },
    onspeechend: () => { },
    start: () => { },
    abort: () => { },
  })),

  webkitSpeechRecognition: jest.fn().mockImplementation(() => ({
    continuous: null,
    lang: null,
    onstart: () => { },
    onend: () => { },
    onerror: () => { },
    onresult: () => { },
    onsoundstart: () => { },
    onspeechstart: () => { },
    onsoundend: () => { },
    onspeechend: () => { },
    start: () => { },
    abort: () => { },
  })),
}

g.n = {
  mediaDevices: {
    getUserMedia: jest.fn().mockResolvedValue({
      getTracks: jest.fn().mockReturnValue([]),
    }),
  },
}

g.AudioProcessingEvent = jest.fn().mockImplementation(() => ({
  inputBuffer: {
    getChannelData: jest.fn().mockReturnValue(new Float32Array(2048).fill(0.04)),
  },
}))

g.Audio = jest.fn().mockImplementation(() => ({
  onended: () => { },
  pause: () => { },
  volume: null,
  src: null,
  play: () => { },
}))
