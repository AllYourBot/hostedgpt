import Service from "./service.js"

export default class extends Service {
  attrAccessor_handler
  attrAccessor_executed
  attrReader_cleared
  attrReader_type

  new(type) {
    $.executed = false
    $.cleared = false
    $.type = type
  }

  stop() {
    if (! $.handler) return
    if ($.type == 'setTimeout') clearTimeout($.handler)
    if ($.type == 'setInterval') clearInterval($.handler)
    $.handler = null
    $.cleared = true
  }

  valueOf() {
    return !!$.handler
  }
}