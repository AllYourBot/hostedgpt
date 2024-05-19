const repl = require('repl')
const readline = require('readline')
const stream = require('stream')
const fs = require('fs')
const path = require('path')

let cmd = ''
let suppressOutput = false

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1)
}


// Configure REPL

process.stdin.setRawMode(true)
process.stdin.resume()
process.stdin.setEncoding('utf8')

const replInput = new stream.PassThrough()
const blocksDir = path.join(__dirname, '..', '..', 'app', 'javascript', 'blocks')
class DummyOutput extends stream.Writable { _write(chunk, encoding, callback) { callback() }}

const r = repl.start({ input: replInput, output: process.stdout, terminal: true })
r.on('exit', () => process.exit())

process.stdin.on('data', (key) => {
  if (key !== '\r') cmd += key

  if (key === '\u0003') // Ctrl+C
    exit()
  else if (key === '\r' && (cmd.trim() == 'exit' || cmd.trim() == '.exit'))
    exit()
  else
    replInput.write(key)

  if (key === '\r') cmd = ''
})

init()
replInput.write('')


// Helper methods

function exit() {
  console.log("\n")
  process.exit()
}

function output(on) {
  if (on)
    r.output = process.stdout
  else
    r.output = new DummyOutput()

  suppressOutput = !on
}

function init() {
  output(false)
  const subdirs = subdirsExceptLib(blocksDir); // semi needed

  (async () => {
    importFile(blocksDir, 'index.js')
    importDir('lib')
    for (const subdir of subdirs) await importDir(subdir)

    setTimeout(() => output(true), 1000)
  })()
}

async function importFile(dir, name) {
  const filepath = path.join(dir, name)

  let className = name.split('.')[0].split('_').map(s => s.capitalize()).join('')

  replInput.write(`const ${className}Module = await import('${filepath}')\n`)

  if (dir.endsWith('/lib') || dir.endsWith('blocks'))
    replInput.write(`.load ${filepath}\n`)
  else {
    replInput.write(`const ${className} = ${className}Module.default\n`)
    replInput.write(`${className}.to_s = '${className}'\n`)
    replInput.write(`${className}.toString = () => '${className}'\n`)
  }
}

function importDir(dir) {
  const dirPath = path.join(blocksDir, dir)
  fs.readdirSync(dirPath).filter(f => f.endsWith('.js')).forEach(file => {
    importFile(dirPath, file)
  })
}

function subdirsExceptLib(dir) {
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(dir => dir.isDirectory())
    .map(dir => dir.name)
    .filter(name => name != 'lib')
}
