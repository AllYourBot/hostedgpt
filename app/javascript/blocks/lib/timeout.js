g.runAfter = (timeInSec, func) => {
  const timeout = new TimeoutService('setTimeout')
  timeout.func = () => {
    timeout.executed = true
    timeout.end()
    func()
  }
  timeout.handler = setTimeout(timeout.func, timeInSec * 1000)
  return timeout
}

g.runEvery = (timeInSec, func) => {
  const timeout = new TimeoutService('setInterval')
  timeout.func = () => {
    timeout.executed = true
    func()
  }
  timeout.handler = setInterval(timeout.func, timeInSec * 1000)
  return timeout
}

g.sleep = async(s) => {
  return await new Promise(r => setTimeout(r, s*1000))
}
