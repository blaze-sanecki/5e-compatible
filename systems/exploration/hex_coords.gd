class_name HexCoords
extends RefCounted

## Static utility for hex coordinate math using cube coordinates (Vector3i).
##
## Cube coordinates satisfy x + y + z = 0. Axial coordinates (Vector2i) map
## to cube as (q, r) -> (q, -q-r, r).  Pointy-top orientation assumed.

# ---------------------------------------------------------------------------
# Axial <-> Cube conversion
# ---------------------------------------------------------------------------

## Convert axial (q, r) to cube (x, y, z).
static func axial_to_cube(axial: Vector2i) -> Vector3i:
	return Vector3i(axial.x, -axial.x - axial.y, axial.y)


## Convert cube (x, y, z) to axial (q, r).
static func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.z)


# ---------------------------------------------------------------------------
# Distance
# ---------------------------------------------------------------------------

## Manhattan distance between two cube coordinates.
static func cube_distance(a: Vector3i, b: Vector3i) -> int:
	var diff: Vector3i = a - b
	return (absi(diff.x) + absi(diff.y) + absi(diff.z)) / 2


## Distance between two axial coordinates.
static func axial_distance(a: Vector2i, b: Vector2i) -> int:
	return cube_distance(axial_to_cube(a), axial_to_cube(b))


# ---------------------------------------------------------------------------
# Neighbors
# ---------------------------------------------------------------------------

## The six cube direction vectors (pointy-top).
const CUBE_DIRECTIONS: Array[Vector3i] = [
	Vector3i( 1, -1,  0),  # East
	Vector3i( 1,  0, -1),  # NE
	Vector3i( 0,  1, -1),  # NW
	Vector3i(-1,  1,  0),  # West
	Vector3i(-1,  0,  1),  # SW
	Vector3i( 0, -1,  1),  # SE
]


## Return the six neighbors of a cube coordinate.
static func cube_neighbors(center: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for dir in CUBE_DIRECTIONS:
		result.append(center + dir)
	return result


## Return a single neighbor by direction index (0-5).
static func cube_neighbor(center: Vector3i, direction: int) -> Vector3i:
	return center + CUBE_DIRECTIONS[direction % 6]


# ---------------------------------------------------------------------------
# Ring & Spiral
# ---------------------------------------------------------------------------

## Return all hexes exactly [code]radius[/code] steps from [code]center[/code].
static func cube_ring(center: Vector3i, radius: int) -> Array[Vector3i]:
	if radius <= 0:
		return [center]

	var results: Array[Vector3i] = []
	# Start at the hex radius steps in direction 4 (SW) from center.
	var hex: Vector3i = center + CUBE_DIRECTIONS[4] * radius

	for i in 6:
		for _j in radius:
			results.append(hex)
			hex = hex + CUBE_DIRECTIONS[i]

	return results


## Return all hexes within [code]radius[/code] of [code]center[/code] (inclusive).
static func cube_spiral(center: Vector3i, radius: int) -> Array[Vector3i]:
	var results: Array[Vector3i] = [center]
	for r in range(1, radius + 1):
		results.append_array(cube_ring(center, r))
	return results


# ---------------------------------------------------------------------------
# Line drawing
# ---------------------------------------------------------------------------

## Linearly interpolate between two cube coordinates (float result).
static func _cube_lerp(a: Vector3i, b: Vector3i, t: float) -> Vector3:
	return Vector3(
		lerpf(float(a.x), float(b.x), t),
		lerpf(float(a.y), float(b.y), t),
		lerpf(float(a.z), float(b.z), t),
	)


## Round a floating-point cube coordinate to the nearest integer cube hex.
static func cube_round(frac: Vector3) -> Vector3i:
	var rx: int = roundi(frac.x)
	var ry: int = roundi(frac.y)
	var rz: int = roundi(frac.z)

	var x_diff: float = absf(float(rx) - frac.x)
	var y_diff: float = absf(float(ry) - frac.y)
	var z_diff: float = absf(float(rz) - frac.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector3i(rx, ry, rz)


## Return all hexes on the line from [code]a[/code] to [code]b[/code] (inclusive).
static func cube_line(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var dist: int = cube_distance(a, b)
	if dist == 0:
		return [a]

	var results: Array[Vector3i] = []
	var inv_dist: float = 1.0 / float(dist)
	for i in range(dist + 1):
		results.append(cube_round(_cube_lerp(a, b, inv_dist * float(i))))
	return results
