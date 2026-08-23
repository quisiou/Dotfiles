-- hypr/hyprland.lua


------ LOAD ACTIVE ELYSIAN THEME ------------------------
theme = require("theme")


------ LOAD ENV VARIABLES (DEFAULT AND/OR CUSTOM) -------
require("default.env")
require("user.env")


------ LOAD VARIABLES (DEFAULT AND/OR CUSTOM) -----------
require("default.variables")
require("user.variables")


------ LOAD DEFAULT CONFIGURATION -----------------------
require("default.monitors")
require("default.look_and_feel")
require("default.input")
require("default.keybinds")
require("default.windowrules")
require("default.autostart")


----- LOAD USER OVERRIDES -------------------------------
require("user.monitors")
require("user.look_and_feel")
require("user.input")
require("user.keybinds")
require("user.windowrules")
require("user.autostart")
