String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1)
}

String.prototype.strip = function() { return this.trim() }
