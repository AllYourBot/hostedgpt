g.runAfter = (timeInSec, func) => {
  const timeout = new TimeoutService('setTimeout')
  const handler = setTimeout(() => {
    timeout.executed = true
    timeout.end()
    func()
  }, timeInSec*1000)

  timeout.handler = handler
  return timeout
}

g.runEvery = (timeInSec, func) => {
  const timeout = new TimeoutService('setInterval')
  const handler = setInterval(() => {
    timeout.executed = true
    func()
  }, timeInSec*1000)

  timeout.handler = handler
  return timeout
}

g.sleep = async(s) => {
  return await new Promise(r => setTimeout(r, s*1000))
}