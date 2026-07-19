@tool
extends Control
class_name TextureNumber

## When `value` changes, each digit slot animates by sliding the old digit
## out while the new digit slides in, like a mechanical counter/odometer.
## Toggle with `scroll_enabled`, tweak feel with `scroll_duration`,
## `scroll_transition` and `scroll_ease`.

signal value_changed(old_value: int, new_value: int)
@warning_ignore("unused_signal")
signal on_reset()

@onready var number_container : BoxContainer = BoxContainer.new()

@export var Numbers: Array[Texture2D] :
	set(new_value):
		Numbers = new_value
		_rebuild()
@export_range(1, 10, 1) var max_number: int = 10 :
	set(n_value):
		max_number = n_value
		_rebuild()

@export_range(1, 4, 1) var max_slot: int = 3 :
	set(new_value):
		max_slot = new_value
		_rebuild()
@export var do_hide_zero: bool = false :
	set(new_value):
		do_hide_zero = new_value
		update()
@export var alignement := BoxContainer.ALIGNMENT_END :
	set(new_value):
		alignement = new_value
		if number_container:
			number_container.alignment = new_value
		update()
@export var vertical : bool = false :
	set(new_value):
		vertical = new_value
		if number_container:
			number_container.vertical = new_value
		update()
@export var spacing : int = 1 :
	set(new_value): spacing = new_value ; _rebuild()
@export var number_offset : Vector2 = Vector2(0, 0) :
	set(new_value): number_offset = new_value ; _rebuild()
@export var value: int = 169:
	set(new_value):
		var old_value = value
		value = new_value
		value_changed.emit(old_value, new_value)
		update(old_value)

@export var images_slot : Array[Texture2D] = [] :
	set(new_value):
		images_slot = new_value
		_rebuild()

@export_group("Scrolling")
@export var scroll_enabled : bool = true
@export var scroll_duration : float = 0.35
@export var scroll_transition : Tween.TransitionType = Tween.TRANS_CUBIC
@export var scroll_ease : Tween.EaseType = Tween.EASE_OUT

var is_debug = false

# --- internal state ---------------------------------------------------
var _slots: Array = []            # one Dictionary per digit slot
var _digit_size: Vector2 = Vector2.ZERO
var _ready_done: bool = false


func _ready() -> void:
	if not number_container.get_parent():
		add_child(number_container)
	number_container.alignment = alignement
	number_container.vertical = vertical
	number_container.add_theme_constant_override("separation", spacing)
	number_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ready_done = true
	_build_slots()
	update(value)

	if not Engine.is_editor_hint():
		Debugger.add_text("hp_debug" + str(name), "HPDEBUG" + str(name))


# --- public entry point (also used by exported setters) ---------------
# old_value == -2147483648 (INT_MIN) means "no previous value known":
# just snap every slot to the current value with no animation.
const _NO_OLD := -2147483648

func update(old_value: int = _NO_OLD) -> void:
	if not _ready_done or not is_inside_tree():
		return
	if Numbers.is_empty():
		return
	if _slots.size() != max_slot:
		_build_slots()

	number_container.alignment = alignement
	number_container.vertical = vertical
	number_container.add_theme_constant_override("separation", spacing)

	var new_digits := _get_digits(value)

	if old_value == _NO_OLD or not scroll_enabled or Engine.is_editor_hint():
		for i in range(max_slot):
			_set_digit_instant(i, new_digits[i])
	else:
		var old_digits := _get_digits(old_value)
		for i in range(max_slot):
			if old_digits[i] != new_digits[i]:
				_animate_digit(i, old_digits[i], new_digits[i])
			else:
				_set_digit_instant(i, new_digits[i])

	_apply_hide_zero(new_digits)


func _rebuild() -> void:
	if not _ready_done:
		return
	#_build_slots()
	update()


# --- digit math ---------------------------------------------------------
func _get_digits(v: int) -> Array:
	var digits := []
	var base : int = max(max_number, 1)
	var n : int = abs(v)
	for i in range(max_slot):
		digits.push_front(n % base)
		n = int(n / base)
	return digits


# --- slot construction ----------------------------------------------------
func _build_slots() -> void:
	for child in number_container.get_children():
		number_container.remove_child(child)
		child.free()
	_slots.clear()

	if Numbers.is_empty():
		return

	_digit_size = Numbers[0].get_size()
	var base : int = max(max_number, 1)

	for i in range(max_slot):
		var slot_ctrl := Control.new()
		slot_ctrl.name = "Slot%d" % i
		slot_ctrl.custom_minimum_size = _digit_size
		slot_ctrl.clip_contents = true

		# optional background/frame texture behind the digit strip
		if i < images_slot.size() and images_slot[i]:
			var bg := TextureRect.new()
			bg.name = "Background"
			bg.texture = images_slot[i]
			bg.stretch_mode = TextureRect.STRETCH_KEEP
			bg.size = _digit_size
			bg.visible = false # Test
			slot_ctrl.add_child(bg)

		# strip holds: [dup of last digit] [digit 0..base-1] [dup of first digit]
		var strip := Control.new()
		strip.name = "Strip"
		strip.custom_minimum_size = Vector2(_digit_size.x, _digit_size.y * (base + 2))

		for row in range(base + 2):
			var digit_index := row - 1
			if digit_index < 0:
				digit_index = base - 1
			elif digit_index >= base:
				digit_index = 0

			var txr := TextureRect.new()
			txr.stretch_mode = TextureRect.STRETCH_KEEP
			txr.size = _digit_size
			txr.position = Vector2(0, row * _digit_size.y) + number_offset
			if digit_index < Numbers.size():
				txr.texture = Numbers[digit_index]
			strip.add_child(txr)

		slot_ctrl.add_child(strip)
		number_container.add_child(slot_ctrl)

		_slots.append({
			"control": slot_ctrl,
			"strip": strip,
			"digit": 0,
			"tween": null,
		})

	# The root control needs a real size or clip_contents on the slots has
	# nothing to clip against (a zero-size rect clips nothing, which is what
	# causes every digit in the strip to render stacked on top of each other).
	var total_w : float = _digit_size.x * max_slot + spacing * max(max_slot - 1, 0)
	var total_h : float = _digit_size.y * max_slot + spacing * max(max_slot - 1, 0)
	if vertical:
		custom_minimum_size = Vector2(_digit_size.x, total_h)
	else:
		custom_minimum_size = Vector2(total_w, _digit_size.y)
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = custom_minimum_size


# --- slot animation -------------------------------------------------------
## Set the slot's digit at this instant in time. (and reset position)
func _set_digit_instant(slot_i: int, digit: int) -> void:
	if slot_i >= _slots.size():
		return
	var s = _slots[slot_i]
	if s.tween and is_instance_valid(s.tween):
		s.tween.kill()
	s.digit = digit
	s.strip.position.y = -(digit + 1) * _digit_size.y


func _animate_digit(slot_i: int, old_digit: int, new_digit: int) -> void:
	if slot_i >= _slots.size():
		return
	var s = _slots[slot_i]
	var base : int = max(max_number, 1)


	# shortest signed distance around the digit wheel
	var delta := new_digit - old_digit
	delta = int(fmod(delta + base * 1000, base))
	if delta > base / 2.0:
		delta -= base

	var old_row := old_digit + 1
	var target_row := old_row + delta

	if s.tween and is_instance_valid(s.tween):
		s.tween.kill()

	if abs(old_digit - new_digit) > 1:
		s.strip.position.y = -target_row * _digit_size.y
		s.strip.position.y = -(old_digit + 1) * _digit_size.y
		s.digit = new_digit
		return

	var tw := create_tween()
	s.tween = tw
	tw.set_trans(scroll_transition).set_ease(scroll_ease)
	tw.tween_property(s.strip, "position:y", -target_row * _digit_size.y, scroll_duration)
	tw.finished.connect(func():
		s.strip.position.y = -(new_digit + 1) * _digit_size.y
		s.digit = new_digit
	)


# --- leading-zero hiding ----------------------------------------------------
func _apply_hide_zero(digits: Array) -> void:
	if _slots.is_empty():
		return
	if not do_hide_zero:
		for s in _slots:
			s.control.visible = true
		return

	var first_nonzero := digits.size() - 1
	for i in range(digits.size()):
		if digits[i] != 0:
			first_nonzero = i
			break

	for i in range(min(digits.size(), _slots.size())):
		_slots[i].control.visible = i >= first_nonzero