g().runAfter = (timeInMs, func) => {
  const timeout = new TimeoutService('setTimeout')
  const handler = setTimeout(() => {
    timeout.executed = true
    func()
  }, timeInMs)

  timeout.handler = handler
  return timeout
}

g().runEvery = (timeInMs, func) => {
  const timeout = new TimeoutService('setInterval')
  const handler = setInterval(() => {
    timeout.executed = true
    func()
  }, timeInMs)

  timeout.handler = handler
  return timeout
}

g().sleep = async(ms) => {
  return await new Promise(r => setTimeout(r, ms))
}