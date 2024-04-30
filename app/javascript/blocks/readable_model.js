export default class {
  logLevels = {
    'debug': 0,
    'info': 1,
    'warn': 2,
    'error': 3,
  }

  constructor() {
    this.attributes = {}
    this.$ = this.attributes // Define '$' as a property of 'this'
    this._haveSetDefaultAttributes = false

    this._analyzeMethods()
    this._wrapMethods()
    this._wrapGettersAndSetters()

    if (typeof this.new === 'function') this.new(...arguments)

    const self = this

    setTimeout(() => this._setAttrDefaultValues(), 0)

    return new Proxy(this, {
      get(target, prop, receiver) {
        const readerProps = self._declarationsFor('attrReader', 'attrAccessor', 'attr')
        if (readerProps.includes(prop))
          return self._setAttrDefaultValues() && receiver.$[prop]
        else
          return Reflect.get(...arguments)
      },
      set(target, prop, value, receiver) {
        const writerProps = self._declarationsFor('attrWriter', 'attrAccessor')
        if (writerProps.includes(prop))
          return receiver.$[prop] = value
        else
          return Reflect.get(...arguments)
      }
    })
  }

  _analyzeMethods() {
    this._prototype = Object.getPrototypeOf(this)
    this._descriptors = Object.getOwnPropertyDescriptors(this._prototype)
    this._properties = Object.keys(this._descriptors)
    this._allMethods = this._properties.filter(prop =>  (typeof this._descriptors[prop].value === 'function' || this._descriptors[prop].get || this._descriptors[prop].set) && prop !== 'constructor')
    this._allMethodsExceptGetterAndSetter = this._allMethods.filter(prop => !this._descriptors[prop].get && !this._descriptors[prop].set)
    this._getterMethods = this._allMethods.filter(prop => this._descriptors[prop].get)
    this._setterMethods = this._allMethods.filter(prop => this._descriptors[prop].set)
    this._getterAndSetterMethods = this._allMethods.filter(prop => this._descriptors[prop].get || this._descriptors[prop].set)
    this._callableMethods = [...this._allMethodsExceptGetterAndSetter.excluding('new'), 'log']
  }

  _wrapMethods() {
    this._allMethodsExceptGetterAndSetter.forEach(func => {
      const originalMethod = this[func]
      const methodStr = originalMethod.toString()
      const isAsync = methodStr.startsWith('async ')

      const args = methodStr.substring(methodStr.indexOf('(')+1, methodStr.indexOf(')')).split(',')
      const methodBody = methodStr.substring(methodStr.indexOf('{')+1).trim().slice(0, -1)
      const body = `
        {
          const $ = this.attributes;
          ${this._callableMethods.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
          ${this._getterMethods.map(func => 'const '+func+' = (v) => { return (typeof v == "undefined") ? Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").get() : Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").set(v); };').join("\n")}
          this._methodLog('${func}', arguments, this.${func}.length);

          ${methodBody}
        }
      `
      if (isAsync)
        this[func] = new Function(...args, `return (async function() { ${body} }).apply(this, arguments)`)
      else
        this[func] = new Function(...args, body)
    })
  }

  _wrapGettersAndSetters() {
    this._getterAndSetterMethods.forEach(func => {

      if (this._descriptors[func].get) {
        const methodBody = this._descriptors[func].get.toString().match(/{([\s\S]*)}/)[1].trim()
        const body = `
          {
            const $ = this.attributes;
            ${this._callableMethods.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
            ${this._getterMethods.map(func => 'const '+func+' = (v) => { return (typeof v == "undefined") ? Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").get() : Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").set(v); };').join("\n")}
            this._methodLog('${func}', [], 0)

            ${methodBody}
          }
        `
        this._descriptors[func].get = new Function(body).bind(this)
      }

      if (this._descriptors[func].set) {
        const methodStr = this._descriptors[func].set.toString()
        const arg = methodStr.match(/\(([^)]*)\)/)[1].trim()
        const methodBody = methodStr.match(/{([\s\S]*)}/)[1].trim()
        const body = `
          {
            const $ = this.attributes;
            ${this._callableMethods.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
            ${this._getterMethods.map(func => 'const '+func+' = (v) => { return (typeof v == "undefined") ? Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").get() : Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), "'+func+'").set(v); };').join("\n")}
            this._methodLog('${func}', [${arg}], 1);

            ${methodBody}
          }
        `
        this._descriptors[func].set = new Function(arg, body).bind(this)
      }

      Object.defineProperty(this._prototype, func, this._descriptors[func])
    })
  }

  log(str, level = 'info') {
    let logLevel
    if (node.env.isTest)
      logLevel = 'error'
    else
      logLevel = this._declarationsFor('log').first() || 'error'
    if (this.logLevels[level] >= this.logLevels[logLevel]) console.log(`${this.constructor.name}: ${str}`);
  }

  _setAttrDefaultValues() {
    // The default value of attr_* variables cannot be accessed inside the constructor. Most of the time,
    // the setTimeout with 0 hack will get it to happen at the end of the constructor but more advanced
    // class stuff can still end up skipping that. That's why we also call this within the getter as a backup.
    if (this._haveSetDefaultAttributes) return true

    const attrProps = this._declarationsFor('attr')
    attrProps.forEach(prop => {
      if (typeof this[`attr_${prop}`] != 'undefined') this.$[prop] = this[`attr_${prop}`]
    })

    this._haveSetDefaultAttributes = true
    return true
  }

  _declarationsFor(...prefixes) {
    return Object.keys(this)
        .filter(prop => prefixes.some(prefix => prop.startsWith(prefix) && prop.includes('_')))
        .map(prop => prop.split('_').splice(1))
        .flat();
  }

  _declaration(declaration, name) {
    return this[`${declaration}_${name}`]
  }

  _methodLog(name, args, numArgs) {
    const methodName = name.replace(/^_/, '') // turn _calculate into just calculate
    const logDirective = `log_${methodName}`
    let argSummary = []
    for (let i = 0; i < numArgs; i++) {
      let arg = args[i]
      if (typeof arg === 'number' || typeof arg === 'string' || typeof arg === 'boolean')
        argSummary.push(arg)
      else if (typeof arg === 'undefined')
        argSummary.push('undefined')
      else if (arg === null)
        argSummary.push('null')
      else if (typeof arg === 'function')
        argSummary.push('function')
      else if (typeof arg === 'symbol')
        argSummary.push(arg.toString())
      else if (Array.isArray(arg))
        argSummary.push('array')
      else if (typeof arg === 'object' && arg !== null && Object.getPrototypeOf(arg) === Object.prototype)
        argSummary.push('obj')
      else argSummary.push('class')
    }

    let level = 'debug'
    if (this._declarationsFor('log').includes(methodName)) {
      let logDirective = this._declaration('log', methodName)
      level = (typeof logDirective === 'string') ? logDirective : 'info'
    }

    this.log(`${name}(${argSummary.join(',')})`, level)
  }


  // _wrapGettersAndSetters() {
  //   this._callableMethods.forEach(func => this[func] = this[func].bind(this))
  //   this._getterMethods.forEach(func => this[func] = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), func).get)
  //   this._setterMethods.forEach(func => this['set'+func.capitalize()] = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), func).set)

  //   this._getterAndSetterMethods.forEach(func => {
  //     const descriptor = Object.getOwnPropertyDescriptor(this._prototype, func)

  //     if (descriptor.get) {
  //       const originalGet = descriptor.get
  //       descriptor.get = function() {
  //         const $ = this.attributes
  //         this._methodLog(func, [], 0)
  //         return originalGet.call(this)
  //       }
  //     }

  //     if (descriptor.set) {
  //       const originalSet = descriptor.set
  //       descriptor.set = function(value) {
  //         debugger
  //         const $ = this.attributes
  //         this._methodLog(func, [value], 1)
  //         originalSet.call(this, value)
  //       }
  //     }

  //     Object.defineProperty(this._prototype, func, descriptor)
  //   })
  // }
}


// Test Code:

// class Test extends ReadableModel {

//   tester() {
//     console.log(`in tester()`)

//     console.log('1. one')
//     on('on!')
//     on()
//     reallyDone()
//   }

//   set on(v) {
//     $.onValue = v
//     console.log(`2. set on() - ${$.onValue}`)
//   }

//   get on() {
//     console.log(`3. get on() - ${$.onValue}`)
//     off('off!')
//     off()
//     done()
//   }

//   set off(num) {
//     $.offValue = num
//     console.log(`4. set off() - ${$.offValue}`)
//     firstName('keith')
//     firstName()
//     movingOn()
//   }

//   set firstName(n) {
//     $.firstName = n
//     console.log(`5. set firstName() - ${$.firstName}`)
//   }

//   get firstName() {
//     console.log(`6. get firstName() - ${$.firstName}`)
//   }

//   movingOn() {
//     console.log(`7. movingOn`)
//   }

//   get off() {
//     console.log(`8. get off() - ${$.offValue}`)
//   }

//   done() {
//     console.log(`9. done!`)
//   }

//   reallyDone() {
//     console.log(`10. really done!`)
//   }
// }
// t = new Test
// t.tester()



