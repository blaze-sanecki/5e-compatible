class_name UITheme

## Shared color and style constants for the RPG UI.
## Use these instead of hardcoding Color() values in individual UI scripts.

# --- Core UI Colors ---
const COLOR_TITLE: Color = Color(0.9, 0.8, 0.4)
const COLOR_SUBTITLE: Color = Color(0.6, 0.55, 0.4)
const COLOR_TEXT_MUTED: Color = Color(0.6, 0.6, 0.7)
const COLOR_SCREEN_BG: Color = Color(0.08, 0.08, 0.12, 1.0)

# --- Panel Colors ---
const COLOR_PANEL_BG: Color = Color(0.1, 0.1, 0.15, 0.95)
const COLOR_BORDER: Color = Color(0.6, 0.5, 0.3)

# --- Button Colors ---
const COLOR_BUTTON_BG: Color = Color(0.15, 0.15, 0.2, 0.9)
const COLOR_BUTTON_HOVER_BG: Color = Color(0.2, 0.2, 0.28, 0.95)
const COLOR_BUTTON_PRESSED_BG: Color = Color(0.12, 0.12, 0.16, 0.95)

# --- Feedback Colors ---
const COLOR_SUCCESS: Color = Color(0.4, 0.9, 0.4)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.4)

# --- Quest Colors ---
const COLOR_QUEST_OBJECTIVE: Color = Color(0.7, 0.7, 0.9)
const COLOR_QUEST_COMPLETE: Color = Color(0.5, 0.8, 0.5)

# --- HP Bar Colors ---
const COLOR_HP_HIGH: Color = Color(0.2, 0.7, 0.2, 0.9)
const COLOR_HP_MID: Color = Color(0.8, 0.6, 0.1, 0.9)
const COLOR_HP_LOW: Color = Color(0.8, 0.2, 0.1, 0.9)
const COLOR_HP_BG: Color = Color(0.2, 0.1, 0.1, 0.8)

# --- Overlay Colors ---
const COLOR_OVERLAY_DARK: Color = Color(0.0, 0.0, 0.0, 0.6)
const COLOR_OVERLAY_MEDIUM: Color = Color(0.0, 0.0, 0.0, 0.5)
const COLOR_OVERLAY_LIGHT: Color = Color(0.0, 0.0, 0.0, 0.4)

# --- Character/NPC Name Colors ---
const COLOR_CHAR_NAME: Color = Color(0.85, 0.82, 0.7)
const COLOR_PLAYER_NAME: Color = Color(0.5, 0.8, 1.0)
const COLOR_ENEMY_NAME: Color = Color(1.0, 0.5, 0.4)

# --- Combat Action Colors ---
const COLOR_ACTION_ATTACK: Color = Color(0.9, 0.3, 0.2)
const COLOR_ACTION_ITEM: Color = Color(0.3, 0.8, 0.6)
const COLOR_ACTION_DASH: Color = Color(0.2, 0.7, 0.9)
const COLOR_ACTION_DISENGAGE: Color = Color(0.5, 0.8, 0.3)
const COLOR_ACTION_DODGE: Color = Color(0.8, 0.7, 0.2)
const COLOR_ACTION_HIDE: Color = Color(0.6, 0.4, 0.8)
const COLOR_ACTION_END_TURN: Color = Color(0.5, 0.5, 0.5)

# --- Death Save Colors ---
const COLOR_DEATH_PANEL_BG: Color = Color(0.1, 0.05, 0.05, 0.95)
const COLOR_DEATH_PANEL_BORDER: Color = Color(0.7, 0.2, 0.2)
const COLOR_DEATH_NAME: Color = Color(1.0, 0.4, 0.4)
const COLOR_DEATH_SUCCESS: Color = Color(0.3, 0.9, 0.3)
const COLOR_DEATH_FAILURE: Color = Color(0.9, 0.3, 0.3)
const COLOR_DEATH_INACTIVE: Color = Color(0.3, 0.3, 0.3)
const COLOR_DEATH_BRIGHT_SUCCESS: Color = Color(0.3, 1.0, 0.3)
const COLOR_DEATH_BRIGHT_FAILURE: Color = Color(0.8, 0.2, 0.2)
const COLOR_DEATH_STABILIZED: Color = Color(0.5, 0.9, 0.5)
const COLOR_DEATH_SAVE_BTN: Color = Color(0.5, 0.15, 0.15)

# --- Initiative Tracker Colors ---
const COLOR_INIT_BORDER_ACTIVE: Color = Color(1.0, 0.85, 0.2)
const COLOR_INIT_BG_ACTIVE: Color = Color(0.2, 0.2, 0.1, 0.95)
const COLOR_INIT_BORDER_INACTIVE: Color = Color(0.4, 0.4, 0.5)
const COLOR_INIT_TEXT: Color = Color(0.7, 0.7, 0.7)
const COLOR_DEAD_MODULATE: Color = Color(0.5, 0.5, 0.5, 0.6)
const COLOR_COMPLETED_MODULATE: Color = Color(0.6, 0.6, 0.6)

# --- Targeting/Movement Overlay ---
const COLOR_MOVEMENT_FILL: Color = Color(0.2, 0.5, 1.0, 0.25)
const COLOR_MOVEMENT_BORDER: Color = Color(0.3, 0.6, 1.0, 0.5)
const COLOR_TARGET_FILL: Color = Color(1.0, 0.2, 0.2, 0.35)
const COLOR_TARGET_BORDER: Color = Color(1.0, 0.3, 0.3, 0.7)
const COLOR_AOE_FILL: Color = Color(1.0, 0.6, 0.1, 0.3)
const COLOR_AOE_BORDER: Color = Color(1.0, 0.7, 0.2, 0.6)

# --- Damage Numbers ---
const COLOR_DAMAGE_CRIT: Color = Color(1.0, 0.8, 0.0)
const COLOR_DAMAGE_HEAL: Color = Color(0.2, 1.0, 0.3)
const COLOR_DAMAGE_MISS: Color = Color(0.7, 0.7, 0.7)
const COLOR_DAMAGE_STATUS: Color = Color(1.0, 0.8, 0.2)

# --- Hint / Muted Text ---
const COLOR_HINT_TEXT: Color = Color(0.6, 0.6, 0.6, 0.7)
const COLOR_TEXT_LIGHT: Color = Color(0.8, 0.8, 0.85)
const COLOR_TEXT_BRIGHT: Color = Color(1.0, 1.0, 1.0, 0.9)
const COLOR_TEXT_WHITE: Color = Color(1.0, 1.0, 1.0)
const COLOR_REWARDS: Color = Color(0.8, 0.7, 0.4)

# --- Item Popup Colors ---
const COLOR_ITEM_POPUP_BG: Color = Color(0.1, 0.12, 0.18, 0.95)
const COLOR_ITEM_POPUP_BORDER: Color = Color(0.3, 0.8, 0.6)
const COLOR_ITEM_BTN_BG: Color = Color(0.15, 0.18, 0.25, 0.9)
const COLOR_ITEM_BTN_HOVER: Color = Color(0.2, 0.25, 0.35, 0.95)
const COLOR_ITEM_TEXT: Color = Color(0.9, 0.9, 0.8)
const COLOR_CANCEL_BG: Color = Color(0.2, 0.15, 0.15, 0.9)
const COLOR_CANCEL_TEXT: Color = Color(0.8, 0.6, 0.6)

# --- Skill Check Popup ---
const COLOR_SKILL_CHECK_BG: Color = Color(0.15, 0.1, 0.2, 0.95)
const COLOR_SKILL_CHECK_BORDER: Color = Color(0.7, 0.6, 0.3)

# --- Step Indicator Colors ---
const COLOR_STEP_COMPLETE: Color = Color(0.4, 0.8, 0.4)
const COLOR_STEP_CURRENT: Color = Color(1.0, 1.0, 1.0)
const COLOR_STEP_FUTURE: Color = Color(0.5, 0.5, 0.5)

# --- Log Panel ---
const COLOR_LOG_BG: Color = Color(0.08, 0.08, 0.12, 0.85)
const COLOR_LOG_BORDER: Color = Color(0.3, 0.3, 0.4)

# --- Journal ---
const COLOR_JOURNAL_BG: Color = Color(0.12, 0.12, 0.18, 0.95)

# --- Font Sizes ---
const FONT_TITLE: int = 48
const FONT_HEADING: int = 28
const FONT_SUBHEADING: int = 22
const FONT_LARGE: int = 20
const FONT_MEDIUM: int = 18
const FONT_BODY: int = 16
const FONT_SMALL: int = 14
const FONT_CAPTION: int = 13
const FONT_DETAIL: int = 12
const FONT_TINY: int = 11
const FONT_MINI: int = 10
const FONT_MICRO: int = 9
const FONT_QUEST_HEADER: int = 15
