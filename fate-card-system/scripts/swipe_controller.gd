class_name FateCardSwipeController
extends RefCounted

var threshold := 180.0
var max_rotation_degrees := 10.0
var animation_duration := 0.28

func decision_for_offset(offset: float) -> String:
	if absf(offset) < threshold:
		return ""
	return "yes" if offset < 0.0 else "no"
