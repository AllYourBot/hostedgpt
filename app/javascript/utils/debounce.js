// "immediate" controls whether to execute the first call or the last call if there are multiple calls within the "wait" period
export default function(func, wait, immediate) {
  var timeout

  return function() {
    var context = this, args = arguments

    var later = function() {
      timeout = null
      if (!immediate) func.apply(context, args)
    }
    var callNow = immediate && !timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    if (callNow) func.apply(context, args)
  }
}