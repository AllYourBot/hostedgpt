String.prototype.capitalize = function() {
  return new String(this.charAt(0).toUpperCase() + this.slice(1))
}
String.prototype.strip = function() { return new String(this.trim()) }
String.prototype.gsub = function(...args) { return new String(this.replace(...args)) }
String.prototype.downcase = function() { return new String(this.toLowerCase()) }
String.prototype.upcase = function() { return new String(this.toUpperCase()) }
String.prototype.include = function(substring) { return this.indexOf(substring) !== -1 }
String.prototype.includes = function(substring) { return this.indexOf(substring) !== -1 }
String.prototype.exclude = function(substring) { return this.indexOf(substring) === -1 }
String.prototype.excludes = function(substring) { return this.indexOf(substring) === -1 }
String.prototype.includeAny = function(array) { return array.some(word => this.includes(word)) }
String.prototype.empty = function() { return this.length === 0 }
