# Hale Obernolte - CS 11 World of Warcraft AddOn Project

World of Warcraft is a massively multiplayer online roleplaying video game with over 12 million active
users. One factor for the game’s success is that it exposes an extensive API that allows programmers to
develop their own “AddOn” programs written in Lua and a custom XML format in order to customize the
game's user interface. This project is a collection of AddOn programs written in Lua and XML using World of
Warcraft’s API. The goal of this project is to gain experience working with a real world API, to
learn and gain more confidence in Lua, and  to develop a real-world program that will be released
open source to the game's players. to receive further feedback.

-------------------------------------------------------------------------------

## Easy Swap

This is a simple AddOn that allows players to quickly save and swap between different talent configurations
while in game. This is intended to be an introductory AddOn to familizarize myself with Lua, WoW's XML, and WoW's API.
Plyaers using the AddOn will be able to save and name their current talent configuration using the AddOn's interface.
After a talent configuration is saved, players can swap between configurations by simply clicking on their desired
saved talent configuration. Players will also be able to change to saved talent configurations through chat commands
and therefore through macros so that the talent interface does not even need to be opened to change between talent
configurations.

I expect that writing this AddOn will take the first 2-3 weeks of the term.

Easy Swap publically available on CurseForge: https://www.curseforge.com/wow/addons/easy-swap

-------------------------------------------------------------------------------

## DoT Hub

This is a more compliated AddOn that helps players track their [DoT (Damage over Time)](https://wow.gamepedia.com/Damage_over_Time#:~:text=Damage%20over%20Time%2C%20generally%20abbreviated,interval%20for%20a%20limited%20duration.&text=Some%20AoE%20effects%20also%20deal,every%20X%20seconds%2C%20in%20ticks.) spell timers across multiple
enemies. Players will be presented with a centralized hub containing a health bar for each enemy they are in combat with,
and each health bar will be accomponied by detailed times of all DoT spells that the player has on the target. This will
allow players to easily track their debuffs over multiple targets to make sure they optimize their damage by not
missing any DoT uptime.

I expect that writing this AddOn will take the remaining 7-8 weeks of the term. This is a generous estimate to allow for
time dealing with security restictions.

-------------------------------------------------------------------------------

## Stretch Goals

If I am able to complete both of these AddOns before the end of the term, as a stretch goal I would like to
attempt to “break” the game’s AddOn securities to somehow do something that I should not be allowed to do
in an AddOn (automate the player’s actions, for example). If I am able to complete all of these goals during
the term I will simply continue to develop additional AddOns.

-------------------------------------------------------------------------------

## Resources

Lua reference: [Programming In Lua](https://www.lua.org/pil/cover.html) <br />
WoW AddOn Textbook: [World of Warcraft Programming: A Guide and Reference for Creating WoW
Addons](http://garde.sylvanas.free.fr/ressources/Guides/Macros-Addons/Wiley-World.of.Warcraft.Programming.A.Guide.and.Reference.for.Creating.WoW.Addons.pdf) <br />
WoW API reference: [WoWWiki API Documentation](https://wowwiki.fandom.com/wiki/World_of_Warcraft_API)

-------------------------------------------------------------------------------
