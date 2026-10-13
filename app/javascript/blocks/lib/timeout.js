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

// Like runEvery but each wait is a random length between minSec and maxSec, so repeated sounds don't feel mechanical
g.runEveryBetween = (minSec, maxSec, func) => {
  const timeout = new TimeoutService('setTimeout')
  const scheduleNext = () => {
    timeout.handler = setTimeout(timeout.func, (minSec + Math.random() * (maxSec - minSec)) * 1000)
  }
  timeout.func = () => {
    timeout.executed = true
    func()
    if (!timeout.cleared) scheduleNext()
  }
  scheduleNext()
  return timeout
}

g.sleep = async(s) => {
  return await new Promise(r => setTimeout(r, s*1000))
}
