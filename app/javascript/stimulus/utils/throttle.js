// throttle is typically used when a system event will fire repeatedly
//
// Imagine the case where a user is scrolling and a scroll event is firing
// repeatedly, faster than 'wait' interval. The first call to throttle
// will execute, then every 'wait' periods it will execute the next call
// will go through. But you can also be certain the last call to throttle
// will execute, although slightly delayed so that there is a final 'wait'
// period before the execution.
//
// See debounce.js

export default function(func, wait) {
  let timeout, lastExecution = Date.now() - wait

  return function() {
    var context = this
    var elapsed = Date.now() - lastExecution // always positive but could be 0

    clearTimeout(timeout)

    if (elapsed >= wait) {
      func.apply(context, arguments)
      lastExecution = Date.now()
    } else {
      timeout = setTimeout(() => {
        func.apply(context, arguments)
        lastExecution = Date.now()
      }, wait - elapsed)
    }
  }
}
