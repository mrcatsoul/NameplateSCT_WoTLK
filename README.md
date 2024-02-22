# NameplateSCT - WoTLK (3.3.5)
This adds the same style of SCT to your personal frame or anchored to your screen (depending on what is enabled).

## Install

1. [Download the package.](https://github.com/bkader/NameplateSCT_WoTLK/archive/refs/heads/main.zip)
2. Open the archive, then open folder `NameplateSCT_WoTLK-main`.
3. Extract the single folder `NameplateSCT` to `Interface\AddOns`.
4. Enjoy!

Original addon can be found here: https://www.curseforge.com/wow/addons/nameplate-scrolling-combat-text
Credits to original authors: **mpstark, Justwait**.


## About this fork

This is a fork that I published on the private server forum (https://forum.wowcircle.com/showthread.php?t=1248039)
It includes the following fixes and additional settings:

**Updates of 11.23**:

Added: Adaptation for **Awesome WotLK** (https://github.com/FrostAtom/awesome_wotlk), allowing the addon to now work correctly with all nameplates, meaning there's no need to mouseover or target each of them to retrieve guids. Without the patch, it will only work on target and mouseover, similar to **PlateBuffs**, from the nameplates from which the guids were obtained, and even then, not always.

Fixed: Rare bug where the nameplate from which the numbers were coming didn't belong to the true owner.

Added: Settings, both for personal SCT and for nameplates separately.

Added: Ex-constants, affecting visual width, height, depth, and possibly duration of animations available for customization. If any of them are set in such a way that the MAX value is lower than the MIN, warnings will be displayed in chat.

Added: "Do not show heals for nameplates" option, if enabled, only incoming healing is displayed.

Added: Rainfall reverse animation, other more complex variations beyond simply reversing rainfall could be added, but I'm not very good with formulas.

Added: Ability to set a separate animation type for healing.

Fixed: Auto-attack/healing colors not matching classic, white/green, they are now white/green.

Added: Override damage color for auto-attack/auto-shot.

Added: Max small damage/heal hit values, custom threshold maximum values for micro-damage/healing hits, below which text will be reduced in size. Value of 0 = off.

Added: Hide small damage/heal hit values, option to hide micro-damage/healing hits, although it would have been more reasonable to add an alpha channel setting, I chose to do it this way, the option was personally not useful for me.

Added: Small damage/heal hits scale, custom size for micro-damage/healing hits in %, ranging from 1 to 100.

Added: Text size is relative to max health, text size relative to the target's maximum health pool, i.e., the more damage, the larger the numbers on the screen in percentage terms, the minimum text size always remains equal to the size setting, or the size of micro-damage/healing hits if the option is enabled.

Added: Text max size, if enabled, the maximum text size will always be equal to this value and will not exceed it. If set to 0, the maximum text size will always be equal to the default size*2.

Added: Custom max health, since text size relative to the target's maximum health pool is useless when mobs have hundreds of thousands/millions of HP, you can set a custom maximum HP from which the text size will depend. For example, if you set a custom max HP to 20,000, and the text size is 20, then a damage hit of 10,000, even non-crit, will be displayed at one and a half times the size (30). If Custom max health = 0, UnitHealthMax is tracked.

Added: Blacklisted spells, a list of spell names (comma-separated **;** without spaces), hits of which will be hidden. For example, you can add **Vampiric Embrace** for priests, and as a result, eliminate spam from the healing through this spell on the screen.

Added: `ANIMATION_VERTICAL_DISTANCE_MIN`, `ANIMATION_VERTICAL_DISTANCE_MAX`, maximum height of vertical animations as a complement to the ex-constants.

Added: Dodges/misses/parries/absorbs/immunes, etc., can now be reduced in size and have the explosive effect removed when crit.

Added: Show all units hits, for fun, added an option to display hits from all units on nameplates, it turned into a mess, but it's cool :D


## FAQ for adding your own fonts

**Option 1**:
Place the font file, for example, **nazvanie123.ttf**, in the **Interface\addons\NameplateSCT\Media** folder.
Add the following line of code to the **Interface\addons\NameplateSCT\NameplateSCT.lua** file to register this font in the addon:
`SharedMedia:Register("font", "nazvanie123", [[Interface\Addons\NameplateSCT\Media\nazvanie123.ttf]])`
The same should be done for each newly added font.

**Option 2**:
Install the **SharedMedia** addon and if the required font is not found there, the same thing can be done in it:
Put the font in the **Interface\addons\SharedMedia\Media\Fonts** folder.
Register it by adding the `LSM:Register(MediaType_FONT, "nazvanie123", [[Interface\AddOns\SharedMedia\Media\Fonts\nazvanie123.ttf]])` line to **SharedMedia.lua**


## Updates of 12.23 - ...


**Updated 8.12.23**:
Added: Embiggen crits max pow sizing, determines how much crit numbers will maximally grow.

**Updated 18.12.23**:
Added: Frame strata (personal) - still don't understand how this works, if it works at all, icons still overlay frames anyway, text seems to not.

**Updated 21.12.23**:
Added: Show caster names, displays caster names + if the owner of the pet is determined, then the name of the pet's owner. Currently only for the English client, accuracy of owner determination for pets summoned not through `SPELL_SUMMON` (all constant pets like DKs, hunters) is not the best in the world.

**Updated 28.12.23**:
Added: Only target SCT, for displaying hits only on the target.
Added: Names blacklist + Enable names blacklist, blacklist of unit names for non-displaying their hits and possibly their pets too + option on/off for this thing.
Added: Names whitelist + Enable names whitelist, whitelist of names for non-displaying + option on/off for this thing.

**Updated 20.1.24**:
Added: Show absorb amount, shows absorbed damage in parentheses on/off.

**Updated 1.24**:
Added: Super-duper crappy option for overkill display.

*The added functionality has been tested only superficially, there may be errors, to find them, those who will use this version are recommended to enable lua errors display, and generally, it's better to never disable them, because detected bad code needs fixing.*
