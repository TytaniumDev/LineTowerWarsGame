class_name SimMath
extends RefCounted
## Integer math helpers for the simulation, so no outcome depends on float rounding.


## Largest integer whose square is <= `value`.
static func isqrt(value: int) -> int:
	assert(value >= 0, "isqrt of a negative number")
	if value < 2:
		return value
	var x := value
	var y := (x + 1) / 2
	while y < x:
		x = y
		y = (x + value / x) / 2
	return x


## Integer division rounded up, for positive divisors.
static func ceil_div(numerator: int, denominator: int) -> int:
	return (
		-(-numerator / denominator)
		if numerator < 0
		else (numerator + denominator - 1) / denominator
	)
