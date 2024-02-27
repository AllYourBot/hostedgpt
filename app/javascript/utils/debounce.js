// debounce is typically used when a user is interacting with an element
//
// Imagine the case where a user is rage-clicking a button faster than your
// 'wait' interval. When you use debounce, it will wait until the user has
// stopped clicking so quickly and the last call to the function will
// finally execute.
//
// See throttle.js

export default function(func, wait) {
  let timeout

  return function() {
    var context = this

    clearTimeout(timeout)
    timeout = setTimeout(() => func.apply(context, arguments), wait)
  }
}
