extends V1UIViewBase
class_name MainMenuPage

# 文件职责：
# - 渲染 V1 局外入口页面。
# - 主菜单是核心 UI 页面，必须由 Rendered State 显式坐标驱动，不使用 Container 自动排版核心控件。
# - 页面只负责把固定组件拼成可交互 Godot Control，并把按钮事件转交给 V1AppController 或本页的后置提示。

const RENDERED_STATE_PATH: String = "res://data/ui/rendered_states/main_menu.rendered_state.json"
const DESIGN_SIZE: Vector2 = Vector2(1080, 2340)

var message_label: Label = null
var _nodes_by_component_id: Dictionary = {}


func refresh() -> void:
	if message_label != null and app_controller != null:
		message_label.text = app_controller.last_ui_message


func _ensure_layout() -> void:
	if _built:
		return

	_built = true
	custom_minimum_size = DESIGN_SIZE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var rendered_state: Dictionary = _load_rendered_state()
	_render_components(rendered_state)


func _load_rendered_state() -> Dictionary:
	var json_text: String = FileAccess.get_file_as_string(RENDERED_STATE_PATH)
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		return parsed
	return {
		"components": []
	}


func _render_components(rendered_state: Dictionary) -> void:
	clear_children(self)
	_nodes_by_component_id.clear()
	message_label = null

	var components: Array = rendered_state.get("components", [])
	var index: int = 0
	while index < components.size():
		var component = components[index]
		if component is Dictionary:
			_create_component(component)
		index += 1


func _create_component(component: Dictionary) -> void:
	var node_type: String = component.get("node_type", "TextureRect")
	var node: Control = null

	match node_type:
		"TextureButton":
			node = _make_texture_button(component)
		"Label":
			node = _make_label_component(component)
		_:
			node = _make_texture_rect(component)

	if node == null:
		return

	var component_id: String = component.get("component_id", "Component")
	node.name = component_id
	_apply_common_control(node, component)
	add_child(node)
	_nodes_by_component_id[component_id] = node

	if node is TextureButton:
		_bind_button_interactions(node, component)

	if component_id == "last_message_label" and node is Label:
		message_label = node


func _make_texture_rect(component: Dictionary) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = _load_texture(component)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_texture_button(component: Dictionary) -> TextureButton:
	var button := TextureButton.new()
	var texture: Texture2D = _load_texture(component)
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	return button


func _make_label_component(component: Dictionary) -> Label:
	var label := Label.new()
	label.text = component.get("text", "")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var text_style: Dictionary = component.get("text_style", {})
	var label_settings := LabelSettings.new()
	label_settings.font_size = text_style.get("font_size", 30)
	label_settings.font_color = _style_color(text_style, "font_color", Color.WHITE)
	label_settings.outline_size = text_style.get("outline_size", 0)
	label_settings.outline_color = _style_color(text_style, "outline_color", Color.BLACK)
	label_settings.shadow_size = text_style.get("shadow_size", 0)
	label_settings.shadow_color = _style_color(text_style, "shadow_color", Color.BLACK)
	label_settings.shadow_offset = Vector2(0, 2)
	label.label_settings = label_settings
	return label


func _load_texture(component: Dictionary) -> Texture2D:
	var asset_path: String = component.get("asset", "")
	if asset_path == "":
		return null

	var imported_texture := ResourceLoader.load(asset_path, "Texture2D") as Texture2D
	if imported_texture != null:
		return imported_texture

	# Godot 还未成功导入新 PNG 时，.import 可能是 valid=false，ResourceLoader 会返回空。
	# 这里保留运行时 PNG fallback，避免背景图或新组件在编辑器导入完成前显示成灰底。
	var image := Image.load_from_file(asset_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _style_color(style: Dictionary, key: String, fallback: Color) -> Color:
	var color_text: String = style.get(key, "")
	if color_text == "":
		return fallback
	return Color.from_string(color_text, fallback)


func _apply_common_control(node: Control, component: Dictionary) -> void:
	var rect: Dictionary = component.get("rect", {})
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.position = Vector2(rect.get("x", 0), rect.get("y", 0))
	node.size = Vector2(rect.get("w", 0), rect.get("h", 0))
	node.pivot_offset = node.size * 0.5
	node.visible = component.get("visible", true)
	node.z_index = component.get("z_index", 0)


func _bind_button_interactions(button: TextureButton, component: Dictionary) -> void:
	var interactions: Array = component.get("interactions", [])
	var index: int = 0
	while index < interactions.size():
		var interaction = interactions[index]
		if interaction is Dictionary and interaction.get("event", "") == "pressed":
			_bind_pressed_interaction(button, interaction)
		index += 1


func _bind_pressed_interaction(button: TextureButton, interaction: Dictionary) -> void:
	var target: String = interaction.get("target", "app_controller")
	var method: String = interaction.get("method", "")
	if method == "":
		return

	var callable := Callable()
	if target == "self":
		callable = Callable.create(self, method)
		if interaction.has("payload"):
			callable = callable.bind(interaction.get("payload", ""))
	else:
		if app_controller == null:
			return
		callable = Callable.create(app_controller, method)

	if callable.is_valid():
		button.pressed.connect(callable)


func _show_pending_message(message: String) -> void:
	if app_controller != null:
		app_controller.last_ui_message = message
	refresh()
