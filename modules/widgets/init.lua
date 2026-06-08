local widgets = {};

-- ============================================================
-- Widget modules
-- ============================================================

widgets.name = require('modules.widgets.name');
widgets.bar = require('modules.widgets.bar');
widgets.castBar = require('modules.widgets.cast_bar');
widgets.background = require('modules.widgets.background');
widgets.text = require('modules.widgets.text');
widgets.level = require('modules.widgets.level');
widgets.id = require('modules.widgets.id');
widgets.statusIcons = require('modules.widgets.status_icons');
widgets.job = require('modules.widgets.job');
widgets.gameModeIcon = require('modules.widgets.game_mode_icon');
widgets.plateIcon = require('modules.widgets.plate_icon');
widgets.targetModule = require('modules.widgets.target_module');

return widgets;
