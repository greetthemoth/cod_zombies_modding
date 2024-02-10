#include maps\_utility; 
#include common_scripts\utility; 
#include maps\_zombiemode_utility;
 
//*******************************************************************************\\
/*
MODIFIED PERKS SCRIPT FOR ZOMBIES
 
Author: F3ARxReaper666 (death_reaper0 on UGX/fourms)
 
CHANGES/ADDITIONS:
changes functions to allow perks to be customized with 1 line each
ability to add custom perks easily
automatically detects any perks in the map ran (no need to add level variables)
customisable perk slots per player (default 4)
	-level.perk_limit = 4; -base perk slot limit
	-to add a perk slot for 1 player, call 	 maps\_zombiemode_perks::give_perk_slot();  on a player
	-to change base perk limit see line 28
 
see line 81 for how to add aditional perks
 
*/
//*******************************************************************************\\
#using_animtree( "generic_human" ); 
init()
{


	level.QUICKREVIVE_ADDED_LIVES = true;					//ADDED CHANGED FOR MOD
	level.QUICKREVIVE_LIMIT_LIVES = false;
	level.QUICKREVIVE_INCREASED_REGEN = false;
	level.QUICKREVIVE_SOLO_COST_SOLO_ON = true;

	level.PERK_LEVELS = true;
		level.PERK_LEVEL_LIMIT = 1;
		if(level.ZHC_TESTING_LEVEL >= 3)
			level.PERK_LEVEL_LIMIT = 10;
		level.ZHC_PERK_LEVELS_BUYABLE = true;
		level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER = true;
		level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER_SYSTEMATIZED = false; //testo  	Makes it so all player must have cur perk level in order to buy next perk level.

	level.MUST_POWER_PERKS = true;
	if(level.ZHC_TESTING_LEVEL > 1)
		level.MUST_POWER_PERKS = false;// testo


	level thread place_additionalprimaryweapon_machine();
	level.perk_limit = 4;	//change to be perk limit for all players
	PrecacheItem( "zombie_knuckle_crack" );
	level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
	level._effect["divetonuke_groundhit"] = loadfx("maps/zombie/fx_zmb_phdflopper_exp");
	set_zombie_var( "zombie_perk_divetonuke_radius", 300 ); // WW (01/12/2011): Issue 74726:DLC 2 - Zombies - Cosmodrome - PHD Flopper - Increase the radius on the explosion (Old: 150)
	set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
	set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );
	PrecacheModel("zombie_vending_packapunch_on");
	level._effect["doubletap_light"]				= loadfx("misc/fx_zombie_cola_dtap_on");
	level._effect["marathon_light"]					= loadfx("maps/zombie/fx_zmb_cola_staminup_on");
	level._effect["divetonuke_light"]				= loadfx("misc/fx_zombie_cola_dtap_on");
	level._effect["deadshot_light"]					= loadfx("misc/fx_zombie_cola_dtap_on");
	level._effect["additionalprimaryweapon_light"]	= loadfx("misc/fx_zombie_cola_arsenal_on");
	level._effect["jugger_light"]					= loadfx("misc/fx_zombie_cola_jugg_on");
	level._effect["revive_light"]					= loadfx("misc/fx_zombie_cola_revive_on");
	level._effect["sleight_light"]					= loadfx("misc/fx_zombie_cola_on");
	level._effect["packapunch_fx"]					= loadfx("maps/zombie/fx_zombie_packapunch");
	level._effect["revive_light_flicker"]			= loadfx("maps/zombie/fx_zmb_cola_revive_flicker");
	PrecacheString( &"ZOMBIE_PERK_PACKAPUNCH" );

	// Perks-a-cola vending machine use triggers
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
 
	// Pack-A-Punch weapon upgrade machine use triggers
	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	flag_init("pack_machine_in_use");
	flag_init( "solo_game" );
 
	if( level.mutators["mutator_noPerks"] )
	{
		for( i = 0; i < vending_triggers.size; i++ )
		{
			vending_triggers[i] disable_trigger();
		}
		for( i = 0; i < vending_weapon_upgrade_trigger.size; i++ )
		{
			vending_weapon_upgrade_trigger[i] disable_trigger();
		}
		return;
	}
 
	if ( vending_triggers.size < 1 )
	{
		return;
	}
 
	if ( vending_weapon_upgrade_trigger.size >= 1 )
	{
		array_thread( vending_weapon_upgrade_trigger, ::vending_weapon_upgrade );;
	}
 
//*******************************************************************************\\
/*
all items, materials and models WILL be precached from this, no need to do it above. only fx will not be
 
add_perk( vending_machine, specialty, light_fx, machine_change, cost, perk_name, perk_name_actual, shader, bottle_weapon, short_jingle, function);
vending_machine	 - targetname on machine
specialty		 - trigger specialty (script_noteworthy)
light_fx		 - name of fx used for machine (level._effect[ -> light_fx <- ]) e.g. "zombie_vending_jugg_on"
machine_change	 - name of model to change to when powers on (CAN leave undefined if none)
cost			 - cost of the perk (should be a whole number e.g. 2500 )
perk_name		 - string of perks name e.g. "Deadshot Daquari" (leave undefined if string is already made e.g. &"ZOMBIE_PERK_JUGGERNAUT")
perk_name_actual - use this if above is undefined ONLY! should be used if string exists e.g. "ZOMBIE_PERK_JUGGERNAUT"
shader			 - name of icon to show up in game e.g. "specialty_juggernaut_zombies"
bottle_weapon	 - name of bottle used when drinking e.g. "zombie_perk_bottle_jugg"
short_jingle	 - name of jingle to play upon purchase e.g. "mx_jugger_sting"
function		 - threaded fuction that will only play if perk exists e.g. ::my_fuction
 
add_custom_perk( vending_machine, specialty, light_fx, machine_change, cost, perk_name, perk_name_actual, shader, bottle_weapon, short_jingle, function);
 -same as everything above, but WILL NOT need a specific specialty, instead saves to an array on player
 -for these perks, you will need different checks for if the player has it (listed below)
 
HasPerk( specialty_NAME )		-|-	will become	-|-		maps\_zombiemode_perks::HasCustomPerk( specialty_NAME )
UnsetPerk( specialty_NAME )		-|-	will become	-|-		maps\_zombiemode_perks::UnsetCustomPerk( specialty_NAME )
SetPerk( specialty_NAME )		-|-	will become	-|-		maps\_zombiemode_perks::SetCustomPerk( specialty_NAME )
 
extra fuctions for custom specialty perks
maps\_zombiemode_perks::IsCustomPerk( specialty_NAME )		- returns true if specialty is listed as a custom specialty
maps\_zombiemode_perks::CreateCustomPerk( specialty_NAME )	- shouldnt be needed, but this will create a custom specialty (add_custom_perk() will automaticly use this)
maps\_zombiemode_perks::HasThePerk( specialty_NAME )		- finds out if player has that perk as custom or normal (it will find out if its custom or normal for you)
*/
//*******************************************************************************\\
 
 //changed for mod //mule kick cost //dt cost
	//	 				   vending_machine, specialty, 			  light_fx, 	  machine_change, 		   cost, perk_name, perk_name_actual,		 	shader, 					   bottle_weapon,			   short_jingle,	 function
	level thread add_perk("vending_jugg", "specialty_armorvest", "jugger_light", "zombie_vending_jugg_on", 2500, undefined, &"ZOMBIE_PERK_JUGGERNAUT", "specialty_juggernaut_zombies", "zombie_perk_bottle_jugg", "mx_jugger_sting", undefined);
	level thread add_perk("vending_sleight", "specialty_fastreload", "sleight_light", "zombie_vending_sleight_on", 3000, undefined, &"ZOMBIE_PERK_FASTRELOAD", "specialty_fastreload_zombies", "zombie_perk_bottle_sleight", "mx_speed_sting", undefined);
	level thread add_perk("vending_doubletap", "specialty_rof", "doubletap_light", "zombie_vending_doubletap_on", 2000, undefined, &"ZOMBIE_PERK_DOUBLETAP", "specialty_doubletap_zombies", "zombie_perk_bottle_doubletap", "mx_doubletap_sting", undefined);
	level thread add_perk("vending_revive", "specialty_quickrevive", "revive_light", "zombie_vending_revive_on", 1500, undefined, &"ZOMBIE_PERK_QUICKREVIVE", "specialty_quickrevive_zombies", "zombie_perk_bottle_revive", "mx_revive_sting", undefined);	
	
	level thread add_perk("vending_divetonuke", "specialty_flakjacket", "divetonuke_light", "zombie_vending_nuke_on", 2000, "PHD Flopper", undefined, "specialty_divetonuke_zombies", "zombie_perk_bottle_nuke", undefined, undefined);	
	level thread add_perk("vending_marathon", "specialty_longersprint", "marathon_light", "zombie_vending_marathon_on", 2000, "Stamin-Up", undefined, "specialty_marathon_zombies", "zombie_perk_bottle_marathon", undefined, undefined);	
	level thread add_perk("vending_deadshot", "specialty_deadshot", "deadshot_light", "zombie_vending_ads_on", 1000, "Deadshot Daquari", undefined, "specialty_ads_zombies", "zombie_perk_bottle_deadshot", undefined, undefined);	
	level thread add_perk("vending_additionalprimaryweapon", "specialty_additionalprimaryweapon", "additionalprimaryweapon_light", "zombie_vending_three_gun_on", 2000, "Mule Kick", undefined, "specialty_extraprimaryweapon_zombies", "zombie_perk_bottle_additionalprimaryweapon", undefined, undefined);	
 	



	//level thread add_custom_perk("vending_bulletdamage", "specialty_bulletdamage", "revive_light", undefined, 3000, "Tufbrew", undefined, "specialty_tufbrew_zombies", "zombie_perk_bottle_doubletap", undefined, undefined);
	level thread add_custom_perk("vending_chamberfill", "specialty_killbulletload", "doubletap_light", undefined, 2000, "Chamberwick Champagne", undefined, "specialty_chamberfill_zombies", "zombie_perk_bottle_doubletap", undefined, undefined);
	level thread add_custom_perk("vending_bucha", "specialty_knifeescape", "jugger_light", undefined, 1500, "Bucha", undefined, "specialty_bucha_zombies", "zombie_perk_bottle_doubletap", undefined, undefined);
	//level thread add_custom_perk("vending_bulletaccuracy", "specialty_bulletaccuracy", "sleight_light", undefined, 2500, "Candolier Soda", undefined, "specialty_candolier_zombies", "zombie_perk_bottle_sleight", undefined, undefined);

 
 	//if(level.PERK_LEVELS){
 		//maps\_zombiemode::register_player_damage_callback(::player_damaged_func);
 	//	maps\_zombiemode_spawner::register_zombie_damage_callback(::zombie_damage_not_killed_func); //Bucha perk, knifed zombies turn into crawlers.
 	//}
	//maps\_zombiemode::register_player_damage_callback(::player_damaged_func);
	//maps\_zombiemode_spawner::register_zombie_damage_callback(::zombie_damage_not_killed_func); //Bucha perk, knifed zombies turn into crawlers.
	//level thread candolier();	//bandolier perk, 2 extra clips of ammo for each gun, add to weapon files of each gun

 
 
 
	//Perks machine
	if( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}
 
	set_zombie_var( "zombie_perk_cost",					2000 );
	if( level.mutators["mutator_susceptible"] )
	{
		set_zombie_var( "zombie_perk_juggernaut_health",	80 );
		set_zombie_var( "zombie_perk_juggernaut_health_upgrade",	95 );
	}
	else
	{
		set_zombie_var( "zombie_perk_juggernaut_health",	160 );
		//set_zombie_var( "zombie_perk_juggernaut_health",	125 );
		set_zombie_var( "zombie_perk_juggernaut_health_upgrade",	190 );
		//set_zombie_var( "zombie_perk_juggernaut_health_upgrade",	150 );
	}
 
	array_thread( vending_triggers, ::vending_trigger_think );
	array_thread( vending_triggers, ::electric_perks_dialog );
 
	level thread turn_PackAPunch_on();
	level thread perk_slot_setup();
 
	if ( isdefined( level.quantum_bomb_register_result_func ) )
	{
		[[level.quantum_bomb_register_result_func]]( "give_nearest_perk", ::quantum_bomb_give_nearest_perk_result, 10, ::quantum_bomb_give_nearest_perk_validation );
	}
}

get_jug_health(upgrade){
	if(is_true(upgrade))
		return  100 + level.zombie_damage + level.zombie_damage;
	return 100 + level.zombie_damage;
	if(is_true(upgrade))
		return  level.zombie_vars["zombie_perk_juggernaut_health_upgrade"];
	return level.zombie_vars["zombie_perk_juggernaut_health"];
}
 
 
place_additionalprimaryweapon_machine()
{	
	if
	//while 
	( !isdefined( level.zombie_additionalprimaryweapon_machine_origin ) )
	{
		//IPrintLnBold( "WAITING FOR INF0" );
		//wait_network_frame();
		return;
	}
 
	machine = Spawn( "script_model", level.zombie_additionalprimaryweapon_machine_origin );
	machine.angles = level.zombie_additionalprimaryweapon_machine_angles;
	machine setModel( "zombie_vending_three_gun" );
	machine.targetname = "vending_additionalprimaryweapon";
 
	machine_trigger = Spawn( "trigger_radius_use", level.zombie_additionalprimaryweapon_machine_origin + (0, 0, 30), 0, 20, 70 );
	machine_trigger.targetname = "zombie_vending";
	machine_trigger.target = "vending_additionalprimaryweapon";
	machine_trigger.script_noteworthy = "specialty_additionalprimaryweapon";
 
	if ( isdefined( level.zombie_additionalprimaryweapon_machine_clip_origin ) )
	{
		machine_clip = spawn( "script_model", level.zombie_additionalprimaryweapon_machine_clip_origin );
		machine_clip.angles = level.zombie_additionalprimaryweapon_machine_clip_angles;
		machine_clip setmodel( "collision_geo_64x64x256" );
		machine_clip Hide();
	}
 
	if ( isdefined( level.zombie_additionalprimaryweapon_machine_monkey_origins ) )
	{
		machine.target = "vending_additionalprimaryweapon_monkey_structs";
		for ( i = 0; i < level.zombie_additionalprimaryweapon_machine_monkey_origins.size; i++ )
		{
			machine_monkey_struct = SpawnStruct();
			machine_monkey_struct.origin = level.zombie_additionalprimaryweapon_machine_monkey_origins[i];
			machine_monkey_struct.angles = level.zombie_additionalprimaryweapon_machine_monkey_angles;
			machine_monkey_struct.script_int = i + 1;
			machine_monkey_struct.script_notetworthy = "cosmo_monkey_additionalprimaryweapon";
			machine_monkey_struct.targetname = "vending_additionalprimaryweapon_monkey_structs";
 
			if ( !IsDefined( level.struct_class_names["targetname"][machine_monkey_struct.targetname] ) )
			{
				level.struct_class_names["targetname"][machine_monkey_struct.targetname] = [];
			}
 
			size = level.struct_class_names["targetname"][machine_monkey_struct.targetname].size;
			level.struct_class_names["targetname"][machine_monkey_struct.targetname][size] = machine_monkey_struct;
		}
	}
 
	level.zombiemode_using_additionalprimaryweapon_perk = true;
}
 
HasThePerk( perk )
{
	p = false;
	if(IsCustomPerk(perk)){
		if(self HasCustomPerk( perk ))
			p = true;
	}
	else{
		if(self HasPerk( perk ))
			p = true;
	}
	return p;
}

CanAddPerkLevel(perk){
	if(self.num_perks >= level.perk_limit+self.perk_slots){
		//IPrintLn( "out of slots" );
		return false;
	}
	//no_perk_level = perk == "specialty_marathon" || perk == "specialty_fastreload" ;
	//if(no_perk_level)
	//	return false;
	cur = self GetPerkLevel(perk);


	curlimit = level.PERK_LEVEL_LIMIT;
	hardlimit = 1;
	if(perk == "specialty_quickrevive"){
		hardlimit = 3;
	}
	if(perk == "specialty_armorvest"){
		hardlimit = 3;
		curlimit /= 2;
	}
	else if(perk == "specialty_additionalprimaryweapon"){
		hardlimit = 3;
	}
	else if(perk == "specialty_rof"){
		hardlimit = 10;
	}
	else if(perk == "specialty_flakjacket"){
		hardlimit = 5;
		curlimit /= 3;
	}
	limit = min(hardlimit, max(1,curlimit) );
	if(cur >= limit){
		//IPrintLn( "max level" );
		return false;
	}
	return true;
}

GetPerkCost(perk, perk_level){
	players = get_players();
	if(!(perk == "specialty_quickrevive" && level.QUICKREVIVE_SOLO_COST_SOLO_ON && players.size == 1 && !level.QUICKREVIVE_LIMIT_LIVES))
		return level.zombie_perks[perk].cost * perk_level;
	else{
		cost = 500;

		if(!level.QUICKREVIVE_LIMIT_LIVES)
		{
			i = 0;
			//("solo_lives_given: "+level.solo_lives_given);
			while(i < level.solo_lives_given){
				cost *= 3;
				i++;
			} 		
			//cost: 500, 1500, 4500, 13500...


			/*cost1 = 500;
			cost2 = 1500;
			i = 0;
			IPrintLnBold( (level.solo_lives_given) );
			while(i < level.solo_lives_given){
				if(i % 2 == 1){
					cost = cost2;
					cost2 *= 10;
				}else{
					cost1 *= 10;
					cost = cost1;
				}
				i++;
			}*/
			//cost: 500, 1500, 5000, 15000...
		}
		return int(cost); //anouther thread sets the cost
	}
}

GetPerkLevel( specialty )
{
	if(!isdefined(self.perk_level_array))
		self.perk_level_array = [];
	
	if(isdefined(self.perk_level_array[specialty]))
		return self.perk_level_array[specialty];
	else
		return 0;
}

AddPerkLevel( specialty )
{
	if(!isdefined(self.perk_level_array))
		self.perk_level_array = [];


	if(!isdefined(self.perk_level_array[specialty])){
		//( "undefined_var. now defined" );
		self.perk_level_array[specialty] = 0;
	}
	self.num_perks++;
	self.perk_level_array[specialty]++;
}

RemovePerkLevel( specialty )
{
	if(!isdefined(self.perk_level_array))
		self.perk_level_array = [];

	if(!isdefined(self.perk_level_array[specialty]) || self.perk_level_array[specialty] == 0)
		return;

	self.num_perks--;
	self.perk_level_array[specialty]--;
}

RemoveALLPerkLevel( specialty )
{
	if(!isdefined(self.perk_level_array))
		self.perk_level_array = [];

	if(!isdefined(self.perk_level_array[specialty]) || self.perk_level_array[specialty] == 0)
		return;
	self.num_perks -= GetPerkLevel(specialty);
	self.perk_level_array[specialty] = 0;
}

CreateCustomPerk( specialty )
{
	if(!isdefined(level.custom_perk_array))
		level.custom_perk_array = [];

	level.custom_perk_array[specialty] = true;
}
 
IsCustomPerk( specialty )
{
	if(isdefined(level.custom_perk_array))
//		for ( i = 0; i < level.custom_perk_array.size; i++ )
			if(isdefined(level.custom_perk_array[specialty]) && level.custom_perk_array[specialty] == true)
				return true;
	return false;
}
 
HasCustomPerk( specialty )
{
	if(!isdefined(self.custom_perk_array))
		self.custom_perk_array = [];
	if(isdefined(self.custom_perk_array))
//		for ( i = 0; i < self.custom_perk_array.size; i++ )
			if(isdefined(self.custom_perk_array[specialty]) && self.custom_perk_array[specialty] == true)
				return true;
	return false;	
}
 
SetCustomPerk( specialty )
{
	if(!isdefined(self.custom_perk_array))
		self.custom_perk_array = [];
	self.custom_perk_array[specialty] = true;
}
 
UnsetCustomPerk( specialty )
{
	if(!isdefined(self.custom_perk_array))
		self.custom_perk_array = [];
	self.custom_perk_array[specialty] = undefined;
}
 
add_custom_perk(vending_machine, specialty, light_fx, machine_change, cost, perk_name, perk_name_actual, shader, bottle_weapon, sound, function)
{
	CreateCustomPerk( specialty );
	level thread add_perk(vending_machine, specialty, light_fx, machine_change, cost, perk_name, perk_name_actual, shader, bottle_weapon, sound, function);	
}
 
add_perk(vending_machine, specialty, light_fx, machine_change, cost, perk_name, perk_name_actual, shader, bottle_weapon, sound, function)
{
	if (!isdefined(level.zombie_perks))
		level.zombie_perks = [];
	if (!isdefined(level.perk_total))
		level.perk_total =0;
	//make sure the map uses this perk
	perk_exists = false;
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;
		if (perk == specialty)
			perk_exists = true;
	}	
	if (!perk_exists) return;
	level.perk_total +=1;
	if(isDefined(machine_change))
		PrecacheModel(machine_change);
	if(IsDefined( machine_change ) && level.MUST_POWER_PERKS){
		og_machine = GetSubStr( machine_change, 0 , machine_change.size-2 ) + "off";
		//og_machine = GetSubStr( machine_change, 0 , machine_change.size-3 );

		PrecacheModel( og_machine );
	}
	if(isDefined(bottle_weapon))
		PrecacheItem(bottle_weapon);
	level thread turn_perk_on(vending_machine, specialty, light_fx, machine_change);
	perk = SpawnStruct();
	if(isDefined(perk_name_actual))
	{
		PrecacheString( perk_name_actual );
		perk.perk_name_actual = perk_name_actual;
	}
	else
		perk.perk_name = perk_name;
	perk.cost = cost;
	perk.bottle_weapon = bottle_weapon;
	PrecacheShader( shader );
	perk.shader = shader;
	if (isDefined(sound))
		perk.sound = sound;
	level.zombie_perks[specialty] = perk;
	if (isDefined(function))
		level thread [[function]]();
}
 
third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine )
{
	forward = anglesToForward( angles );
	interact_pos = origin + (forward*-25);
	PlayFx( level._effect["packapunch_fx"], origin+(0,1,-34), forward );
 
	worldgun = spawn( "script_model", interact_pos );
	worldgun.angles  = self.angles;
	worldgun setModel( GetWeaponModel( current_weapon ) );
	worldgun useweaponhidetags( current_weapon );
	worldgun rotateto( angles+(0,90,0), 0.35, 0, 0 );
 
	offsetdw = ( 3, 3, 3 );
	worldgundw = undefined;
	if ( maps\_zombiemode_weapons::weapon_is_dual_wield( current_weapon ) )
	{
		worldgundw = spawn( "script_model", interact_pos + offsetdw );
		worldgundw.angles  = self.angles;
 
		worldgundw setModel( maps\_zombiemode_weapons::get_left_hand_weapon_model_name( current_weapon ) );
		worldgundw useweaponhidetags( current_weapon );
		worldgundw rotateto( angles+(0,90,0), 0.35, 0, 0 );
	}
 
	wait( 0.5 );
 
	worldgun moveto( origin, 0.5, 0, 0 );
	if ( isdefined( worldgundw ) )
	{
		worldgundw moveto( origin + offsetdw, 0.5, 0, 0 );
	}
 
	self playsound( "zmb_perks_packa_upgrade" );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles+(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.35 );
 
	worldgun delete();
	if ( isdefined( worldgundw ) )
	{
		worldgundw delete();
	}
 
	wait( 3 );
 
	self playsound( "zmb_perks_packa_ready" );
 
	worldgun = spawn( "script_model", origin );
	worldgun.angles  = angles+(0,90,0);
	worldgun setModel( GetWeaponModel( level.zombie_weapons[current_weapon].upgrade_name ) );
	worldgun useweaponhidetags( level.zombie_weapons[current_weapon].upgrade_name );
	worldgun moveto( interact_pos, 0.5, 0, 0 );
 
	worldgundw = undefined;
	if ( maps\_zombiemode_weapons::weapon_is_dual_wield( level.zombie_weapons[current_weapon].upgrade_name ) )
	{
		worldgundw = spawn( "script_model", origin + offsetdw );
		worldgundw.angles  = angles+(0,90,0);
 
		worldgundw setModel( maps\_zombiemode_weapons::get_left_hand_weapon_model_name( level.zombie_weapons[current_weapon].upgrade_name ) );
		worldgundw useweaponhidetags( level.zombie_weapons[current_weapon].upgrade_name );
		worldgundw moveto( interact_pos + offsetdw, 0.5, 0, 0 );
	}
 
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles-(179, 0, 0), 0.25, 0, 0 );
	}
 
	wait( 0.5 );
 
	worldgun moveto( origin, level.packapunch_timeout, 0, 0);
	if ( isdefined( worldgundw ) )
	{
		worldgundw moveto( origin + offsetdw, level.packapunch_timeout, 0, 0);
	}
 
	worldgun.worldgundw = worldgundw;
	return worldgun;
}
 
 
vending_machine_trigger_think()
{
	self endon("death");
 
	while(1)
	{
		players = get_players();
 
		for(i = 0; i < players.size; i ++)
		{
			if ( players[i] hacker_active() )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], false );
			}		
		}
		wait(0.1);
	}
}
 
//
//	Pack-A-Punch Weapon Upgrade
//
vending_weapon_upgrade()
{
	perk_machine = GetEnt( self.target, "targetname" );
	perk_machine_sound = GetEntarray ( "perksacola", "targetname");
	packa_rollers = spawn("script_origin", self.origin);
	packa_timer = spawn("script_origin", self.origin);
	packa_rollers LinkTo( self );
	packa_timer LinkTo( self );
 
	if( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = GetEnt( perk_machine.target, "targetname" );
	}
 
	self UseTriggerRequireLookAt();
	self SetHintString( &"ZOMBIE_NEED_POWER" );
	self SetCursorHint( "HINT_NOICON" );
 
	level waittill("Pack_A_Punch_on");
 
	self thread vending_machine_trigger_think();
 
	self thread maps\_zombiemode_weapons::decide_hide_show_hint();
 
	perk_machine playloopsound("zmb_perks_packa_loop");
 
	self thread vending_weapon_upgrade_cost();
 
	for( ;; )
	{
		self waittill( "trigger", player );		
 
		index = maps\_zombiemode_weapons::get_player_index(player);	
		plr = "zmb_vox_plr_" + index + "_";
		current_weapon = player getCurrentWeapon();
 
		if ( "microwavegun_zm" == current_weapon )
		{
			current_weapon = "microwavegundw_zm";
		}
 
		if( !player maps\_zombiemode_weapons::can_buy_weapon() ||
			player maps\_laststand::player_is_in_laststand() ||
			is_true( player.intermission ) ||
			player isThrowingGrenade() ||
			player maps\_zombiemode_weapons::is_weapon_upgraded( current_weapon ) )
		{
			wait( 0.1 );
			continue;
		}
 
		if( is_true(level.pap_moving)) //can't use the pap machine while it's being lowered or raised
		{
			continue;
		}
 
 		if( player isSwitchingWeapons() )
 		{
 			wait(0.1);
 			continue;
 		}
 
		if ( !IsDefined( level.zombie_include_weapons[current_weapon] ) )
		{
			continue;
		}
 
		if ( player.score < self.cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			continue;
		}
 
		flag_set("pack_machine_in_use");
 
		player maps\_zombiemode_score::minus_to_player_score( self.cost ); 
		sound = "evt_bottle_dispense";
		playsoundatposition(sound, self.origin);
 
		//TUEY TODO: Move this to a general init string for perk audio later on
		self thread maps\_zombiemode_audio::play_jingle_or_stinger("mus_perks_packa_sting");
		player maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
 
		origin = self.origin;
		angles = self.angles;
 
		if( isDefined(perk_machine))
		{
			origin = perk_machine.origin+(0,0,35);
			angles = perk_machine.angles+(0,90,0);
		}
 
		self disable_trigger();
 
		player thread do_knuckle_crack();
 
		// Remember what weapon we have.  This is needed to check unique weapon counts.
		self.current_weapon = current_weapon;
 
		weaponmodel = player third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine );
 
		self enable_trigger();
		self SetHintString( &"ZOMBIE_GET_UPGRADED" );
		self setvisibletoplayer( player );
 
		self thread wait_for_player_to_take( player, current_weapon, packa_timer );
		self thread wait_for_timeout( current_weapon, packa_timer );
 
		self waittill_either( "pap_timeout", "pap_taken" );
 
		self.current_weapon = "";
		if ( isdefined( weaponmodel.worldgundw ) )
		{
			weaponmodel.worldgundw delete();
		}
		weaponmodel delete();
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		self setvisibletoall();
		flag_clear("pack_machine_in_use");
 
	}
}
 
 
vending_weapon_upgrade_cost()
{
	while ( 1 )
	{
		self.cost = 5000;
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
 
		level waittill( "powerup bonfire sale" );
 
		self.cost = 1000;
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
 
		level waittill( "bonfire_sale_off" );
	}
}
 
 
//	
//
wait_for_player_to_take( player, weapon, packa_timer )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon] ), "wait_for_player_to_take: weapon does not exist" );
	AssertEx( IsDefined( level.zombie_weapons[weapon].upgrade_name ), "wait_for_player_to_take: upgrade_weapon does not exist" );
 
	upgrade_weapon = level.zombie_weapons[weapon].upgrade_name;
 
	self endon( "pap_timeout" );
	while( true )
	{
		packa_timer playloopsound( "zmb_perks_packa_ticktock" );
		self waittill( "trigger", trigger_player );
		packa_timer stoploopsound(.05);
		if( trigger_player == player ) 
		{
			current_weapon = player GetCurrentWeapon();
/#
if ( "none" == current_weapon )
{
	iprintlnbold( "WEAPON IS NONE, PACKAPUNCH RETRIEVAL DENIED" );
}
#/
			if( is_player_valid( player ) && !player is_drinking() && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && "syrette_sp" != current_weapon && "none" != current_weapon && !player hacker_active())
			{
				self notify( "pap_taken" );
				player notify( "pap_taken" );
				player.pap_used = true;
 
				weapon_limit = level.zhc_starting_weapon_slots;
				if ( player HasPerk( "specialty_additionalprimaryweapon" ) )
				{
					weapon_limit = level.zhc_starting_weapon_slots+1;
					if(level.PERK_LEVELS){
						weapon_limit = level.zhc_starting_weapon_slots + player GetPerkLevel("specialty_additionalprimaryweapon");
					}
				}
 
				primaries = player GetWeaponsListPrimaries();
				if( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					player maps\_zombiemode_weapons::weapon_give( upgrade_weapon );
				}
				else
				{
					player GiveWeapon( upgrade_weapon, 0, player maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
					player maps\ZHC_zombiemode_zhc::give_weapon(upgrade_weapon);
					player GiveStartAmmo( upgrade_weapon );
				}
 
				player SwitchToWeapon( upgrade_weapon );
				player maps\_zombiemode_weapons::play_weapon_vo(upgrade_weapon);
				return;
			}
		}
		wait( 0.05 );
	}
}
 
 
//	Waiting for the weapon to be taken
//
wait_for_timeout( weapon, packa_timer )
{
	self endon( "pap_taken" );
 
	wait( level.packapunch_timeout );
 
	self notify( "pap_timeout" );
	packa_timer stoploopsound(.05);
	packa_timer playsound( "zmb_perks_packa_deny" );
 
	maps\_zombiemode_weapons::unacquire_weapon_toggle( weapon );
}
 
 
//	Weapon has been inserted, crack knuckles while waiting
//
do_knuckle_crack()
{
	gun = self upgrade_knuckle_crack_begin();
 
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
 
	self upgrade_knuckle_crack_end( gun );
 
}
 
 
//	Switch to the knuckles
//
upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();
 
	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowCrouch( true );
	self AllowProne( false );
	self AllowMelee( false );
 
	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}
 
	primaries = self GetWeaponsListPrimaries();
 
	gun = self GetCurrentWeapon();
	weapon = "zombie_knuckle_crack";
 
	if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self notify( "zmb_lost_knife" );
		self maps\ZHC_zombiemode_zhc::take_weapon(gun);
		self TakeWeapon( gun );
	}
	else
	{
		return;
	}
 
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
 
	return gun;
}
 
//	Anim has ended, now switch back to something
//
upgrade_knuckle_crack_end( gun )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "zombie_perk_bottle_marathon" );
	assert( gun != "zombie_perk_bottle_nuke" );
	assert( gun != "zombie_perk_bottle_deadshot" );
	assert( gun != "zombie_perk_bottle_additionalprimaryweapon" );
	assert( gun != "syrette_sp" );
 
	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );		
	self AllowMelee( true );
	weapon = "zombie_knuckle_crack";
 
	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}
 
	self decrement_is_drinking();
 
	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if( self is_drinking() )
	{
		return;
	}
	else if( isDefined( primaries ) && primaries.size > 0 )
	{
		self SwitchToWeapon( primaries[0] );
	}
	else
	{
		self SwitchToWeapon( level.laststandpistol );
	}
}
 
// PI_CHANGE_BEGIN
//	NOTE:  In the .map, you'll have to make sure that each Pack-A-Punch machine has a unique targetname
turn_PackAPunch_on()
{
	level waittill("Pack_A_Punch_on");
 
	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0; i<vending_weapon_upgrade_trigger.size; i++ )
	{
		perk = getent(vending_weapon_upgrade_trigger[i].target, "targetname");
		if(isDefined(perk))
		{
			perk thread activate_PackAPunch();
		}
	}
}
 
activate_PackAPunch()
{
	self setmodel("zombie_vending_packapunch_on");
	self playsound("zmb_perks_power_on");
	self vibrate((0,-100,0), 0.3, 0.4, 3);
	/*
	self.flag = spawn( "script_model", machine GetTagOrigin( "tag_flag" ) );
	self.angles = machine GetTagAngles( "tag_flag" );
	self.flag setModel( "zombie_sign_please_wait" );
	self.flag linkto( machine );
	self.flag.origin = (0, 40, 40);
	self.flag.angles = (0, 0, 0);
	*/
	timer = 0;
	duration = 0.05;
 
	level notify( "Carpenter_On" );
}
// PI_CHANGE_END
 
 
 
//############################################################################
//		P E R K   M A C H I N E S
//############################################################################
 
//
//	Threads to turn the machines to their ON state.
//
 
turn_perk_on(vending_machine, specialty, light_fx, machine_change)
{
	machine = getentarray(vending_machine, "targetname");
	og_machine = GetSubStr( machine_change, 0 , machine_change.size-2 ) + "off";
	//og_machine = GetSubStr( machine_change, 0 , machine_change.size-3 );
	
	must_be_powered = level.MUST_POWER_PERKS;

	flag_wait( "all_players_connected" );
	players = get_players();


	if(players.size == 1 && specialty == "specialty_quickrevive" && level.QUICKREVIVE_SOLO_COST_SOLO_ON)
	{
		must_be_powered = false;
		machine_model = undefined;
		machine_clip = undefined;
		for( i = 0; i < machine.size; i++ )
		{
			if(IsDefined(machine[i].script_noteworthy) && machine[i].script_noteworthy == "clip")
			{
				machine_clip = machine[i];
			}
			else // then the model
			{	
				machine[i] setmodel("zombie_vending_revive_on");
				machine_model = machine[i];
			}
		}
		wait_network_frame();
		if ( isdefined( machine_model ) )
		{
			machine_model thread revive_solo_fx(machine_clip);
		}

	}else{
		while(1){
			
			if(must_be_powered)
				level waittill_any("electricity_on", specialty+"_on");
			else
				wait(5);

			for( i = 0; i < machine.size; i++ )
			{
				if(isdefined(machine[i]))
				{
					if(isdefined(machine_change)){
						machine[i] setmodel(machine_change);
						machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
					}
					machine[i] playsound("zmb_perks_power_on");
					machine[i] thread perk_fx( light_fx , specialty);
				}
			}
			level notify( specialty + "_power_on" );
			//IPrintLnBold( specialty + "_power_on" );

			if(must_be_powered)
				level waittill_any("electricity_off", specialty+"_off");
			else
				break;

			wait(5);
			for( i = 0; i < machine.size; i++ )
			{
				if(isdefined(machine[i]))
				{
					//IPrintLnBold( og_machine );
					if(isdefined(machine_change))
						machine[i] setmodel(og_machine);
					machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
					//machine[i] playsound("zmb_perks_power_on");
				}
			}
			level notify( specialty + "_power_off" );
			//IPrintLnBold( specialty + "_power_off" );
		}
	}
}

manage_self_power(specialty){
	while(1){
		//IPrintLnBold( "waiting for "+specialty + "_power_on" );
		level waittill( specialty + "_power_on" );
		//IPrintLnBold( specialty + "_power_on" );
		self.power_on = true;

		//IPrintLnBold( "waiting for "+specialty + "_power_off" );
		level waittill( specialty + "_power_off");
		//IPrintLnBold( specialty + "_power_off" );
		self.power_on = false;
	}
}
is_powered_on(){
	//IPrintLnBold( "self.power_on "+ is_true( self.power_on ) +"   level.power_on "+ level.power_on );
	return is_true( self.power_on ) || level.power_on;
}
 
revive_solo_fx(machine_clip)
{
	flag_init( "solo_revive" );
 
	self.fx = Spawn( "script_model", self.origin );
	self.fx.angles = self.angles;
	self.fx SetModel( "tag_origin" );
	self.fx LinkTo(self);
 
	playfxontag( level._effect[ "revive_light" ], self.fx, "tag_origin" );
	playfxontag( level._effect[ "revive_light_flicker" ], self.fx, "tag_origin" );
 
	flag_wait( "solo_revive" );
 
	if ( isdefined( level.revive_solo_fx_func ) )
	{
		level thread [[ level.revive_solo_fx_func ]]();
	}
	wait(2.0);
	self playsound("zmb_box_move");
	playsoundatposition ("zmb_whoosh", self.origin );
 
	self moveto(self.origin + (0,0,40),3);
	if( isDefined( level.custom_vibrate_func ) )
	{
		[[ level.custom_vibrate_func ]]( self );
	}
	else
	{
	   direction = self.origin;
	   direction = (direction[1], direction[0], 0);
 
	   if(direction[1] < 0 || (direction[0] > 0 && direction[1] > 0))
	   {
            direction = (direction[0], direction[1] * -1, 0);
       }
       else if(direction[0] < 0)
       {
            direction = (direction[0] * -1, direction[1], 0);
       }
 
        self Vibrate( direction, 10, 0.5, 5);
	}
 
	self waittill("movedone");
	PlayFX(level._effect["poltergeist"], self.origin);
	playsoundatposition ("zmb_box_poof", self.origin);
 
    level clientNotify( "drb" );
 
	//self setmodel("zombie_vending_revive");
	self.fx Unlink();
	self.fx delete();	
	self Delete();
 
	// DCS: remove the clip.
	machine_clip trigger_off();
	machine_clip ConnectPaths();	
	machine_clip Delete();
}
 
divetonuke_explode( attacker, origin )
{
	// tweakable vars
	radius = level.zombie_vars["zombie_perk_divetonuke_radius"];
	min_damage = level.zombie_vars["zombie_perk_divetonuke_min_damage"];
	max_damage = level.zombie_vars["zombie_perk_divetonuke_max_damage"];
 
	// radius damage
	RadiusDamage( origin, radius, max_damage, min_damage, attacker, "MOD_GRENADE_SPLASH" );
 
	// play fx
	PlayFx( level._effect["divetonuke_groundhit"], origin );
 
	// play sound
	attacker playsound("zmb_phdflop_explo");
 
	// WW (01/12/11): start clientsided effects - These client flags are defined in _zombiemode.gsc & _zombiemode.csc
	// Used for zombie_dive2nuke_visionset() in _zombiemode.csc
	attacker SetClientFlag( level._ZOMBIE_PLAYER_FLAG_DIVE2NUKE_VISION );
	wait_network_frame();
	wait_network_frame();
	attacker ClearClientFlag( level._ZOMBIE_PLAYER_FLAG_DIVE2NUKE_VISION );
}
//	
//
perk_fx( fx , specialty)
{


	while(1){
		self.fx = Spawn( "script_model", self.origin );
		self.fx.angles = self.angles;
		self.fx SetModel( "tag_origin" );
		self.fx LinkTo(self);
		wait(3);
		playfxontag( level._effect[ fx ], self.fx, "tag_origin" );

		level waittill( specialty + "_power_off" );
		
		if(IsDefined( self.fx ))
		{
			self.fx Unlink();
			self.fx delete();
		}

		level waittill( specialty + "_power_on" );
	}	
	//self Delete();
}
 
electric_perks_dialog()
{
	//TODO  TEMP Disable Revive in Solo games
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		return;
	}
 
	self endon ("warning_dialog");
	level endon("switch_flipped");
	timer =0;
	while(1)
	{
		wait(0.5);
		players = get_players();
		for(i = 0; i < players.size; i++)
		{		
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer = 0;
				continue;
			}
			if(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer ++;
			}
			if(dist < 70*70 && timer == 3)
			{
 
				players[i] thread do_player_vo("vox_start", 5);	
				wait(3);				
				self notify ("warning_dialog");
				/#
				iprintlnbold("warning_given");
				#/
			}
		}
	}
}
 
 
//
//
vending_trigger_think()
{
	//self thread turn_cola_off();
	perk = self.script_noteworthy;
	//solo = false;
	flag_init( "_start_zm_pistol_rank" );

	self.cost = level.zombie_vars["zombie_perk_cost"];
	self.cost = level.zombie_perks[perk].cost;
	

	is_quick_revive_on = false;

	if ( IsDefined(perk) && 
		(perk == "specialty_quickrevive" || perk == "specialty_quickrevive_upgrade"))
	{
		flag_wait( "all_players_connected" );
		players = GetPlayers();
		if ( players.size == 1 )
		{
			if(level.QUICKREVIVE_SOLO_COST_SOLO_ON){
				is_quick_revive_on = true;
				self.cost = 500;
			}
			if(level.QUICKREVIVE_ADDED_LIVES){
				//solo = true;
				flag_set( "solo_game" );
				level.solo_lives_given = 0;
				players[0].lives = 0;
				level maps\_zombiemode::zombiemode_solo_last_stand_pistol();
			}
		}
	}

	flag_set( "_start_zm_pistol_rank" );
 
	self SetCursorHint( "HINT_NOICON" );
	self UseTriggerRequireLookAt();
 
	if (level.MUST_POWER_PERKS && !is_quick_revive_on && !self is_powered_on())
	{
		self thread manage_self_power(perk);
	//	self SetHintString( &"ZOMBIE_NEED_POWER" );
	//	level waittill( perk + "_power_on" );
	}
 
	if(!IsDefined(level._perkmachinenetworkchoke))
	{
		level._perkmachinenetworkchoke = 0;
	}
	else
	{
		level._perkmachinenetworkchoke ++;
	}
 
	for(i = 0; i < level._perkmachinenetworkchoke; i ++)
	{
		wait_network_frame();
	}
 
	//Turn on music timer
	self thread maps\_zombiemode_audio::perks_a_cola_jingle_timer();
 
	perk_hum = spawn("script_origin", self.origin);
	perk_hum playloopsound("zmb_perks_machine_loop");
 
	self thread check_player_has_perk(perk);
 
	self thread vending_set_hintstring(perk);

	costs_money = true;
	if(level.ZHC_TESTING_LEVEL > 2)
		costs_money = false; //testo
 
	for( ;; )
	{

		self waittill( "trigger", player );
 		
		if(level.MUST_POWER_PERKS && !is_quick_revive_on && !self is_powered_on() ){
			if(level.ZHC_TESTING_LEVEL >= 1)
				level thread maps\ZHC_zombiemode_zhc::turn_on_nearest_perk(self.origin, 500, 12);//testo
			continue;
		}

		//IPrintLnBold( "triggerPassed powerCheck" );

		index = maps\_zombiemode_weapons::get_player_index(player);
 		
		if (player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
		{
			continue;
		}
 		
		if(player in_revive_trigger())
		{
			continue;
		}
 
		if( player isThrowingGrenade() )
		{
			wait( 0.1 );
			continue;
		}
 
 		if( player isSwitchingWeapons() )
 		{
 			wait(0.1);
 			continue;
 		}
 
		if( player is_drinking() )
		{
			wait( 0.1 );
			continue;
		}

		if ( player HasThePerk( perk ) )
		{
			//int perkLevel = player GetPerkAmount(perk);

			cheat = false;
 
			/#
			if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
			{
				cheat = true;
			}
			#/

			can_get_multiple = cheat;

 			if(!can_get_multiple 
 				&& level.PERK_LEVELS  
 				&& is_true(level.ZHC_PERK_LEVELS_BUYABLE)
 			 	&& player CanAddPerkLevel(perk))
 			{
 				can_get_multiple = true;
 			}

			if ( !can_get_multiple)
			{
				//player iprintln( "Already using Perk: " + perk );
				self playsound("deny");
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 1 );
				continue;
			}
		}

		pl = player GetPerkLevel(perk);

		if(!VendingPerkLvlBuyPass(perk, pl))
			continue;

		cost = GetPerkCost(perk, pl+1);

		if (costs_money && player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("evt_perk_deny");
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			continue;
		}
 
		if ( player.num_perks >= level.perk_limit+player.perk_slots )
		{
			//player iprintln( "Too many perks already to buy Perk: " + perk );
			self playsound("evt_perk_deny");
			// COLLIN: do we have a VO that would work for this? if not we'll leave it at just the deny sound
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "sigh" );
			continue;
		}
 		
		//self notify("update_perk_hintstrings");

		sound = "evt_bottle_dispense";
		playsoundatposition(sound, self.origin);

		if(costs_money)
			player maps\_zombiemode_score::minus_to_player_score( cost );
 
		player.perk_purchased = perk;
 
		if(isdefined(self.script_label))
			self thread maps\_zombiemode_audio::play_jingle_or_stinger (self.script_label);
		else if(isdefined(level.zombie_perks[perk].sound))
			self thread maps\_zombiemode_audio::play_jingle_or_stinger (level.zombie_perks[perk].sound);
 
		// do the drink animation
		gun = player perk_give_bottle_begin( perk );
		player waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
 
		// restore player controls and movement
		player perk_give_bottle_end( gun, perk );
 
		// TODO: race condition?
		if ( player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
		{
			continue;
		}
 
		if ( isDefined( level.perk_bought_func ) )
		{
			player [[ level.perk_bought_func ]]( perk );
		}
 
		player.perk_purchased = undefined;
 
		player give_perk( perk, true );
 		
 		
		//player iprintln( "Bought Perk: " + perk );
		bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type perk",
			player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, perk, self.origin );
	}
}

// ww: tracks the player's lives in solo, once a life is used then the revive trigger is moved back in to position
solo_revive_buy_trigger_move( revive_trigger_noteworthy )
{
	self endon( "death" );
 
	revive_perk_trigger = GetEnt( revive_trigger_noteworthy, "script_noteworthy" );
 
	revive_perk_trigger trigger_off();
 
	if( level.solo_lives_given >= 3 )
	{
		if(IsDefined(level._solo_revive_machine_expire_func))
		{
			revive_perk_trigger [[level._solo_revive_machine_expire_func]]();
		}
 
		return;
	}
 
	while( self.lives > 0 )
	{
		wait( 0.1 );
	}
 
	revive_perk_trigger trigger_on();
}
 
unlocked_perk_upgrade( perk )
{
	ch_ref = string(tablelookup( "mp/challengeTable_zmPerk.csv", 12, perk, 7 ));
	ch_max = int(tablelookup( "mp/challengeTable_zmPerk.csv", 12, perk, 4 ));
	ch_progress = self getdstat( "challengeStats", ch_ref, "challengeProgress" );
 
	if( ch_progress >= ch_max )
	{
		return true;
	}
	return false;
}
 
give_perk( perk, bought )
{

	lvl = 0;
	if(level.PERK_LEVELS)
		lvl = GetPerkLevel(perk);

	if(!level.PERK_LEVELS|| lvl == 0){
		if(IsCustomPerk(perk))
			self SetCustomPerk( perk );
		else
			self SetPerk( perk );
	}



	if(level.PERK_LEVELS)
 		self AddPerkLevel(perk);
 	else
 		self.num_perks++;

 	new_lvl = 1;
 	if(level.PERK_LEVELS)
 		new_lvl = self GetPerkLevel(perk);

	if ( is_true( bought ) )
	{
		//AUDIO: Ayers - Sending Perk Name over to audio common script to play VOX
		self thread maps\_zombiemode_audio::perk_vox( perk );
		self setblur( 4, 0.1 );
		wait(0.1);
		self setblur(0, 0.1);
		//earthquake (0.4, 0.2, self.origin, 100);
 
		self notify( "perk_bought", perk );
	}else{
		self notify( "perk_gained", perk );
	}

	if(perk == "specialty_armorvest" 
		//|| perk == "specialty_armorvest_upgrade"
		){
		if(lvl == 0)
			self.preMaxHealth = self.max_health;
		self UpdateMaxHP();
	}

	if(level.PERK_LEVELS){
		if(perk == "specialty_quickrevive"){
			if(new_lvl == 2)
				self.QUICKREVIVE_INCREASED_REGEN = true;
			else if (new_lvl == 3)
				self make_retain_perks_once(); 
		}
	}
 
	// WW (02-03-11): Deadshot csc call
	if( perk == "specialty_deadshot" )
	{
		self SetClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
	}
	else if( perk == "specialty_deadshot_upgrade" )
	{
		self SetClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
	}
 
	// quick revive in solo gives an extra life
	if(level.QUICKREVIVE_ADDED_LIVES)
	{
		players = getplayers();
		if ( players.size == 1 && perk == "specialty_quickrevive" )
		{
			if(level.PERK_LEVELS){
				self.lives++;
			}else{
				self.lives = 1;
			}
	 		
			level.solo_lives_given++;
	 		
	 		if(level.QUICKREVIVE_LIMIT_LIVES){
				if( level.solo_lives_given >= 3 )
				{
					flag_set( "solo_revive" );
				}
		 
				self thread solo_revive_buy_trigger_move( perk );
		 
				self disable_trigger();
			}
		}
	}

	if(level.PERK_LEVELS)
		self perk_hud_create( perk, lvl + 1 );
	else
 		self perk_hud_create(perk);
 	
 	if(!level.PERK_LEVELS || lvl == 0){
		//stat tracking
		self.stats["perks"]++;
		self thread perk_think( perk );
	}
}
 
check_player_has_perk(perk)
{
	self endon( "death" );
/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		return;
	}
#/
 
	dist = 128 * 128;
	while(true)
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if(DistanceSquared( players[i].origin, self.origin ) < dist)
			{
				dohide = false;
				if(level.PERK_LEVELS){
					dohide = !players[i] CanAddPerkLevel(perk) || 
					!VendingPerkLvlBuyPass(perk, players[i] GetPerkLevel(perk));
				}else{
					dohide = players[i] HasThePerk(perk);
				}
				if(	dohide ||
					players[i] in_revive_trigger() ||
					players[i] hacker_active() ||
					players[i] is_drinking()
				  )
				{
					self setinvisibletoplayer(players[i], true);
				}
				else
				{
					self SetInvisibleToPlayer(players[i], false);
				}
			}
		}
		wait(0.1);
 
	}
}

GetLowestPerkLevel(perk){
	players = get_players();
	lvl  = 1;
	//all players must have the perk in order to increase the perk level of th vending machine.
	while(1)
	{
		allHavePerk = true;
		for( i = 0; i < players.size; i++ )
		{
			if(players[i] GetPerkLevel(perk) < lvl){
				allHavePerk = false;
				break;
			}
		}
		if(allHavePerk)
			lvl++;
		else
			break;
	}
	return lvl-1;
}

GetVendingCost(perk){
	players = get_players();
	if(perk == "specialty_quickrevive" && level.QUICKREVIVE_SOLO_COST_SOLO_ON && players.size == 1 && !level.QUICKREVIVE_LIMIT_LIVES){ //becuae qr doesnt require perk lvl to get price
																																		//works the same regardless of perk level system in solo games
		cost = 500;
		if(!level.QUICKREVIVE_LIMIT_LIVES)
		{
			i = 0;
			//("solo_lives_given: "+level.solo_lives_given);
			while(i < level.solo_lives_given){
				cost *= 3;
				i++;
			}
			players[0] thread update_perk_hintstrings_thread_for_player_perk(perk, "perk_bought");

		}else if(level.solo_lives_given > 0){
			cost = 1500;
		}else{
			players[0] thread update_perk_hintstrings_thread_for_player_perk(perk, "perk_bought");
		}
		
		return cost;
	}

	if(level.PERK_LEVELS && is_true(level.ZHC_PERK_LEVELS_BUYABLE)){
		lvl = 1;

		/*if(perk == "specialty_quickrevive" && level.QUICKREVIVE_SOLO_COST_SOLO_ON && players.size == 1 && !level.QUICKREVIVE_LIMIT_LIVES){ //becuae qr doesnt require perk lvl to get price
			level.zombie_perks[perk].perk_level = 1;
			return  GetPerkCost(perk);
		}*/

		if(players.size >= 1){//temp testo
			if(is_true(level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER) && is_true(level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER_SYSTEMATIZED)){
				//perk level available to buy is limited to lowest lvl 
				lvl = GetLowestPerkLevel(perk) + 1;
				level.zombie_perks[perk].perk_level = lvl;
				//update_perk_hintstrings_thread_for_all_players(players, perk);
			}else{
				closest_distance = Distance2DSquared(self.origin, players[0].origin);
				closest = players[0];
				dif = 10000000000;
				for( i = 1; i < players.size; i++ )
				{
					dist = DistanceSquared(self.origin, players[i].origin);
					if(dist < closest_distance){
						closest = players[i];
						dif = closest_distance - dist;
						closest_distance = dist;
					}
				}
				//closest = GetClosest( level.zombie_perks[perk].origin, players);
				lvl = closest GetPerkLevel(perk) + 1;
				if(level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER)
					level.zombie_perks[perk].perk_level = lvl;
				waitTime = min(max(0.3, sqrt(dif)/250),7.1 + RandomInt( 3 ));
				thread update_perk_hintstring_wait(waitTime, perk);
			}
		}else{
			lvl = players[0] GetPerkLevel(perk) + 1;
			//update_perk_hintstrings_thread_for_all_players(players, perk);
		}
		update_perk_hintstrings_thread_for_all_players(players, perk);
		return GetPerkCost(perk, lvl);
	}else{
		return level.zombie_perks[perk].cost;
	}
}

update_perk_hintstrings_thread_for_all_players(players, perk){
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread update_perk_hintstrings_thread_for_player_perk(perk, "perk_gained");
		players[i] thread update_perk_hintstrings_thread_for_player_perk(perk, "perk_lost");
		players[i] thread update_perk_hintstrings_thread_for_player_perk(perk, "perk_bought");
	}
}
update_perk_hintstrings_thread_for_player_perk(perk, msg){
	level.zombie_perks[perk] endon( "update_perk_hintstrings" );
	level endon( perk + "_power_off" );
	for(;;){
		self waittill( msg, p);
		if(p == perk)
			break;
	}
	level.zombie_perks[perk] notify( "update_perk_hintstrings" );
}

update_perk_hintstring_wait(time, perk){
	level.zombie_perks[perk] endon ( "update_perk_hintstrings" );
	wait(time);
	level.zombie_perks[perk] notify( "update_perk_hintstrings" );
}



VendingPerkLvlBuyPass(perk, cur_level){
	players = get_players();
	
	if(perk == "specialty_quickrevive" && players.size == 1 && level.QUICKREVIVE_SOLO_COST_SOLO_ON)
		return true;

	if(is_true(level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER) && level.zombie_perks[perk].perk_level == -1)	//undefined means perk is off,
		return true;

	if(level.PERK_LEVELS && is_true(level.ZHC_PERK_LEVELS_BUYABLE) && is_true(level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER) && players.size >= 1){//temp testo
		if(cur_level == level.zombie_perks[perk].perk_level - 1)
			return true;
		else{
			IPrintLn( "wrong vending perk level " );
			return false;
		}
	}
	else
		return true;
}

vending_set_hintstring( perk )
{
	self UseTriggerRequireLookAt();
	players = get_players();
	//if(perk == "specialty_quickrevive" && players.size == 1 && level.QUICKREVIVE_SOLO_COST_SOLO_ON)
	//	thread solo_quick_revive_set_hintstring();
	//else{
		while(1)
		{
			if(!level.MUST_POWER_PERKS || self is_powered_on() || (perk == "specialty_quickrevive" && players.size == 1 && level.QUICKREVIVE_SOLO_COST_SOLO_ON)){
				if(isdefined(level.zombie_perks[perk].perk_name_actual))
					self SetHintString( level.zombie_perks[perk].perk_name_actual, self GetVendingCost(perk) );
				else
					self SetHintString( "Press & hold &&1 to buy "+level.zombie_perks[perk].perk_name+" [Cost: "+self GetVendingCost(perk)+"]" );

				if(level.PERK_LEVELS && is_true(level.ZHC_PERK_LEVELS_BUYABLE))
					waittill_any_ents( level, perk+"_power_off", level.zombie_perks[perk], "update_perk_hintstrings" );
				else
					level waittill (perk+"_power_off");
				wait_network_frame( );
			}else{
				level.zombie_perks[perk].perk_level = -1;
				self SetHintString( &"ZOMBIE_NEED_POWER" );
				
				level waittill(perk+"_power_on");
				wait_network_frame(); //wait for self power turn true
				//IPrintLnBold( "hinstring ON"+ perk+"_power_on");
			}
		}
	//}

}
 
solo_quick_revive_set_hintstring(){     //unused
	level endon( "specialty_quickrevive_power_off" );

	while(1 ){
		cost = 500;

		if(!level.QUICKREVIVE_LIMIT_LIVES)
		{
			i = 0;
			//("solo_lives_given: "+level.solo_lives_given);
			while(i < level.solo_lives_given){
				cost *= 3;
				i++;
			} 		
			//cost: 500, 1500, 4500, 13500...


			/*cost1 = 500;
			cost2 = 1500;
			i = 0;
			IPrintLnBold( (level.solo_lives_given) );
			while(i < level.solo_lives_given){
				if(i % 2 == 1){
					cost = cost2;
					cost2 *= 10;
				}else{
					cost1 *= 10;
					cost = cost1;
				}
				i++;
			}*/
			//cost: 500, 1500, 5000, 15000...
		}

		if(level.solo_lives_given > 0){
			cost = 1500;
		}

		level.zombie_perks["specialty_quickrevive"].cost = cost;
		self SetHintString(&"ZOMBIE_PERK_QUICKREVIVE_SOLO", cost );
		get_players()[0] waittill ( "perk_bought" );
		wait_network_frame( );
	}
}


perk_think( perk, recall_checked)
{

/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		if ( IsDefined( self.perk_hud[ perk ] ) )
		{
			return;
		}
	}
#/

	perk_str = perk + "_stop";
	result = "death";
	if(self maps\_laststand::player_is_in_laststand() && !is_true(recall_checked)){
		result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
		if(result == "player_downed")//player is already down
		{
			self thread perk_think(perk, true);
			return;
		}
	}else{
		result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
	}



	lvl = 1;
	if(level.PERK_LEVELS)
		lvl = GetPerkLevel(perk);
 
	do_retain = true;
 
	if( flag( "solo_game" ) && perk == "specialty_quickrevive")
	{
		do_retain = false;
	}
	//else{
		//wait_network_frame();
		//wait for quick revive to be removed first.
	//}
 	s = "RETAINED "+result+ ":  "+perk+":  ((retain = "+ is_true(self._retain_perks_once)+"))   lvl:"+lvl;

	if(result != perk_str && do_retain && (is_true(self._retain_perks) || is_true(self._retain_perks_once)) )
	{
		//IPrintLn( s );
		self thread perk_think(perk);
		return;
	}

	new_lvl = 0;
 	if(level.PERK_LEVELS){
		if(do_retain == false &&  result != perk_str)
			self RemovePerkLevel(perk);
		else
			self RemoveALLPerkLevel(perk);
		new_lvl = GetPerkLevel(perk);
	}

	remove_perk = (!level.PERK_LEVELS || new_lvl == 0);
 

	if(remove_perk){
		if(!level.PERK_LEVELS)
			self.num_perks--;
		if(IsCustomPerk(perk))
			self UnsetCustomPerk( perk );
		else
			self UnsetPerk( perk );
	}

 	
 	//end_retain_perks_once = false; 
	switch(perk)
	{
		case "specialty_armorvest":
		//case "specialty_armorvest_upgrade":
			self UpdateMaxHP();
			break;
 		case "specialty_quickrevive":
 			if(level.PERK_LEVELS){
 				if (result == perk_str && level.QUICKREVIVE_ADDED_LIVES && flag( "solo_game" ) && perk == "specialty_quickrevive" )
				{
					self.lives--;
					level.solo_lives_given--;		//changed for mod
					level.zombie_perks[perk] notify ("update_perk_hintstrings");
				}
				if(new_lvl < 2)
					self.QUICKREVIVE_INCREASED_REGEN = false;
				if (new_lvl < 3){
					self._retain_perks_once = false;
					self notify("end_retain_perks_once");
				}
			}else{
				if (remove_perk && result == perk_str && level.QUICKREVIVE_ADDED_LIVES && flag( "solo_game" ) && perk == "specialty_quickrevive" )
				{
					self.lives--;
					level.solo_lives_given--;		//changed for mod
				}
			}
			break;
		case "specialty_additionalprimaryweapon":
			if ( result == perk_str )
			{
				self maps\_zombiemode::take_additionalprimaryweapon(new_lvl);
			}
			break;
 
		case "specialty_deadshot":
			if(remove_perk)
				self ClearClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
			break;
 
		case "specialty_deadshot_upgrade":		
			if(remove_perk)
				self ClearClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
			break;
	}

	s = ""+result+ ":  "+perk+":  ((retain = "+ is_true(self._retain_perks_once)+"))   lvl:"+lvl+"-"+new_lvl;
	if(remove_perk)	
		s = ("REMOVED" + s );
	else
		s = ("REDUCED" + s);

	//if(perk != "specialty_quickrevive")
		//IPrintLn( s );

 	if(level.PERK_LEVELS){
 		//( "nl = "+new_lvl+" oldlvl "+ lvl );
 		for(i = new_lvl + 1; i <= lvl; i++)
			self perk_hud_destroy( perk , i);
		self update_perk_hud(); //takes aways empty s[paces.]
 	}
	else
		self perk_hud_destroy( perk);

	self.perk_purchased = undefined;
	//self iprintln( "Perk Lost: " + perk );
 	self notify( "perk_lost" , perk );

 	if(remove_perk){
		if ( IsDefined( level.perk_lost_func ) )
		{
			self [[ level.perk_lost_func ]]( perk );
		}
	}else{
		self thread perk_think(perk);
	}

}


watch_for_respawn()
{
	self endon("disconnect");
	self endon("end_retain_perks_once");
	
	while(self._retain_perks_once)
	{
		self waittill( "player_revived" ); 
		waittillframeend;	// Let the other spawn threads do their thing.

		self UpdateMaxHP();


		wait_network_frame();
		self._retain_perks_once = self GetPerkLevel("specialty_quickrevive") >= 3;
	}
}

UpdateMaxHP(){
	max_hp = 100;
	s = max_hp;

	//IPrintLn(  "  " +level.zombie_vars["zombie_perk_juggernaut_health"] +"    "+level.zombie_vars["zombie_perk_juggernaut_health_upgrade"]);
	if(self HasThePerk("specialty_armorvest")){
		max_hp = get_jug_health();
		s += "->"+max_hp;
	}
	/*if(self HasThePerk("specialty_armorvest_upgrade")){
		max_hp = get_jug_health(true);
		s += "->"+max_hp;
	}*/
	if(level.PERK_LEVELS){
		pl = self GetPerkLevel("specialty_armorvest");
		if(pl != 0){
			hpIntreval = (get_jug_health(true) - get_jug_health() ); 
			//hpIntreval = 25;
			s += "->"+max_hp;
			if(pl > 1){
				mult = (pl-1);
				s += max_hp+"+("+mult+"*"+hpIntreval+") ->";
				max_hp = max_hp+(mult*hpIntreval);
				s += max_hp;
			}
		}
	}

	self SetMaxHealth(max_hp);
	//IPrintLnBold( s );

	if ( self.health > self.maxhealth )
	{
		self.health = self.maxhealth;
	}
}

make_retain_perks_once()
{
	self._retain_perks_once = true;
	self notify("end_retain_perks_once");	//ends current thread.
	self thread watch_for_respawn();
}
 
perk_hud_create( perk, perk_level )
{
	//bold(perk+perk_level);
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];

		//self.perk_hud_order = [];
	}
	just_perk = perk;
	if(isdefined(perk_level)){
		perk = perk+perk_level;
	}
/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		if ( IsDefined( self.perk_hud[ perk ] ) )
		{
			return;
		}
	}
#/


 
	shader = level.zombie_perks[just_perk].shader;
 
	hud = create_simple_hud( self );
	hud.foreground = true;
	hud.sort = 1; 
	hud.hidewheninmenu = false; 
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	hud.x = self.perk_hud.size * 30; 
	hud.y = hud.y - 70; 
	hud.alpha = 1;
	hud SetShader( shader, 24, 24 );
 
	self.perk_hud[ perk ] = hud;
}



Damage_Perk(perk, amount){
	hud = self.perk_hud[perk];
	if(!isDefined(hud.hp)){
			hud.hp = 100;
	}
	hud.hp = max(hud-amount,0);
	hud.alpha = min((hud.hp + 30) / 130, 1);
	if(hud.hp <= 0){
		self notify(perk+"_stop");
	}
}

DamagePerks(amount){
	if(!IsDefined( self.perk_hud ))
		return;
	playerperks = [];
	allperks = self get_all_perks();
	for(i = 0; i < allperks.size; i++){
		if(isDefined(self.perk_hud[allperks[i]])){
			playerperks[playerperks.size] = allperks[i];
		}
	}

	for(i = 0; i < playerperks.size; i++){
		if(playerperks[i] == "specialty_armorvest"){
			Damage_Perk(playerperks[i],10);
			return;
		}
	}

	for(i = 0; i < playerperks.size; i++){
		Damage_Perk(playerperks[i],10);
	}
	return;

}

perk_hud_destroy( perk, perk_level)
{
	//("destroy "+perk+perk_level);
	if(isDefined(perk_level)){
		self.perk_hud[ perk+perk_level ] destroy_hud();
		self.perk_hud[ perk+perk_level ] = undefined;
		return;
	}

	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}
 
perk_hud_flash()
{
	self endon( "death" );
 
	self.flash = 1;
	self ScaleOverTime( 0.05, 32, 32 );
	wait( 0.3 );
	self ScaleOverTime( 0.05, 24, 24 );
	wait( 0.3 );
	self.flash = 0;
}
 
perk_flash_audio( perk )
{
    alias = undefined;
 
    switch( perk )
    {
        case "specialty_armorvest":
            alias = "zmb_hud_flash_jugga";
            break;
 
        case "specialty_quickrevive":
            alias = "zmb_hud_flash_revive";
            break;
 
        case "specialty_fastreload":
            alias = "zmb_hud_flash_speed";
            break;
 
        case "specialty_longersprint":
            alias = "zmb_hud_flash_stamina";
            break;
 
        case "specialty_flakjacket":
            alias = "zmb_hud_flash_phd";
            break;
 
        case "specialty_deadshot":
            alias = "zmb_hud_flash_deadshot";
            break;
 
        case "specialty_additionalprimaryweapon":
            alias = "zmb_hud_flash_additionalprimaryweapon";
            break;
    }
 
    if( IsDefined( alias ) )
        self PlayLocalSound( alias );
}
 
perk_hud_start_flash( perk )
{
	if ( self HasThePerk( perk ) && isdefined( self.perk_hud ) )
	{
		hud = self.perk_hud[perk];
		if ( isdefined( hud ) )
		{
			if ( !is_true( hud.flash ) )
			{
				hud thread perk_hud_flash();
				self thread perk_flash_audio( perk );
			}
		}
	}
}
 
perk_hud_stop_flash( perk, taken )
{
	if ( self HasThePerk( perk ) && isdefined( self.perk_hud ) )
	{
		hud = self.perk_hud[perk];
		if ( isdefined( hud ) )
		{
			hud.flash = undefined;
			if ( isdefined( taken ) )
			{
				hud notify( "stop_flash_perk" );
			}
		}
	}
}
 
perk_give_bottle_begin( perk )
{
	self increment_is_drinking();
 
	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowCrouch( true );
	self AllowProne( false );
	self AllowMelee( false );
 
	wait( 0.05 );
 
	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}
 
	gun = self GetCurrentWeapon();
	weapon = "";
 
	weapon = level.zombie_perks[perk].bottle_weapon;
 
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
 
	return gun;
}
 
 
perk_give_bottle_end( gun, perk )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "zombie_perk_bottle_marathon" );
	assert( gun != "zombie_perk_bottle_nuke" );
	assert( gun != "zombie_perk_bottle_deadshot" );
	assert( gun != "zombie_perk_bottle_additionalprimaryweapon" );
	assert( gun != "syrette_sp" );
 
	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );		
	self AllowMelee( true );
	weapon = "";
	weapon = level.zombie_perks[perk].bottle_weapon;
 
 
	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}
 
	self TakeWeapon(weapon);
 
	if( self is_multiple_drinking() )
	{
		self decrement_is_drinking();
		return;
	}
	else if( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self SwitchToWeapon( gun );
		// ww: the knives have no first raise anim so they will never get a "weapon_change_complete" notify
		// meaning it will never leave this funciton and will break buying weapons for the player
		if( is_melee_weapon( gun ) )
		{
			self decrement_is_drinking();
			return;
		}
	}
	else 
	{
		// try to switch to first primary weapon
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
	}
 
	self waittill( "weapon_change_complete" );
 
	if ( !self maps\_laststand::player_is_in_laststand() && !is_true( self.intermission ) )
	{
		self decrement_is_drinking();
	}
}
 
give_random_perk()
{
	perks = get_all_perks();
 
 	for ( i = 0; i < perks.size; i++ )
	{
		perk = perks[i];
		if ( isdefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			continue;
		}

		if ( !self HasThePerk( perk ) )
		{
			perks[ perks.size ] = perk;
		}
	}
	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		self give_perk( perks[0] );
	}
}

get_all_perks(){
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	perks = [];
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;
  		perks[ perks.size ] = perk;
 	}
		
	return perks;
}
 
 
lose_random_perk()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
 
	perks = [];
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;
 
		if ( isdefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			continue;
		}
 
		if ( self HasThePerk( perk ) )
		{
			perks[ perks.size ] = perk;
		}
	}
 
	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		perk = perks[0];
 
		perk_str = perk + "_stop";
		self notify( perk_str );
	}
}
 
update_perk_hud()
{
	if ( isdefined( self.perk_hud ) )
	{
		keys = getarraykeys( self.perk_hud );
		for ( i = self.perk_hud.size-1; i >= 0; i-- )
		{
			self.perk_hud[ keys[i] ].x = i * 30;
		}
	}
}
 
quantum_bomb_give_nearest_perk_validation( position )
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
 
	range_squared = 180 * 180; // 15 feet
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		if ( DistanceSquared( vending_triggers[i].origin, position ) < range_squared )
		{
			return true;
		}
	}
 
	return false;
}
 
 
quantum_bomb_give_nearest_perk_result( position )
{
	[[level.quantum_bomb_play_mystery_effect_func]]( position );
 
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
 
	nearest = 0;
	for ( i = 1; i < vending_triggers.size; i++ )
	{
		if ( DistanceSquared( vending_triggers[i].origin, position ) < DistanceSquared( vending_triggers[nearest].origin, position ) )
		{
			nearest = i;
		}
	}
 
	players = getplayers();
	perk = vending_triggers[nearest].script_noteworthy;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
 
		if ( player.sessionstate == "spectator" || player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}
 
		if ( !player HasThePerk( perk ) && ( !isdefined( player.perk_purchased ) || player.perk_purchased != perk) && RandomInt( 5 ) ) // 80% chance
		{
			if( player == self )
			{
				self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			}
 
			player give_perk( perk );
			player [[level.quantum_bomb_play_player_effect_func]]();
		}
	}
}
perk_slot_setup()
{
	flag_wait( "all_players_connected" );
	players = get_players();
	for ( i = 0; i < players.size; i++ )
		players[i].perk_slots = 0;
}
give_perk_slot()
{
	if(!isdefined(self.perk_slots))
		self.perk_slots = 0;
	self.perk_slots +=1;
}
 




//perk_modify_actor_killed_override(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime){
	//attacker chamberfill_func(attacker, sMeansOfDeath,sWeapon,true);
	//eInflictor bucha_func(attacker,sMeansOfDeath,iDamage,attacker,sHitLoc,true);
//}
//perk_modify_actor_damage_override( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, sHitLoc, modelIndex, psOffsetTime ){
	//attacker chamberfill_func(attacker,meansofdeath,weapon,false);
	//inflictor bucha_func(attacker, meansofdeath,damage, weapon,sHitLoc);
//}
//zombie_damage_not_killed_func( mod, hit_location, hit_origin, player, amount ){
	//player chamberfill_func(player, mod,undefined,false);
	//self bucha_func(player,mod,amount,player GetCurrentWeapon(),hit_location,false);
	//IPrintLnBold( 1111 );	
//	self double_tap_2_func(mod, hit_location, hit_origin, player, amount);
//	return false;
//}
/*player_damaged_func( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	eInflictor damagePerks(iDamage);
	return iDamage;
}*/

double_tap_2_func( mod, hit_location, player, amount )
{
	p = "specialty_rof";
	pl = player GetPerkLevel(p);

	if(pl > 1){
		if( mod == "MOD_RIFLE_BULLET" || mod == "MOD_PISTOL_BULLET"  )
		{
			amount_of_damage_points = 0;
			additional_damage = 0;
			kill = false;
			for( i = 2; i <= pl; i ++){
				additional_damage = amount*(i-1);
				if(additional_damage < self.health){
					amount_of_damage_points = i - 1;
				}else{
					kill = true;
					break;
				}
			}
			for(j = 0; j < amount_of_damage_points; j++){
				player maps\_zombiemode_score::player_add_points( "damage", mod, hit_location, self.isdog );
			}
			return additional_damage;

			if(kill)
				player maps\_zombiemode_score::player_add_points( "death", mod, hit_location, self.isdog );
			self DoDamage( additional_damage, player.origin );
		}
	}
	return 0;
	return false;	
}
phd_flopper_2_func(mod, hit_location, player, amount){
	p = "specialty_flakjacket";
	pl = player GetPerkLevel(p);

	if(pl > 1){
		if( mod == "MOD_PROJECTILE" || mod == "MOD_PROJECTILE_SPLASH" || mod == "MOD_GRENADE" || mod == "MOD_GRENADE_SPLASH"  )
		{
			amount_of_damage_points = 0;
			additional_damage = 0;
			kill = false;
			for( i = 2; i <= pl; i ++){
				additional_damage = (amount*((pl-1)*2))-amount;
				if(additional_damage < self.health){
					amount_of_damage_points = i - 1;
				}else{
					kill = true;
					break;
				}
			}
			for(j = 0; j < amount_of_damage_points; j++){
				player maps\_zombiemode_score::player_add_points( "damage", mod, hit_location, self.isdog );
			}
			return additional_damage;

			if(kill)
				player maps\_zombiemode_score::player_add_points( "death", mod, hit_location, self.isdog );
			self DoDamage( additional_damage, player.origin );
		}
	}
	return 0;
	return false;	
}

chamberfill_wait_thread(player){
	player.can_chamberfill = false;
	wait_network_frame();
	player.can_chamberfill = true;
}

//chamberfill_func(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, damageFromUnderneath, modelIndex, partName )
chamberfill_func(player,mod,weap,isKill)
{
	if(!IsPlayer(player))
		return false;
	canrefillgernade = false;
	magicammo = false;
	if (self HasThePerk("specialty_killbulletload")){
		if(!IsDefined( player.can_chamberfill ) || player.can_chamberfill){
			thread chamberfill_wait_thread(player);

			
			if( mod == "MOD_RIFLE_BULLET" || mod == "MOD_PISTOL_BULLET" ){
				if(!IsDefined( weap ) || weap == player GetCurrentWeapon()){
					weap = self GetCurrentWeapon();
					clipammo = self GetWeaponAmmoClip( weap );
					stockammo = self GetWeaponAmmoStock( weap );
					clipsize = WeaponClipSize( weap );

					 //allow clip to load even without stock ammo // does not take stock ammo

					reloadAmount = 0;
					

					/*if(isKill){
						weapThresholdAmount = Int((clipSize/3)-3);
						if(weapThresholdAmount < 1)
							weapThresholdAmount = 1;
						if(clipammo <= weapThresholdAmount){
							reloadAmount = weapThresholdAmount - clipammo;
						}
					}*/
					
					if (
						//reloadAmount == 0 && (isKill || clipammo == 1) && 
						clipammo + 1 <= clipsize){
						reloadAmount = 1;
					}
					println("reloadamount: "+reloadAmount);


					if(IsDefined(reloadAmount)){
						if(reloadAmount > stockAmmo && !magicammo)
							reloadAmount = stockAmmo;
						player SetWeaponAmmoClip( weap, clipammo + reloadAmount);
						if(!magicammo)
							player SetWeaponAmmoStock( weap, stockammo - reloadAmount);
					}
					
				}
			}
			else if((mod == "MOD_GRENADE_SPLASH" || mod == "MOD_GRENADE") && canrefillgernade){
				if(!IsDefined( weap )){}
				weapons_on_player = self GetWeaponsList();
				for ( i = 0; i < weapons_on_player.size; i++ ){
					if ( self maps\_zombiemode_utility::is_player_lethal_grenade( weapons_on_player[i] ) ){
						weap = weapons_on_player[i];
						break;
					}
				}
				clipammo = self GetWeaponAmmoClip( weap );
				if(clipammo + 1 <= WeaponClipSize( weap )) {
					self SetWeaponAmmoClip( weap, clipammo + 1);
				}
			}
		}
	}
	return false;
}

//bucha_func( mod, hit_location, hit_origin, player, amount )
bucha_func(player, mod, amount ,weap,hit_location,isKill)
{
	if((player HasThePerk("specialty_knifeescape")) && ( mod == "MOD_MELEE" || mod == "MOD_BAYONET")) {

		maxHp = self.maxhealth;
		hp = self.health;
		additionalamount = 0;
		fatalthreshhold = 0;
		if(!isKill){
			additionalamount = int(amount/((amount/1000) + 1));
			fatalthreshhold = int(maxHp - (maxHp/((4/3) + (((amount-150)/1000)*(1/3))))); //get fatal damage amount
			if(hp <= fatalthreshhold) //if fatal damage could kill zombie (before this attack) make this attack fatal
				additionalamount = fatalthreshhold;
		}

		if( self maps\_zombiemode_spawner::zombie_should_gib( amount, player, "MOD_GRENADE_SPLASH" ) )
		{
			refs = [];
			
			m = 1;
			isBay = false;
			if(mod == "MOD_BAYONET"){
				isBay = true;
				m = 2;
			}
			cm = amount/maxHp;
			if(cm > 1.666)
				cm = 1.666;
			if(cm < 0.333)
				cm = 0.333;
			m *= cm;

			k = false;
			if(isKill || additionalamount >= hp ){
				k = true;
				m+=1.5;
			}
			//if((mod == "MOD_BAYONET" || (self.gibbed && (isKill || hp < maxHp - (amount*4) || hp <= fatalthreshhold*2) && randomint(2) == 0 )) && (isKill || hp <= fatalthreshhold*2) && self.has_legs) {
			if(self.has_legs){
				cm = m;
				if(isBay)
					cm *= 2;
				else{
					kcm = (maxHp*0.5)/ max(1,hp + amount);
					if(kcm > 3)
						kcm = 3;
					cm *= kcm;
				}
				if(randomint(100) < 10 * cm)
					refs[refs.size] = "right_leg"; 
				if(randomint(100) < 10 * cm)
					refs[refs.size] = "left_leg"; 
				if(randomint(100) < 10 * cm)
					refs[refs.size] = "no_legs"; 
			//}else if(!self.has_legs){
			}else{
				if(randomint(100) < 40 * m)
					refs[refs.size] = "right_leg"; 
				if(randomint(100) < 40 * m)
					refs[refs.size] = "left_leg"; 
				//refs[refs.size] = "guts";
				//refs[refs.size] = "right_arm"; 
				//refs[refs.size] = "left_arm"; 
			}
			if(randomint(100) < 30 * m)
				refs[refs.size] = "guts";
			if(randomint(100) < 30 * m)
				refs[refs.size] = "right_arm"; 
			if(randomint(100) < 30 * m)
				refs[refs.size] = "left_arm"; 

			hm = m;
			if(k)
				hm *= 4;

			if(randomint(100) < 10 * hm)
				refs[refs.size] = "head";

			bucha_gib_refs(refs,player, !(additionalamount >= hp));
			
		}

				//deal additinal damage which might kill
		if(additionalamount > 0){
			if(!isKill){
				if(additionalamount >= hp){
					player maps\_zombiemode_score::player_add_points( "death", mod, hit_location, self.isdog );
					isKill = true;//isKill now applies to kills done from  additinal damage
				}
				//self maps\_zombiemode_spawner::zombie_disintegrate(player);
				
				self DoDamage( Int(additionalamount), player.origin );
			}
		}

		//IPrintLnBold( (additionalamount + amount) + " knife damage vs " +(hp + amount) + "zombie health");

		


		//gives additinal points based on health of zombie
		if(isKill){
			timesToGivePoints = int(hp/amount)+1;
			if(timesToGivePoints>13)
				timesToGivePoints = 13;
			for( i=0; i<timesToGivePoints; i++ )
				player maps\_zombiemode_score::player_add_points( "damage", mod, hit_location, self.isdog );
		}
		return true;
	}
	return false;
}
bucha_gib_refs(refs, player, changeAnims){
	if( refs.size )
	{
		//for( i=0; i<refs.size; i++ ){
			self.a.gib_ref = animscripts\zombie_death::get_random( refs );
			//self.a.gib_ref = refs[i];

			if(changeAnims){
				// Don't stand if a leg is gone
				if(self.a.gib_ref == "no_legs" || self.a.gib_ref == "right_leg" || self.a.gib_ref == "left_leg" )
				{
					self.has_legs = false; 
					self AllowedStances( "crouch" ); 
										
					// reduce collbox so player can jump over
					self setPhysParams( 15, 0, 24 );
					
					which_anim = RandomInt( 5 ); 
					if(self.a.gib_ref == "no_legs")
					{
						if(randomint(100) < 50)
						{
							self.deathanim = %ai_zombie_crawl_death_v1;
							self set_run_anim( "death3" );
							self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
							self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_1"];
							self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
						}
						else
						{
							self.deathanim = %ai_zombie_crawl_death_v1;
							self set_run_anim( "death3" );
							self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
							self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_2"];
							self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
						}
					}
					else if( which_anim == 0 ) 
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl1"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl1"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl1"];
					}
					else if( which_anim == 1 ) 
					{
						self.deathanim = %ai_zombie_crawl_death_v2;
						self set_run_anim( "death4" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl2"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl2"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl2"];
					}
					else if( which_anim == 2 ) 
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl3"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl3"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl3"];
					}
					else if( which_anim == 3 ) 
					{
						self.deathanim = %ai_zombie_crawl_death_v2;
						self set_run_anim( "death4" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl4"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl4"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl4"];
					}
					else if( which_anim == 4 ) 
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl5"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl5"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl5"];
					}
						
					if ( isdefined( self.crawl_anim_override ) )
					{
						self [[ self.crawl_anim_override ]]();
					}
				}
			}
			// force gibbing if the zombie is still alive
			self thread animscripts\zombie_death::do_gib();
			//stat tracking
			if ( IsPlayer( self ) )
				player.stats["zombie_gibs"]++;
		//}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////candolier/////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//note: stock ammo of all weapons should be 2 clip sizes higher than normal ammo
candolier()
{
	flag_wait( "all_players_connected" );
	players = get_players();
	for ( i = 0; i < players.size; i++ )
		players[i] thread candolier_ammo();
}
candolier_ammo()
{
	while(1)
	{	
		player_weapons = self GetWeaponsListPrimaries();
		for( i=0; i<player_weapons.size; i++ )
		{
			clip = weaponClipSize(player_weapons[i])*2;
			candolier_ammo = WeaponMaxAmmo(player_weapons[i]);
			if (!( self HasThePerk( "specialty_bulletaccuracy" )))
				candolier_ammo -= clip;	
			if(self GetWeaponAmmoStock(player_weapons[i]) <= candolier_ammo)
				continue;
			if(self GetAmmoCount(player_weapons[i]) > candolier_ammo)
				self SetWeaponAmmoStock(player_weapons[i], candolier_ammo);
		}
		wait .05;
	}
}