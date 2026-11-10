## How snails decide to boop, train up and hide. Pure logic on ground-plane positions (x, z as a
## Vector2) and unit headings, so tests can run it without a scene.
class_name SnailRules

const STYLES := ["gloss", "glitter", "chrome", "holo", "bubble"]

## Heads closer than this can boop.
const BOOP_REACH := 0.55
## How squarely two snails must face each other (dot of headings) to boop.
const BOOP_FACING := -0.6
## A leader this close ahead, and mostly in front of you, counts as being followed.
const FOLLOW_REACH := 1.8
const FOLLOW_CONE := 0.7
const FOLLOW_TIME := 2.0
## Followers keep this far apart along the leader's path.
const TRAIN_GAP := 1.1
## The train breaks up after the leader sits still this long.
const TRAIN_IDLE := 3.0
const HIDE_REACH := 1.6
const HIDE_SPEED := 1.2


## Two snails boop when their heads meet and they face each other.
static func is_boop(head_a: Vector2, dir_a: Vector2, head_b: Vector2, dir_b: Vector2) -> bool:
	if head_a.distance_to(head_b) > BOOP_REACH:
		return false
	var a_to_b := (head_b - head_a).normalized()
	return dir_a.dot(dir_b) < BOOP_FACING and dir_a.dot(a_to_b) > 0.0 and dir_b.dot(-a_to_b) > 0.0


## The follower is tailing the leader: close behind it and heading the same way.
static func is_following(follower: Vector2, follower_dir: Vector2, leader: Vector2, moving: bool) -> bool:
	if not moving:
		return false
	var to_leader := leader - follower
	if to_leader.length() > FOLLOW_REACH or to_leader.length() < 0.01:
		return false
	return follower_dir.dot(to_leader.normalized()) > FOLLOW_CONE


## A shy snail hides when a sprinting snail rushes straight at it.
static func should_hide(shy: bool, snail: Vector2, rusher: Vector2, rusher_dir: Vector2, rusher_speed: float) -> bool:
	if not shy or rusher_speed < HIDE_SPEED:
		return false
	var to_snail := snail - rusher
	return to_snail.length() < HIDE_REACH and rusher_dir.dot(to_snail.normalized()) > 0.8


## The point `distance` back along a path of points (newest first), for a train car to steer to.
static func along_path(path: PackedVector2Array, distance: float) -> Vector2:
	var left := distance
	for i in range(1, path.size()):
		var step := path[i - 1].distance_to(path[i])
		if step >= left:
			return path[i - 1].lerp(path[i], left / step)
		left -= step
	return path[path.size() - 1] if path.size() > 0 else Vector2.ZERO


## Slime material channels the ground shader reads: (glitter, chrome, holo). Bubble is a brush shape.
static func style_channels(style: String) -> Color:
	assert(style in STYLES, "unknown slime style " + style)
	match style:
		"glitter":
			return Color(1, 0, 0)
		"chrome":
			return Color(0, 1, 0)
		"holo":
			return Color(0, 0, 1)
	return Color(0, 0, 0)
