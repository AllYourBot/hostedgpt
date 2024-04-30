Number.prototype.round = function(precision = 0) {
  return Number(this.toFixed(precision))
}
