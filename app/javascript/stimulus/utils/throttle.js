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

export default function(func, wait, onDiscard) {
  let timeout, timeoutOnDiscard,  lastExecution = Date.now() - wait

  return function() {
    var context = this
    var elapsed = Date.now() - lastExecution // always positive but could be 0

    if (timeout !== null) {
      if (timeoutOnDiscard) {
        timeoutOnDiscard()
        timeoutOnDiscard = null
      }
      clearTimeout(timeout)
      timeout = null
    }

    if (elapsed >= wait) {
      func.apply(context, arguments)
      lastExecution = Date.now()
    } else {
      if (onDiscard) timeoutOnDiscard = (() => { onDiscard.apply(context, arguments); }).bind(this, ...arguments)
      timeout = setTimeout(() => {
        timeout = null
        func.apply(context, arguments)
        lastExecution = Date.now()
      }, wait - elapsed)
    }
  }
}
