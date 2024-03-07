const path = require('path')
const fs = require('fs')

beforeAll(async () => {
  const blocksDir = path.join(__dirname, '../app/javascript/blocks/')
  await import(path.join(blocksDir, 'index.js'))

  const files = fs.readdirSync(path.join(blocksDir, 'lib'))
  for (const file of files) {
    if (file.endsWith('.js')) {
      const filepath = path.join(blocksDir, 'lib', file)
      await import(filepath)
    }
  }

  process.stdout.write('Loading all Blocks modules...\n')
  const subdirs = fs.readdirSync(blocksDir, { withFileTypes: true })
                    .filter(dir => dir.isDirectory())
                    .map(dir => dir.name)
                    .filter(name => name != 'lib')

  for (const subdir of subdirs) {
    process.stdout.write(`Loading blocks/${subdir}/*\n`)

    const files = fs.readdirSync(path.join(blocksDir, subdir))
    for (const file of files) {
      if (file.endsWith('.js')) {
        const modulePath = path.join(blocksDir, subdir, file)
        const className = path.basename(file, '.js')
                          .split('_')
                          .map(part => part.charAt(0).toUpperCase() + part.slice(1))
                          .join('')
        const { default: moduleClass } = await import(modulePath)
        global[className] = moduleClass
      }
    }
  }
  process.stdout.write('\n')
})

// Mock AudioContext

global.window = {
  mock: true,
  AudioContext: jest.fn().mockImplementation(() => ({
    close: jest.fn(),
    destination: {},

    // $.audioListener
    createMediaStreamSource: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
    }),

    // $.audioProcessor
    createScriptProcessor: jest.fn().mockReturnValue({
      connect: jest.fn(),
      disconnect: jest.fn(),
      onaudioprocess: null,
    }),
  })),
}

global.navigator = {
  mediaDevices: {
    getUserMedia: jest.fn().mockResolvedValue({ /* Mocked stream data */ }),
  },
}

global.AudioProcessingEvent = jest.fn().mockImplementation(() => ({
  inputBuffer: {
    getChannelData: jest.fn().mockReturnValue(new Float32Array(2048).fill(0.04)),
  },
}))
