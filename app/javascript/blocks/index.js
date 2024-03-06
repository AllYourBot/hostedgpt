(typeof window !== 'undefined' ? window : global).g = () => (typeof window !== 'undefined' ? window : global)
g().process = (typeof process === 'undefined') ? {} : process
g().node= {
  env: (() => {
    const envFunc = () => process?.env?.NODE_ENV ?? 'development'
    envFunc.isTest = () => process?.env?.NODE_ENV === 'test'
    envFunc.isDevelopment = () => (process?.env?.NODE_ENV ?? 'development') === 'development'
    envFunc.toString = () => process?.env?.NODE_ENV ?? 'development'
    return envFunc
  })()
}

console.log('loading blocks')


// const importAll = (r) => r.keys().forEach(key => { console.log('each'); r(key) })

// importAll(context('../path_to_your_js_files', true, /\.js$/))

