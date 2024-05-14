((typeof window !== 'undefined' && window.mock === undefined) ? window : global).g = new Proxy(() => ((typeof window !== 'undefined' && window.mock === undefined) ? window : global), {
  apply: (target, thisArg, argumentsList) => target(),
  get: (target, prop, receiver) => {
    const context = target()
    if (prop in context) {
      return context[prop]
    }
    return undefined
  },
  set: (target, prop, value) => {
    const context = target()
    context[prop] = value
    return true
  }
})

g.process = (typeof process === 'undefined') ? {} : process
g.mode = (typeof window !== 'undefined' && window.mock === undefined) ? 'browser' : 'node'
g.node = {
  env: (() => {
    const env = process?.env?.NODE_ENV ?? 'development'

    const envFunc =                     () => env
    envFunc.                            toString = () => env
    Object.defineProperties(envFunc, {
                                        s: { get: () => env },
                                        isTest: { get: () => env == 'test' },
                                        isDevelopment: { get: () => env == 'development'},
    })

    // Supports:
    //
    // node.env()
    // ${node.env}
    // node.env.s
    // node.isTest
    // node.isDevelopment

    return envFunc
  })()
}

g.allMethodsCall = (actionFunction) => {
  const handler = {
      get: function(target, prop, receiver) {
          return new Proxy(actionFunction, handler)
      },
      apply: function(target, thisArg, args) {
          return actionFunction(...args)
      }
  }
  return new Proxy(actionFunction, handler)
}

// Finish init
if (g.mode == 'browser') {
  await importDir('lib')
  for (const subdir of subdirsExceptLib('lib'))
    await importDir(subdir)

  initializeInterfaces()
}

// Helpers

async function importDir(type) {
  for (const modulePath of allModules(type)) {
    const fileParts = modulePath.split('/')
    const file = fileParts[fileParts.length-1]
    const className = file.split('_').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('')
    console.log(`L: ${className} from ${modulePath}`)
    const module = await import(modulePath)
    if (type != 'lib') {
      window[className] = module.default
      window[className].to_s = className
      window[className].toString = () => className
    }
  }
}

function initializeInterfaces() {
  let instances = []
  for (const modulePath of allModules('interfaces')) {
    const fileParts = modulePath.split('/')
    const file = fileParts[fileParts.length-1]
    if (file.excludes('_')) continue
    const className = file.split('_').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('')
    const instanceName = className.replace('Interface', '')

    console.log(`instantiating: ${className}  ${instanceName}`)

    window[instanceName] = new window[className]
    instances.push(instanceName)
  }

  instances.forEach(instanceName => {
    Object.getOwnPropertyNames(Object.getPrototypeOf(g[instanceName])).filter((name) => {
      return name[0].upcase() == name[0] && name[0] != '_'
    }).forEach(verb => {
      g[verb] ||= {}
      if (verb == 'Flip')
        g[verb][instanceName] = {
          on: () => g[instanceName].Flip(true),
          off: () => g[instanceName].Flip(false)
        }
      else
        g[verb][instanceName] = g.allMethodsCall((...args) => g[instanceName][verb](...args))
    })
  })
}

function allModules(type) {
  return blocksModules().filter(path => path.match(new RegExp(`^blocks/${type}/.*$`)))
}

function blocksModules() {
  return Object.keys(parseImportmapJson()).filter(path => path.match(new RegExp(`^blocks/.*$`)))
}

function subdirsExceptLib() {
  if (typeof window === 'undefined' || g() != window) return []
  return [...new Set(blocksModules().map(f => f.split('/').slice(-2)[0]))].filter(f => f != 'lib')
}

function parseImportmapJson() {
  return JSON.parse(document.querySelector("script[type=importmap]").text).imports
}
