const path = require('path')
const fs = require('fs')

const debug = false

beforeAll(async () => {
  const blocksDir = path.join(__dirname, '../app/javascript/blocks/')
  const subdirs = subdirsExceptLib(blocksDir)

  await importFile(blocksDir, 'index.js')

  if (debug) process.stdout.write('Loading all Blocks modules...\n')
  await importDir('lib')
  for (const subdir of subdirs) await importDir(subdir)

  if (debug) process.stdout.write('\n')
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

async function importFile(dir, name) {
  const filepath = path.join(dir, name)
  return import(filepath)
}

function subdirsExceptLib(dir) {
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(dir => dir.isDirectory())
    .map(dir => dir.name)
    .filter(name => name != 'lib')
}

async function importDir(name) {
  const blocksDir = path.join(__dirname, '../app/javascript/blocks/')
  const nameDir = path.join(blocksDir, name)
  const all = fs.readdirSync(nameDir, { withFileTypes: true })
  const files = all.filter(f => f.name.endsWith('.js')).map(f => f.name)

  if (debug) process.stdout.write(`Loading blocks/${name}/*\n`)

  for (const file of files) {
    const imported = await importFile(nameDir, file)
    if (name != 'lib') {
      const { default: moduleClass } = imported
      const className = file
        .split('.')[0]
        .split('_')
        .map(part => part.charAt(0).toUpperCase() + part.slice(1))
        .join('')
      global[className] = moduleClass
    }
  }
}