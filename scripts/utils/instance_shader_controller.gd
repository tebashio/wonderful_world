@tool
class_name InstanceShaderController
extends MeshInstance3D

## ===================================================================
##  Instance Shader Controller (安定版・素直なパラメータ管理)
## ===================================================================

@export_group("Glare & Glow Shell")
@export var custom_glare_color: Color = Color(0.3, 0.7, 1.0, 0.6):
	set(value):
		custom_glare_color = value
		_update_shader_param("custom_glare_color", custom_glare_color)

@export var glare_enabled: bool = true:
	set(value):
		glare_enabled = value
		_update_shader_param("glare_enabled", glare_enabled)

@export var flip_normal: bool = false:
	set(value):
		flip_normal = value
		_update_shader_param("flip_normal", flip_normal)

@export var offset: Vector3 = Vector3.ZERO:
	set(value):
		offset = value
		_update_shader_param("offset", offset)

@export var max_expand: Vector3 = Vector3(0.04, 0.04, 0.04):
	set(value):
		max_expand = value
		_update_shader_param("max_expand", max_expand)

@export var min_expand: Vector3 = Vector3(0.01, 0.01, 0.01):
	set(value):
		min_expand = value
		_update_shader_param("min_expand", min_expand)

@export_range(0.0, 1.0, 0.01) var max_alpha: float = 0.8:
	set(value):
		max_alpha = value
		_update_shader_param("max_alpha", max_alpha)

@export_range(0.0, 1.0, 0.01) var min_alpha: float = 0.2:
	set(value):
		min_alpha = value
		_update_shader_param("min_alpha", min_alpha)

@export_group("Flicker Animation")
@export_range(0.0, 20.0, 0.1) var flicker_speed: float = 3.0:
	set(value):
		flicker_speed = value
		_update_shader_param("flicker_speed", flicker_speed)

@export_range(0.0, 1.0, 0.01) var randomness: float = 0.2:
	set(value):
		randomness = value
		_update_shader_param("randomness", randomness)


func _ready() -> void:
	apply_all_parameters()


func apply_all_parameters() -> void:
	_update_shader_param("custom_glare_color", custom_glare_color)
	_update_shader_param("glare_enabled", glare_enabled)
	_update_shader_param("flip_normal", flip_normal)
	_update_shader_param("offset", offset)
	_update_shader_param("max_expand", max_expand)
	_update_shader_param("min_expand", min_expand)
	_update_shader_param("max_alpha", max_alpha)
	_update_shader_param("min_alpha", min_alpha)
	_update_shader_param("flicker_speed", flicker_speed)
	_update_shader_param("randomness", randomness)


func _update_shader_param(param_name: StringName, value: Variant) -> void:
	set_instance_shader_parameter(param_name, value)
