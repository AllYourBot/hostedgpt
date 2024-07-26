const path = require('path')
const fs = require('fs')
import('../app/javascript/blocks/test_mocks.js')

const debug = false

beforeAll(async () => {
  const blocksDir = path.join(__dirname, '../app/javascript/blocks/')
  const subdirs = subdirsExceptLib(blocksDir)

  await importFile(blocksDir, 'index.js')

  if (debug) process.stdout.write('Loading all Blocks modules...\n')
  await importDir('lib')
  for (const subdir of subdirs) await importDir(subdir)

  if (debug) process.stdout.write('\n')

  initializeInterfaces = () => {
    const blocksPath = path.join(__dirname, '..', 'app', 'javascript', 'blocks')
    const interfacesPath = path.join(blocksPath, 'interfaces')
    const files = fs.readdirSync(interfacesPath)

    let instances = []
    for (const file of files) {
      if (file.excludes('_')) continue
      const className = file.split('_').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('').replace('.js', '')
      const instanceName = className.replace('Interface', '').replace('.js', '')

      global[instanceName] = new global[className]
      instances.push(instanceName)
    }

    instances.forEach(instanceName => {
      Object.getOwnPropertyNames(Object.getPrototypeOf(g[instanceName])).filter((name) => {
        return name[0].upcase() == name[0] && name[0] != '_'
      }).forEach(verb => {
        global[verb] ||= {}
        if (verb == 'Flip')
          global[verb][instanceName] = {
            on: () => global[instanceName].Flip(true),
            off: () => global[instanceName].Flip(false)
          }
        else
          global[verb][instanceName] = allMethodsCall((...args) => global[instanceName][verb](...args))
      })
    })
  }
})
global.allMethodsCall = (actionFunction) => {
  const handler = {
    get: function (target, prop, receiver) {
      return new Proxy(actionFunction, handler)
    },
    apply: function (target, thisArg, args) {
      return actionFunction(...args)
    }
  }
  return new Proxy(actionFunction, handler)
}

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
      global[className].to_s = className
      global[className].toString = () => className
    }
  }
}
