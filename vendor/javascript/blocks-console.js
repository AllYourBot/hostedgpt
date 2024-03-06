const repl = require('repl')
const readline = require('readline')
const stream = require('stream')
const fs = require('fs')
const path = require('path')

let cmd = ''
let suppressOutput = false


// Configure REPL

process.stdin.setRawMode(true)
process.stdin.resume()
process.stdin.setEncoding('utf8')

const replInput = new stream.PassThrough()
const rootPath = path.join(__dirname, '..', '..', 'app', 'javascript', 'blocks')
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
output(true)
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
  //output(false)
  const libPath = path.join(rootPath, 'lib');

  (async () => {
    const files = fs.readdirSync(libPath)

    for (const file of files) {
      const filePath = path.join(libPath, file)
      await import(filePath)
    }
    loadFilesFrom('services')
    // Lib is loaded for use now
    //loadFilesFrom('.')
    // loadFilesFrom('lib')
    // loadFilesFrom('controls')
    // loadFilesFrom('triggers')
  })()
}

function loadFile(fullpath) {
  [dir, filename] = fullpath.split('/').slice(-2)
  classname = filename.split('.')[0].split('_').map(s => s.capitalize()).join('')
  if (dir == 'lib')
    replInput.write(`.load ${fullpath}\n`)
  else {
    console.log(`const ${classname} = await import('${fullpath}')`)
    replInput.write(`const ${classname} = await import('${fullpath}')`)
  }
}

function loadFilesFrom(dir) {
  const dirPath = path.join(rootPath, dir)
  console.log(dirPath)
  fs.readdirSync(dirPath).forEach(file => {
    const filePath = path.join(dirPath, file)
    if (file.endsWith('.js')) loadFile(filePath)
  })
}


