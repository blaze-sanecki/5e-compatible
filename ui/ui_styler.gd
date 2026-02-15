class_name UIStyler

## Static utility methods for common UI styling patterns.
## Replaces duplicated _style_button() and panel style creation across UI files.


## Apply the standard RPG button theme (normal/hover/pressed states + font).
static func style_button(btn: Button, font_size: int = 16, content_margin: int = 8) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = UITheme.COLOR_BUTTON_BG
	normal.border_color = UITheme.COLOR_BORDER
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(content_margin)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UITheme.COLOR_BUTTON_HOVER_BG
	hover.border_color = UITheme.COLOR_TITLE
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = UITheme.COLOR_BUTTON_PRESSED_BG
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", UITheme.COLOR_TITLE)


## Create a standard panel StyleBoxFlat with the RPG theme.
static func create_panel_style(
	bg_color: Color = UITheme.COLOR_PANEL_BG,
	border_color: Color = UITheme.COLOR_BORDER,
	border_width: int = 2,
	corner_radius: int = 8,
	content_margin: int = 16,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(content_margin)
	return style
