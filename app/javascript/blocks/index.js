((typeof window !== 'undefined' && window.mock === undefined) ? window : global).g = () => ((typeof window !== 'undefined' && window.mock === undefined) ? window : global)
g().process = (typeof process === 'undefined') ? {} : process
g().mode = (typeof window !== 'undefined' && window.mock === undefined) ? 'browser' : 'node'
g().node = {
  env: (() => {
    const env = process?.env?.NODE_ENV ?? 'development'

    // Supports all this:       node.env.
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

await importDir('lib')
for (const subdir of subdirsExceptLib('lib'))
  await importDir(subdir)

console.log(`initializing Blocks`)
initializeInterfaces()


// Private

async function importDir(type) {
  if (typeof window === 'undefined' || g() != window) return

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

async function initializeInterfaces() {
  if (typeof window === 'undefined' || g() != window) return

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
    Object.getOwnPropertyNames(Object.getPrototypeOf(g()[instanceName])).filter((name) => {
      return name[0].upcase() == name[0] && name[0] != '_'
    }).forEach(verb => {
      g()[verb] ||= {}
      if (verb == 'Flip')
        g()[verb][instanceName] = {
          on: () => g()[instanceName].Flip(true),
          off: () => g()[instanceName].Flip(false)
        }
      else
        g()[verb][instanceName] = allMethodsCall((...args) => g()[instanceName][verb](...args))
    })
  })
}

function blocksModules() {
  return Object.keys(parseImportmapJson()).filter(path => path.match(new RegExp(`^blocks/.*$`)))
}

function allModules(type) {
  return blocksModules().filter(path => path.match(new RegExp(`^blocks/${type}/.*$`)))
}

function subdirsExceptLib() {
  if (typeof window === 'undefined' || g() != window) return []
  return [...new Set(blocksModules().map(f => f.split('/').slice(-2)[0]))].filter(f => f != 'lib')
}

function parseImportmapJson() {
  return JSON.parse(document.querySelector("script[type=importmap]").text).imports
}

function allMethodsCall(actionFunction) {
    const handler = {
        get: function(target, prop, receiver) {
            return new Proxy(actionFunction, handler);
        },
        apply: function(target, thisArg, args) {
            return actionFunction(...args);
        }
    };
    return new Proxy(actionFunction, handler);
}