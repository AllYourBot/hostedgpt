Array.prototype.first = function(n) { return n ? this.slice(0, n) : this[0] }
Array.prototype.second = function() { return this[1] }
Array.prototype.third = function() { return this[2] }
Array.prototype.fourth = function() { return this[3] }
Array.prototype.fifth = function() { return this[4] }
Array.prototype.sixth = function() { return this[5] }
Array.prototype.seventh = function() { return this[6] }
Array.prototype.eighth = function() { return this[7] }
Array.prototype.ninth = function() { return this[8] }
Array.prototype.tenth = function() { return this[9] }
Array.prototype.last = function(n) { return n ? this.slice(-n) : this[this.length-1] }

Array.prototype.excluding = function(...excludedValues) { return this.filter(item => !excludedValues.includes(item)) }
Array.prototype.flatten = function(...args) { return this.flat(...args) }
Array.prototype.include = function(...args) { return this.includes(...args) }
Array.prototype.exclude = function(...args) { return !this.includes(...args) }
Array.prototype.sum = function() { return this.reduce((acc, val) => acc + val, 0) }
Array.prototype.select = function(...args) { return this.filter(...args) }
Array.prototype.reject = function(callback) { return this.filter(e => !callback(e)) }
Array.prototype.uniq = function() { return [...new Set(this)] }
Array.prototype.collect = function(...args) { return this.map(...args) }