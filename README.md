# Description
This is an auto map switcher (sourcemod plugin) for Left 4 Dead 2 Dedicated Server.

# Feature
* Automatically switch map by pre-defining a list in CFG.

# Cvar
A configuration file named "mapctrl.cfg" will automatically be created for you upon the first run in the "/cfg/sourcemod/" folder.

~~~
// "map1_end,map2_start|map2_end,map3_start|map3_end,map4_start"
// -
mapctrl_map_pair_list "c1m4_atrium,c2m1_highway|c2m5_concert,c3m1_plankcountry|c3m4_plantation,c4m1_milltown_a"
~~~

# Installation
* Put the "/plugins/mapctrl.smx" file in your "/addons/sourcemod/plugins/" folder.
