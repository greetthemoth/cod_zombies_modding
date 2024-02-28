#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_audio;
#include maps\ZHC_utility;

init()
{
	maps\ZHC_zombiemode_weapons::init();
	init_weapons();
	init_weapon_upgrade();
	init_weapon_toggle();
	init_pay_turret();
//	init_weapon_cabinet();
	treasure_chest_init();
	level thread add_limited_tesla_gun();

	PreCacheShader( "minimap_icon_mystery_box" );
	PrecacheShader( "specialty_instakill_zombies" );
	PrecacheShader( "specialty_firesale_zombies" );
	
	level._zombiemode_check_firesale_loc_valid_func = ::default_check_firesale_loc_valid_func;
}

default_check_firesale_loc_valid_func()
{
	if(level.ZHC_ALL_CHESTS && level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM && level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL && level.chests[level.chest_index] == self
		&& (isDefined(self.times_chest_opened) && self.times_chest_opened >= 1)	//this makes it so the player can get the fake teddy once from the firesale. After that firesale wont work on the chest. ever. 
		)
		return false;
	return true;
}

add_zombie_weapon( weapon_name, upgrade_name, hint, cost, weaponVO, weaponVOresp, ammo_cost )
{
	if( IsDefined( level.zombie_include_weapons ) && !IsDefined( level.zombie_include_weapons[weapon_name] ) )
	{
		return;
	}
	
	// Check the table first
	/*
	table = "mp/zombiemode.csv";
	table_cost = TableLookUp( table, 0, weapon_name, 1 );
	table_ammo_cost = TableLookUp( table, 0, weapon_name, 2 );

	
	if( IsDefined( table_cost ) && table_cost != "" )
	{
		cost = round_up_to_ten( int( table_cost ) );
	}

	if( IsDefined( table_ammo_cost ) && table_ammo_cost != "" )
	{
		ammo_cost = round_up_to_ten( int( table_ammo_cost ) );
	}
	*/

	PrecacheString( hint );

	struct = SpawnStruct();

	if( !IsDefined( level.zombie_weapons ) )
	{
		level.zombie_weapons = [];
	}

	struct.weapon_name = weapon_name;
	struct.upgrade_name = upgrade_name;
	struct.weapon_classname = "weapon_" + weapon_name;
	struct.hint = hint;
	struct.cost = cost;
	struct.vox = weaponVO;
	struct.vox_response = weaponVOresp;
	struct.is_in_box = level.zombie_include_weapons[weapon_name];


	if( !IsDefined( ammo_cost ) )
	{
		//ammo_cost = round_up_to_ten( int( cost * 0.5 ) );  changed for mod
		ammo_cost = round_up_to_ten( int(  
			(min(cost,1500)/2) + 				//Max = 750 ammo cost (1500 cost)
			(min(max(cost-1500,0),3000)/5) +	//Max = 1350 ammo cost (4500 cost)
			(min(max(cost-4500,0),6000)/15) 	//Max = 1750 ammo cost (10500 cost)
		));
		//ammo_cost = maps\ZHC_zombiemode_zhc::normalize_cost(ammo_cost);
	}



	struct.ammo_cost = ammo_cost;

	level.zombie_weapons[weapon_name] = struct;
}

default_weighting_func()
{
	return 1;
}

default_tesla_weighting_func()
{
	num_to_add = 1;
	if( isDefined( level.pulls_since_last_tesla_gun ) )
	{
		// player has dropped the tesla for another weapon, so we set all future polls to 20%
		if( isDefined(level.player_drops_tesla_gun) && level.player_drops_tesla_gun == true )
		{						
			num_to_add += int(.2 * level.zombie_include_weapons.size);		
		}
		
		// player has not seen tesla gun in late rounds
		if( !isDefined(level.player_seen_tesla_gun) || level.player_seen_tesla_gun == false )
		{
			// after round 10 the Tesla gun percentage increases to 20%
			if( level.round_number > 10 )
			{
				num_to_add += int(.2 * level.zombie_include_weapons.size);
			}		
			// after round 5 the Tesla gun percentage increases to 15%
			else if( level.round_number > 5 )
			{
				// calculate the number of times we have to add it to the array to get the desired percent
				num_to_add += int(.15 * level.zombie_include_weapons.size);
			}						
		}
	}
	return num_to_add;
}


//
//	For weapons which should only appear once the box moves
default_1st_move_weighting_func()
{
	if( level.chest_moves > 0 )
	{	
		num_to_add = 1;

		return num_to_add;	
	}
	else
	{
		return 0;
	}
}


//
//	Default weighting for a high-level weapon that is too good for the normal box
default_upgrade_weapon_weighting_func()
{
	if ( level.chest_moves > 1 )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}


//
//	Slightly elevate the chance to get it until someone has it, then make it even
default_cymbal_monkey_weighting_func()
{
	players = get_players();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] has_weapon_or_upgrade( "zombie_cymbal_monkey" ) )
		{
			count++;
		}
	}
	if ( count > 0 )
	{
		return 1;
	}
	else
	{
		if( level.round_number < 10 )
		{
			return 3;
		}
		else
		{
			return 5;
		}
	}
}


is_weapon_included( weapon_name )
{
	if( !IsDefined( level.zombie_weapons ) )
	{
		return false;
	}

	return IsDefined( level.zombie_weapons[weapon_name] );
}


include_zombie_weapon( weapon_name, in_box, collector, weighting_func )
{
	if( !IsDefined( level.zombie_include_weapons ) )
	{
		level.zombie_include_weapons = [];
		level.collector_achievement_weapons = [];
	}
	if( !isDefined( in_box ) )
	{
		in_box = true;
	}
	if( isDefined( collector ) && collector )
	{
		level.collector_achievement_weapons = array_add( level.collector_achievement_weapons, weapon_name );
	}

	level.zombie_include_weapons[weapon_name] = in_box;

	PrecacheItem( weapon_name );

	if( !isDefined( weighting_func ) )
	{
		level.weapon_weighting_funcs[weapon_name] = maps\_zombiemode_weapons::default_weighting_func;
	}
	else
	{
		level.weapon_weighting_funcs[weapon_name] = weighting_func;
	}
}


//
//Z2 add_zombie_weapon will call PrecacheItem on the weapon name.  So this means we're loading 
//		the model even if we're not using it?  This could save some memory if we change this.

ZHC_get_ordered_weapon_keys(){
	k = [];

	k[k.size] = "zombie_cymbal_monkey"; //1
	

	k[k.size] = "m1911_zm";
	k[k.size] = "knife_ballistic_zm";
	k[k.size] = "cz75_zm";
	k[k.size] = "pm63_zm";

	k[k.size] = "zombie_cymbal_monkey"; //2

	k[k.size] = "m14_zm";
	k[k.size] = "rottweil72_zm";
	k[k.size] = "mp40_zm";

	k[k.size] = "g11_lps_zm";

	k[k.size] = "zombie_cymbal_monkey"; //3
	//k[k.size] = "frag_grenade_zm";
	//k[k.size] = "sticky_grenade_zm";
	//k[k.size] = "claymore_zm";

	k[k.size] = "china_lake_zm";
	k[k.size] = "dragunov_zm";
	k[k.size] = "mp5k_zm";
	k[k.size] = "ak74u_zm";
	k[k.size] = "fnfal_zm";
	k[k.size] = "ithaca_zm";
	k[k.size] = "cz75dw_zm";
	k[k.size] = "m16_zm";
	k[k.size] = "spectre_zm";
	k[k.size] = "famas_zm";
	k[k.size] = "m72_law_zm";
	k[k.size] = "python_zm";

	k[k.size] = "zombie_cymbal_monkey"; //4

	k[k.size] = "hs10_zm";
	k[k.size] = "l96a1_zm";
	k[k.size] = "aug_acog_zm";
	k[k.size] = "spas_zm";
	k[k.size] = "commando_zm";
	k[k.size] = "crossbow_explosive_zm";
	k[k.size] = "rpk_zm";
	k[k.size] = "hk21_zm";
	k[k.size] = "galil_zm";
	k[k.size] = "zombie_cymbal_monkey"; //moved
	k[k.size] = "ray_gun_zm";
	//
	k[k.size] = "thundergun_zm";
	//
	//k[k.size] = "tesla_gun_zm";	// included
	//k[k.size] = "freezegun_zm";
	//k[k.size] = "zombie_black_hole_bomb";
	//k[k.size] = "zombie_nesting_dolls";


	return k;
}

init_weapons()
{
	// Zombify
//	PrecacheItem( "zombie_melee" );

	//Z2 Weapons disabled for now
	// Pistols
	add_zombie_weapon( "m1911_zm",					"m1911_upgraded_zm",					&"ZOMBIE_WEAPON_M1911",					100,		"pistol",			"",		undefined );
	add_zombie_weapon( "python_zm",					"python_upgraded_zm",					&"ZOMBIE_WEAPON_PYTHON",				2200,		"pistol",			"",		undefined );
	add_zombie_weapon( "cz75_zm",					"cz75_upgraded_zm",						&"ZOMBIE_WEAPON_CZ75",					600,		"pistol",			"",		undefined );

	//	Weapons - SMGs
	add_zombie_weapon( "ak74u_zm",					"ak74u_upgraded_zm",					&"ZOMBIE_WEAPON_AK74U",					1200,		"smg",				"",		undefined );
	add_zombie_weapon( "mp5k_zm",					"mp5k_upgraded_zm",						&"ZOMBIE_WEAPON_MP5K",					1000,		"smg",				"",		undefined );
	add_zombie_weapon( "mp40_zm",					"mp40_upgraded_zm",						&"ZOMBIE_WEAPON_MP40",					1000,		"smg",				"",		undefined );
	add_zombie_weapon( "mpl_zm",					"mpl_upgraded_zm",						&"ZOMBIE_WEAPON_MPL",					1000,		"smg",				"",		undefined );
	add_zombie_weapon( "pm63_zm",					"pm63_upgraded_zm",						&"ZOMBIE_WEAPON_PM63",					1000,		"smg",				"",		undefined );
	add_zombie_weapon( "spectre_zm",				"spectre_upgraded_zm",					&"ZOMBIE_WEAPON_SPECTRE",				1000,		"smg",				"",		undefined );

	//	Weapons - Dual Wield
	add_zombie_weapon( "cz75dw_zm",					"cz75dw_upgraded_zm",					&"ZOMBIE_WEAPON_CZ75DW",				1200,		"dualwield",		"",		undefined );

	//	Weapons - Shotguns
	add_zombie_weapon( "ithaca_zm",					"ithaca_upgraded_zm",					&"ZOMBIE_WEAPON_ITHACA",				1500,		"shotgun",			"",		undefined );
	add_zombie_weapon( "spas_zm",					"spas_upgraded_zm",						&"ZOMBIE_WEAPON_SPAS",					5000,		"shotgun",			"",		undefined );
	add_zombie_weapon( "rottweil72_zm",				"rottweil72_upgraded_zm",				&"ZOMBIE_WEAPON_ROTTWEIL72",			500,		"shotgun",			"",		undefined );
	add_zombie_weapon( "hs10_zm",					"hs10_upgraded_zm",						&"ZOMBIE_WEAPON_HS10",					2000,		"shotgun",			"",		undefined );

	//	Weapons - Semi-Auto Rifles
	add_zombie_weapon( "m14_zm",					"m14_upgraded_zm",						&"ZOMBIE_WEAPON_M14",					500,		"rifle",			"",		undefined );

	//	Weapons - Burst Rifles
	add_zombie_weapon( "m16_zm",					"m16_gl_upgraded_zm",					&"ZOMBIE_WEAPON_M16",					1200,		"burstrifle",		"",		undefined );
	add_zombie_weapon( "g11_lps_zm",				"g11_lps_upgraded_zm",					&"ZOMBIE_WEAPON_G11",					1200,		"burstrifle",		"",		undefined );
	add_zombie_weapon( "famas_zm",					"famas_upgraded_zm",					&"ZOMBIE_WEAPON_FAMAS",					1200,		"burstrifle",		"",		undefined );

	//	Weapons - Assault Rifles
	add_zombie_weapon( "aug_acog_zm",				"aug_acog_mk_upgraded_zm",				&"ZOMBIE_WEAPON_AUG",					1600,	"assault",			"",		undefined );
	add_zombie_weapon( "galil_zm",					"galil_upgraded_zm",					&"ZOMBIE_WEAPON_GALIL",					6000,	"assault",			"",		undefined );
	add_zombie_weapon( "commando_zm",				"commando_upgraded_zm",					&"ZOMBIE_WEAPON_COMMANDO",				4500,	"assault",			"",		undefined );
	add_zombie_weapon( "fnfal_zm",					"fnfal_upgraded_zm",					&"ZOMBIE_WEAPON_FNFAL",					1500,	"burstrifle",			"",		undefined );

	//	Weapons - Sniper Rifles
	add_zombie_weapon( "dragunov_zm",				"dragunov_upgraded_zm",					&"ZOMBIE_WEAPON_DRAGUNOV",				850,		"sniper",			"",		undefined );
	add_zombie_weapon( "l96a1_zm",					"l96a1_upgraded_zm",					&"ZOMBIE_WEAPON_L96A1",					4500,		"sniper",			"",		undefined );

	//	Weapons - Machineguns
	add_zombie_weapon( "rpk_zm",					"rpk_upgraded_zm",						&"ZOMBIE_WEAPON_RPK",					6500,		"mg",				"",		undefined );
	add_zombie_weapon( "hk21_zm",					"hk21_upgraded_zm",						&"ZOMBIE_WEAPON_HK21",					7000,		"mg",				"",		undefined );

	// Grenades                                         		
	add_zombie_weapon( "frag_grenade_zm", 			undefined,								&"ZOMBIE_WEAPON_FRAG_GRENADE",			250,	"grenade",			"",		undefined );
	add_zombie_weapon( "sticky_grenade_zm", 		undefined,								&"ZOMBIE_WEAPON_STICKY_GRENADE",		250,	"grenade",			"",		undefined );
	add_zombie_weapon( "claymore_zm", 				undefined,								&"ZOMBIE_WEAPON_CLAYMORE",				1500,	"grenade",			"",		undefined );

	// Rocket Launchers
	add_zombie_weapon( "m72_law_zm", 				"m72_law_upgraded_zm",					&"ZOMBIE_WEAPON_M72_LAW",	 			7500,	"launcher",			"",		undefined ); 
	add_zombie_weapon( "china_lake_zm", 			"china_lake_upgraded_zm",				&"ZOMBIE_WEAPON_CHINA_LAKE", 			750,	"launcher",			"",		undefined ); 

	// Special                                          	
 	add_zombie_weapon( "zombie_cymbal_monkey",		undefined,								&"ZOMBIE_WEAPON_SATCHEL_2000", 			2000,	"monkey",			"",		undefined );
 	add_zombie_weapon( "ray_gun_zm", 				"ray_gun_upgraded_zm",					&"ZOMBIE_WEAPON_RAYGUN", 				20000,	"raygun",			"",		undefined );
 	add_zombie_weapon( "tesla_gun_zm",				"tesla_gun_upgraded_zm",				&"ZOMBIE_WEAPON_TESLA", 				50000,		"tesla",			"",		undefined );
 	add_zombie_weapon( "thundergun_zm",				"thundergun_upgraded_zm",				&"ZOMBIE_WEAPON_THUNDERGUN", 			50000,		"thunder",			"",		undefined );
 	add_zombie_weapon( "crossbow_explosive_zm",		"crossbow_explosive_upgraded_zm",		&"ZOMBIE_WEAPON_CROSSBOW_EXPOLOSIVE",	1000,		"crossbow",			"",		undefined );
 	add_zombie_weapon( "knife_ballistic_zm",		"knife_ballistic_upgraded_zm",			&"ZOMBIE_WEAPON_KNIFE_BALLISTIC",		300,		"bowie",	"",		undefined );
 	add_zombie_weapon( "knife_ballistic_bowie_zm",	"knife_ballistic_bowie_upgraded_zm",	&"ZOMBIE_WEAPON_KNIFE_BALLISTIC",		300,		"bowie",	"",		undefined );
 	add_zombie_weapon( "knife_ballistic_sickle_zm",	"knife_ballistic_sickle_upgraded_zm",	&"ZOMBIE_WEAPON_KNIFE_BALLISTIC",		300,		"sickle",	"",		undefined );
 	add_zombie_weapon( "freezegun_zm",				"freezegun_upgraded_zm",				&"ZOMBIE_WEAPON_FREEZEGUN", 			10000,		"freezegun",		"",		undefined );
 	add_zombie_weapon( "zombie_black_hole_bomb",		undefined,							&"ZOMBIE_WEAPON_SATCHEL_2000", 			2000,	"gersh",			"",		undefined );
 	add_zombie_weapon( "zombie_nesting_dolls",		undefined,								&"ZOMBIE_WEAPON_NESTING_DOLLS", 		2000,	"dolls",	"",		undefined );

	if(IsDefined(level._zombie_custom_add_weapons))
	{
		[[level._zombie_custom_add_weapons]]();
	}

	Precachemodel("zombie_teddybear");
}   

//remove this function and whenever it's call for production. this is only for testing purpose.
add_limited_tesla_gun()
{
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" ); 

	for( i = 0; i < weapon_spawns.size; i++ )
	{
		hint_string = weapon_spawns[i].zombie_weapon_upgrade; 
		if(hint_string == "tesla_gun_zm")
		{
			weapon_spawns[i] waittill("trigger");
			weapon_spawns[i] disable_trigger();
			break;

		}
		
	}
}


add_limited_weapon( weapon_name, amount )
{
	if( !IsDefined( level.limited_weapons ) )
	{
		level.limited_weapons = [];
	}

	level.limited_weapons[weapon_name] = amount;
}                                          	

// For pay turrets
init_pay_turret()
{
	pay_turrets = [];
	pay_turrets = GetEntArray( "pay_turret", "targetname" );
	
	for( i = 0; i < pay_turrets.size; i++ )
	{
		cost = level.pay_turret_cost;
		if( !isDefined( cost ) )
		{
			cost = 1000;
		}
		pay_turrets[i] SetHintString( &"ZOMBIE_PAY_TURRET", cost );
		pay_turrets[i] SetCursorHint( "HINT_NOICON" );
		pay_turrets[i] UseTriggerRequireLookAt();
		
		pay_turrets[i] thread pay_turret_think( cost );
	}
}

// For buying weapon upgrades in the environment
init_weapon_upgrade()
{
	weapon_spawns = [];
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );

	ZHC_wall_buy_options_init();	//added for mod

	for( i = 0; i < weapon_spawns.size; i++ )
	{
		weapon_spawns[i] wall_weapon_setup();
		weapon_spawns[i] thread weapon_spawn_think(false, false); 
	}
}

wall_weapon_setup(){
	hint_string = get_weapon_hint( self.zombie_weapon_upgrade ); 
	cost = get_weapon_cost( self.zombie_weapon_upgrade );

	self SetHintString( hint_string, cost ); 
	self setCursorHint( "HINT_NOICON" ); 
	self UseTriggerRequireLookAt();

		//weapon_spawns[i] thread weapon_spawn_think(); //moved for mod
	model = getent( self.target, "targetname" ); 
	model useweaponhidetags( self.zombie_weapon_upgrade );
	model hide();
}


door_barr_set_info_on_buy_door(player){//should happen when the player buys or opens door that will eventually have a barr weapon when the door expires.
	if(!self.doors.size){
		IPrintLnBold( "NO DOORS TO BARR. aborting weapon barr" );
		return;
	}

	if(!IsDefined( player ))
		player = self.last_user;

	if(!isDefined(player)){
		IPrintLnBold( "NO 'self.last_user' ASSIGNED FOR WEAPON BARR aborting weapon barr" );
		return;
	}

	//door_middle = undefined;
	//player_yaw = undefined;
	//yaw = undefined;

	all_trigs = getentarray( self.target, "target" ); 
	if(!IsDefined( self.barr_door_middle )){
		closest = undefined;
		/*for( i = 0; i < all_trigs.size; i++ )
		{
			if(player IsTouching(all_trigs[i])){
				//IPrintLn( "trig "+i+ "/"+all_trigs.size+" found by touch" );
				closest = all_trigs[i];
				break;
			}
		}*/
		//if(!IsDefined( closest )){
			closest_dist = undefined;
			for( i = 0; i < all_trigs.size; i++ )	//FINds origin or closes trigger
			{
				dist = DistanceSquared( player.origin, all_trigs[i].origin );
				if(!IsDefined( closest ) || closest_dist > dist){
					closest = all_trigs[i];
					closest_dist = dist;
				}
			}
		//}

		if(!isDefined(closest)){
			IPrintLnBold( "NO TRIGGER FOUND FOR DOOR BARR WEAPON. aborting weapon barr" );
			return;
		}
		self.barr_door_middle = closest.origin;
	}
	//barr_weapon_yaw = undefined;
	if(!isDefined(
	self.barr_weapon_yaw)){		//if the map has doors which sister doors share a diffrent rotation to each other, this should be changed to run wether defined or not.
		closest_door = undefined;
		closest_dist = undefined;
		for( i = 0; i < self.doors.size; i++ )
		{
			dist = DistanceSquared( self.barr_door_middle, self.doors[i].origin );
			if(
				isDefined (self.doors[i].script_string) && self.doors[i].script_string == "rotate" && //becuase we want to ovid super close fake doors that for some reason exist really close to some triggers. we want a real hinge "rotate" door.
				(!IsDefined( closest_door )|| closest_dist > dist)			//if distance is close
				 				
			){
				closest_door = self.doors[i];
				closest_dist = dist;
			}
			/*if(print_some_info){
				script_string = self.doors[i].script_string;
				if(!IsDefined( script_string )){
					script_string = "undf";
				}
				IPrintLnBold("door_index: "+i+" dist"+ sqrt(dist) + "  script: " + script_string );
				wait(5);
			}*/
		}
		if(!isDefined(closest_door)){
			IPrintLnBold( "NO CLOSEST DOOR FOUND FOR DOOR BARR WEAPON. aborting weapon barr" );
			return;
		}
		yaw = VectorToAngles( self.barr_door_middle - closest_door.origin )[1];
		yaw = AngleClamp180(int((yaw+45)/90)*90);
		self.barr_weapon_yaw = yaw;
	}

	/*if(print_some_info){
		IPrintLnBold("    mid: "+ door_middle + " -  hinge: "+ closest_door.origin);
		wait (2);
		IPrintLnBold( "  ==>   " + (door_middle - closest_door.origin));
		wait (2);
		IPrintLnBold( "angles> " + VectorToAngles( door_middle - closest_door.origin ));
		wait (2);
		IPrintLnBold( "yaw ==  " + VectorToAngles( door_middle - closest_door.origin )[1]);
		wait(2);
		IPrintLnBold( "yawclmp " +(int((VectorToAngles( door_middle - closest_door.origin )[1]+45)/90)*90));
	}*/

	

	

	self.player_yaw = get_player_yaw_from_relative_position(player.origin, self.barr_weapon_yaw, self.barr_door_middle);

	/*self.weapon_model = spawn( "script_model",self.barr_weapon_origin);
	self set_box_weapon_model_to(player GetCurrentWeapon());
	self.weapon_model.angles = (0, self.barr_weapon_yaw, 0);

	self.weapon_model = spawn( "script_model",self.barr_weapon_trigger_origin);
	self set_box_weapon_model_to("aug_acog_zm");
	self.weapon_model.angles = (0, self.barr_weapon_yaw, 0);

	self.weapon_model = spawn( "script_model",self.barr_weapon_locked_side_trigger_origin);
	self set_box_weapon_model_to("frag_grenade_zm");
	self.weapon_model.angles = (0, self.barr_weapon_yaw, 0);*/

}

get_player_yaw_from_relative_position(player_origin, surface_yaw, surface_middle){
	player_yaw = VectorToAngles( surface_middle - player_origin )[1];
	player_yaw0 = player_yaw;
	player_yaw  = AngleClamp180(int((player_yaw+45)/90)*90);
	player_yaw2 = player_yaw;
	for(i = 0 ; i < 3; i ++){
		if(player_yaw2 == surface_yaw || player_yaw2 == AngleClamp180(surface_yaw + 180) || angle_dif(player_yaw2 ,player_yaw0 ) > 90){
			player_yaw2-=90;
			player_yaw2  = AngleClamp180(player_yaw2);
		}else{
			break;
		}
	}
	player_yaw = player_yaw2;
	return player_yaw;
}

door_barr_weapon(){
	self endon ("open_door");
	self endon ("end_door_cooldown");

	if(self._door_open || isDefined(self.transitioning_t_open_f_close))			//wait for door to be accully closed first.
		self waittill( "door_closed" );

	if(!isDefined(self.player_yaw)){
		IPrintLnBold( "DOOR BARR INFO NOT SET"  );
		return;
	}

	same_side = true;

	//roomId_barr_appears_from = maps\_zombiemode_blockers::Get_Zone_Room_ID(maps\_zombiemode_blockers::Get_Players_Current_Zone(player));	//room id of the player that bought the door
	if(same_side)
		roomId_barr_appears_from = self.roomId_bought_to;
	else
		roomId_barr_appears_from = self.roomId_bought_from;	//way cheaper and uses already accesible info

	

	if(!IsDefined( roomId_barr_appears_from) ){
		IPrintLnBold( "DOOR BARR ROOMIDS NOT SET"  );
		return;
	}


	//wait for player be inside room.
	if(IsDefined( roomId_barr_appears_from )){
		wait_network_frame( );
		//while(1){
		player = self maps\_zombiemode_blockers::waittill_roomID_is_occupied_return_player(roomId_barr_appears_from);
		//	if(!maps\_zombiemode_blockers::player_is_in_dead_zone(player, self maps\_zombiemode_blockers::get_door_id()))
		//		break;
		//	else
		//		wait 0.25;
		//}
	}
	else{
		IPrintLnBold( "DOOR BARR ROOM NOT DEFINED" );
		return;
	}

	can_upgrade = true;
	CAN_ONLY_UPGRADE_IF_ROOM_LOCKED = true;
	if(CAN_ONLY_UPGRADE_IF_ROOM_LOCKED){
		doorIds = maps\_zombiemode_blockers::Get_Doors_Accesible_in_room(roomId_barr_appears_from); //doors in room accessed
		doorIds = array_remove( doorIds,self maps\_zombiemode_blockers::get_door_id() );
		doorIds = array_remove(doorIds, 6);doorIds = array_remove(doorIds, 9);	//remove electrical doors
		can_upgrade = !maps\_zombiemode_blockers::one_door_is_unbarred(doorIds);
	}

	weapon = undefined;
	weapon_model = undefined;
	player_cur_weapon = player GetCurrentWeapon();
	player_primaries = player GetWeaponsListPrimaries();
	for(i = 0; i < player_primaries.size; i++){
		if(player_cur_weapon == player_primaries[i]){
			weapon = player_cur_weapon;
			break;
		}
	}
	if(!isDefined(weapon)){
		if(IsDefined( player_primaries[0] )){
			weapon = player_primaries[0];
		}else{
			weapon = "ray_gun_zm";
		}
	}
	wep_class = WeaponClass( weapon );
	if(weapon == "m1911_zm"){
	//if(wep_class == "pistol" || wep_class == "smg" || wep_class == "bowie" || wep_class == "sickle" || wep_class == "raygun"){
		default_weaps = [];
		//default_weaps[default_weaps.size] = "spas_zm";
		//default_weaps[default_weaps.size] = "claymore_zm";
		//default_weaps[default_weaps.size] = "bowie_knife_zm";		// gona be complicated to intergrate.
		//default_weaps[default_weaps.size] = "frag_grenade_zm";
		default_weaps[default_weaps.size] = "frag_grenade_zm";
		//weapon = default_weaps[level.round_number%default_weaps.size];
		weapon = default_weaps[RandomInt( default_weaps.size )];
	}else if(wep_class == "bowie" || wep_class == "sickle"){
		//weapon = "specialty_knifeescape";
		//none of these models are defined, find the correct models.
		if(player HasWeapon( "bowie_knife_zm" ))
			weapon_model = GetWeaponModel("bowie_knife_zm");
		else if(player HasWeapon( "sickle_knife_zm" ))
			weapon_model = GetWeaponModel("sickle_knife_zm");
		else
			weapon_model = GetWeaponModel("knife_zm");
	}	
	
	
	if(same_side){
		sister = self maps\_zombiemode_blockers::get_sister_door();
		if(sister != self){
			sister = maps\_zombiemode_blockers::get_sister_door();
			sister door_barr_set_info_on_buy_door(player);
			sister door_barr_weapon_spawn(weapon, weapon_model, false, roomId_barr_appears_from, can_upgrade);
			return;
		}
	}
	
	//self.cur_barr_weapon = weapon;   //set that weapon to self.cur_barr_weapon

	self door_barr_weapon_spawn(weapon, weapon_model, same_side, roomId_barr_appears_from, can_upgrade);		//spawn weapon
}

door_barr_weapon_spawn(weapon_string, weapon_model, same_side, roomId_visible_from, can_upgrade){
	self notify ("door_barr_started");
	self maps\_zombiemode_blockers::get_sister_door() notify ("door_barr_started");

	self.weapon_trigger = door_barr_weapon_setup(weapon_string, weapon_model, same_side, self.barr_door_middle, self.player_yaw, self.barr_weapon_yaw 
		);

	play_sound_at_pos( "weapon_show", self.origin);
	self.weapon_trigger thread weapon_model_hide();
	self.weapon_trigger thread show_weapon_model();

	//playfx(level._effect["poltergeist"], barr_weapon_trigger_origin);	//playes electricity effect when barr weapon spawns.


	self thread weapon_end_on_door_open();
	self thread weapon_thread_manage_triggers(roomId_visible_from);

	self.zombie_weapon_upgrade = weapon_string; //neaded for swap. but also good info to have generally.
	self thread chest_weapon_swap(roomId_visible_from, can_upgrade);

	is_equipment = is_equipment(weapon_string) || is_placeable_mine(weapon_string) || (WeaponType( weapon_string ) == "grenade");
	can_init_buy = false;	//always true for now.
	can_buy_ammo = is_equipment || true; //lets make it always true for now
	can_upgrade = !is_equipment && can_upgrade;
	self.weapon_trigger thread weapon_spawn_think(false, undefined, can_init_buy, can_buy_ammo ,can_upgrade, weapon_string);	//can buy and upgrade, cant buy ammo
}

chest_weapon_swap(roomId_visible_from, can_upgrade){
	self.weapon_trigger endon("deleted");
	last_threaded_chestIds_index = 0;
	max_chest_size = 1;
	while(1){
		chestIds = level.ZHC_room_info[roomId_visible_from]["chests"];
		if(chestIds.size <= last_threaded_chestIds_index)	//sees if new chest was added
			wait(0.5);
		else{
			self thread chest_weapon_grab_change_door_weapon(level.chests[chestIds[last_threaded_chestIds_index]].chest_origin, can_upgrade);
			last_threaded_chestIds_index++;
			if(last_threaded_chestIds_index >= max_chest_size)
				return;
		}
	}
	/*for(i = 0; i < chestIds.size; i++){
		self thread chest_weapon_grab_change_door_weapon(level.chests[chestIds[i]].chest_origin, can_upgrade);
	}*/
}

chest_weapon_grab_change_door_weapon(chest_origin, can_upgrade){
	self.weapon_trigger endon("deleted");
	while(1){
		chest_origin waittill("weapon_grabbed", weapon);
		if(is_offhand_weapon(weapon))	//not a primary weapon.
			continue;
		if(self.zombie_weapon_upgrade == weapon)
			continue;
		is_equipment = false;//is_equipment(weapon_string) || is_placeable_mine(weapon_string) || (WeaponType( weapon_string ) == "grenade");
		can_init_buy = false;	//always true for now.
		can_buy_ammo = is_equipment || true; //lets make it always true for now
		can_upgrade = !is_equipment && can_upgrade;
		self.zombie_weapon_upgrade = weapon;
		self.weapon_trigger thread swap_weapon_buyable(false, can_init_buy, can_buy_ammo ,can_upgrade, weapon);
	}
}


door_barr_weapon_setup(weapon_string, weapon_model, same_side, door_barr_middle_origin, player_yaw, barr_weapon_yaw
	){
	if(same_side)
	player_yaw = AngleClamp180(player_yaw + 180);

	barr_weapon_origin = door_barr_middle_origin - ( AnglesToForward( ( 0, player_yaw, 0 ) ) * 8 );
	barr_weapon_trigger_origin = door_barr_middle_origin - ( AnglesToForward( ( 0, player_yaw, 0 ) ) * 8 );
	//barr_weapon_locked_side_trigger_origin = self.barr_door_middle - ( AnglesToForward( ( 0, self.player_yaw, 0 ) ) * 50 );

	//self should be door trigger

	//weapon_string = self get_door_barr_weapon(); //gets weapon

	//self disable_trigger();
	//self.locked_side_trigger = Spawn( "trigger_radius", self.barr_weapon_locked_side_trigger_origin, 0, 55, 12 );
	//self.locked_side_trigger SetHintString( "Door barred from other side." );
	//self.locked_side_trigger setCursorHint( "HINT_NOICON" );
	
	//isPerk = IsSubStr( weapon_string ,"specialty_" );

	weapon_trigger = Spawn( "trigger_radius_use", barr_weapon_trigger_origin, 0, 55, 12 );
	weapon_trigger.weapon_model = spawn( "script_model", barr_weapon_origin); 
	weapon_trigger.weapon_model.angles = ( 0, barr_weapon_yaw, 0 );
	weapon_trigger.weapon_model.yaw = player_yaw;

	if(weapon_is_dual_wield(weapon_string)){
		weapon_trigger.weapon_model_dw = spawn( "script_model", barr_weapon_origin - (0 ,0 ,10)); 
		weapon_trigger.weapon_model_dw.angles = ( 0, AngleClamp180(barr_weapon_yaw + 180), 0 );
		weapon_trigger.weapon_model_dw.yaw = player_yaw;
		weapon_trigger.weapon_model_dw LinkTo( weapon_trigger.weapon_model );
		
	}

	if(!IsDefined( weapon_model ))
		weapon_trigger set_box_weapon_model_to(weapon_string);
	else{
		weapon_trigger.weapon_model show();
		weapon_trigger.weapon_model setmodel( weapon_model ); 
	}

	weapon_trigger SetHintString( get_weapon_hint( weapon_string ), get_weapon_cost( weapon_string ) ); 
	weapon_trigger setCursorHint( "HINT_NOICON" );
	weapon_trigger UseTriggerRequireLookAt();
	return weapon_trigger;
}

weapon_thread_manage_triggers(roomId_visible_from){

	//self.weapon_trigger endon("weapon_stop");	//instead checks if weapon_trigger exists
	self.weapon_trigger endon("deleted");	//should end when weapon trigger gets destroyed by thread weapon_stop_on_door_open()

	zones = maps\_zombiemode_blockers::roomIDToZones(roomId_visible_from);

	if(!IsDefined( zones )){
		IPrintLnBold( "NO VOLUMES FOUND" );
		return;
	}
	players = get_players();
	while(1){
		//if(!IsDefined( weapon_trigger ))	//checks if weapon_trigger exists
		//	return;
		playervis = [];
		for(zz = 0; zz < zones.size; zz++){
			if(level.zones[zones[zz]].is_occupied){
				for(i = 0; i < players.size; i++){
					if(isDefined(players[i].current_zone) && players[i].current_zone == zones[zz])
					{
						playervis[i] = true;
					}
				}
			}
		}

		for(i = 0; i < players.size; i++){
			if(isDefined(playervis[i])){
				self.weapon_trigger SetVisibletoPlayer( players[i] );
				self SetInvisibletoPlayer( players[i] );
			}else{
				self.weapon_trigger SetInvisibletoPlayer( players[i] );
				self SetVisibletoPlayer( players[i] );
			}
		}

		wait(1);
	}
}

weapon_end_on_door_open(){
	self waittill_either( "door_open", "end_door_cooldown" );
	playfx(level._effect["poltergeist"], self.barr_door_middle - ( AnglesToForward( ( 0, self.player_yaw, 0 ) ) * 45 ));

	self.weapon_trigger delete_weapon_model();

	//self.barr_door_middle = undefined;		//keep these vars as is
	//self.barr_weapon_yaw = undefined;			//keeps these vars as is
	self.player_yaw = undefined;

	self.weapon_trigger notify("weapon_stop");
	self.weapon_trigger notify("deleted"); 
	self.weapon_trigger delete();

	players = get_players();
	for(i = 0; i < players.size; i++){
		self SetVisibletoPlayer( players[i] );
	}
	//self.locked_side_trigger delete();
	//self enable_trigger();
}


// For toggling which weapons can appear from the box
init_weapon_toggle()
{
	if ( !isdefined( level.magic_box_weapon_toggle_init_callback ) )
	{
		return;
	}

	level.zombie_weapon_toggles = [];
	level.zombie_weapon_toggle_max_active_count = 0;
	level.zombie_weapon_toggle_active_count = 0;

	PrecacheString( &"ZOMBIE_WEAPON_TOGGLE_DISABLED" );
	PrecacheString( &"ZOMBIE_WEAPON_TOGGLE_ACTIVATE" );
	PrecacheString( &"ZOMBIE_WEAPON_TOGGLE_DEACTIVATE" );
	PrecacheString( &"ZOMBIE_WEAPON_TOGGLE_ACQUIRED" );
	level.zombie_weapon_toggle_disabled_hint = &"ZOMBIE_WEAPON_TOGGLE_DISABLED";
	level.zombie_weapon_toggle_activate_hint = &"ZOMBIE_WEAPON_TOGGLE_ACTIVATE";
	level.zombie_weapon_toggle_deactivate_hint = &"ZOMBIE_WEAPON_TOGGLE_DEACTIVATE";
	level.zombie_weapon_toggle_acquired_hint = &"ZOMBIE_WEAPON_TOGGLE_ACQUIRED";

	PrecacheModel( "zombie_zapper_cagelight" );
	PrecacheModel( "zombie_zapper_cagelight_green" );
	PrecacheModel( "zombie_zapper_cagelight_red" );
	PrecacheModel( "zombie_zapper_cagelight_on" );
	level.zombie_weapon_toggle_disabled_light = "zombie_zapper_cagelight";
	level.zombie_weapon_toggle_active_light = "zombie_zapper_cagelight_green";
	level.zombie_weapon_toggle_inactive_light = "zombie_zapper_cagelight_red";
	level.zombie_weapon_toggle_acquired_light = "zombie_zapper_cagelight_on";

	weapon_toggle_ents = [];
	weapon_toggle_ents = GetEntArray( "magic_box_weapon_toggle", "targetname" );

	for ( i = 0; i < weapon_toggle_ents.size; i++ )
	{
		struct = SpawnStruct();

		struct.trigger = weapon_toggle_ents[i];
		struct.weapon_name = struct.trigger.script_string;
		struct.upgrade_name = level.zombie_weapons[struct.trigger.script_string].upgrade_name;
		struct.enabled = false;
		struct.active = false;
		struct.acquired = false;

		target_array = [];
		target_array = GetEntArray( struct.trigger.target, "targetname" );
		for ( j = 0; j < target_array.size; j++ )
		{
			switch ( target_array[j].script_string )
			{
			case "light":
				struct.light = target_array[j];
				struct.light setmodel( level.zombie_weapon_toggle_disabled_light );
				break;
			case "weapon":
				struct.weapon_model = target_array[j];
				struct.weapon_model hide();
				break;
			}
		}

		struct.trigger SetHintString( level.zombie_weapon_toggle_disabled_hint );
		struct.trigger setCursorHint( "HINT_NOICON" );
		struct.trigger UseTriggerRequireLookAt();

		struct thread weapon_toggle_think();

		level.zombie_weapon_toggles[struct.weapon_name] = struct;
	}

	//for initial enable and disable of toggles, and determination of which are activated
	level thread [[level.magic_box_weapon_toggle_init_callback]]();
}


// an upgrade of a weapon toggle is also considered a weapon toggle
get_weapon_toggle( weapon_name )
{
	if ( !isdefined( level.zombie_weapon_toggles ) )
	{
		return undefined;
	}

	if ( isdefined( level.zombie_weapon_toggles[weapon_name] ) )
	{
		return level.zombie_weapon_toggles[weapon_name];
	}

	keys = GetArrayKeys( level.zombie_weapon_toggles );
	for ( i = 0; i < keys.size; i++ )
	{
		if ( weapon_name == level.zombie_weapon_toggles[keys[i]].upgrade_name )
		{
			return level.zombie_weapon_toggles[keys[i]];
		}
	}

	return undefined;
}


is_weapon_toggle( weapon_name )
{
	return isdefined( get_weapon_toggle( weapon_name ) );
}


disable_weapon_toggle( weapon_name )
{
	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}

	if ( toggle.active )
	{
		level.zombie_weapon_toggle_active_count--;
	}
	toggle.enabled = false;
	toggle.active = false;

	toggle.light setmodel( level.zombie_weapon_toggle_disabled_light );
	toggle.weapon_model hide();
	toggle.trigger SetHintString( level.zombie_weapon_toggle_disabled_hint );
}


enable_weapon_toggle( weapon_name )
{
	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}

	toggle.enabled = true;
	toggle.weapon_model show();
	toggle.weapon_model useweaponhidetags( weapon_name );

	deactivate_weapon_toggle( weapon_name );
}


activate_weapon_toggle( weapon_name, trig_for_vox )
{
	if ( level.zombie_weapon_toggle_active_count >= level.zombie_weapon_toggle_max_active_count )
	{
        if( IsDefined( trig_for_vox ) )
        {
            trig_for_vox thread maps\_zombiemode_audio::weapon_toggle_vox( "max" );
        }
            
		return;
	}

	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}
	
	if( IsDefined( trig_for_vox ) )
	{
	    trig_for_vox thread maps\_zombiemode_audio::weapon_toggle_vox( "activate", weapon_name );
	}

	level.zombie_weapon_toggle_active_count++;
	toggle.active = true;

	toggle.light setmodel( level.zombie_weapon_toggle_active_light );
	toggle.trigger SetHintString( level.zombie_weapon_toggle_deactivate_hint );
}


deactivate_weapon_toggle( weapon_name, trig_for_vox )
{
	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}
	
	if( IsDefined( trig_for_vox ) )
	{
	    trig_for_vox thread maps\_zombiemode_audio::weapon_toggle_vox( "deactivate", weapon_name );
	}

	if ( toggle.active )
	{
		level.zombie_weapon_toggle_active_count--;
	}
	toggle.active = false;

	toggle.light setmodel( level.zombie_weapon_toggle_inactive_light );
	toggle.trigger SetHintString( level.zombie_weapon_toggle_activate_hint );
}


acquire_weapon_toggle( weapon_name, player )
{
	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}

	if ( !toggle.active || toggle.acquired )
	{
		return;
	}
	toggle.acquired = true;

	toggle.light setmodel( level.zombie_weapon_toggle_acquired_light );
	toggle.trigger SetHintString( level.zombie_weapon_toggle_acquired_hint );
	
	toggle thread unacquire_weapon_toggle_on_death_or_disconnect_thread( player );
}


unacquire_weapon_toggle_on_death_or_disconnect_thread( player )
{
	self notify( "end_unacquire_weapon_thread" );
	self endon( "end_unacquire_weapon_thread" );

	player waittill_any( "spawned_spectator", "disconnect" );

	unacquire_weapon_toggle( self.weapon_name );
}


unacquire_weapon_toggle( weapon_name )
{
	toggle = get_weapon_toggle( weapon_name );
	if ( !isdefined( toggle ) )
	{
		return;
	}

	if ( !toggle.active || !toggle.acquired )
	{
		return;
	}

	toggle.acquired = false;

	toggle.light setmodel( level.zombie_weapon_toggle_active_light );
	toggle.trigger SetHintString( level.zombie_weapon_toggle_deactivate_hint );

	toggle notify( "end_unacquire_weapon_thread" );
}


weapon_toggle_think()
{
	for( ;; )
	{
		self.trigger waittill( "trigger", player ); 		
		// if not first time and they have the weapon give ammo

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}
        
		if ( !self.enabled || self.acquired )
		{
            self.trigger thread maps\_zombiemode_audio::weapon_toggle_vox( "max" );
		}
		else if ( !self.active )
		{
			activate_weapon_toggle( self.weapon_name, self.trigger );
		}
		else
		{
			deactivate_weapon_toggle( self.weapon_name, self.trigger );
		}
	}
}


// weapon cabinets which open on use
init_weapon_cabinet()
{
	// the triggers which are targeted at doors
	weapon_cabs = GetEntArray( "weapon_cabinet_use", "targetname" ); 

	for( i = 0; i < weapon_cabs.size; i++ )
	{

		weapon_cabs[i] SetHintString( &"ZOMBIE_CABINET_OPEN_1500" ); 
		weapon_cabs[i] setCursorHint( "HINT_NOICON" ); 
		weapon_cabs[i] UseTriggerRequireLookAt();
	}

//	array_thread( weapon_cabs, ::weapon_cabinet_think ); 
}

// returns the trigger hint string for the given weapon
get_weapon_hint( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].hint;
}

get_weapon_cost( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].cost;
}

get_ammo_cost( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].ammo_cost;
}

get_is_in_box( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );
	if(IsDefined( level.zombie_weapons[weapon_name].is_in_box ))
		return level.zombie_weapons[weapon_name].is_in_box;
	else 
		return false;
}

get_is_wall_buy( weapon_name)
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );
	weapon_spawns = [];
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" ); 

	for( i = 0; i < weapon_spawns.size; i++ )
	{
		if(weapon_spawns[i].zombie_weapon_upgrade == weapon_name)
			return true;
	}
	return false;
}


// Check to see if this is an upgraded version of another weapon
//	weaponname can be any weapon name.
is_weapon_upgraded( weaponname )
{
	if( !isdefined( weaponname ) || weaponname == "" )
	{
		return false;
	}

	weaponname = ToLower( weaponname );

	ziw_keys = GetArrayKeys( level.zombie_weapons );
	for ( i=0; i<level.zombie_weapons.size; i++ )
	{
		if ( IsDefined(level.zombie_weapons[ ziw_keys[i] ].upgrade_name) && 
			 level.zombie_weapons[ ziw_keys[i] ].upgrade_name == weaponname )
		{
			return true;
		}
	}

	return false;
}


//	Check to see if the player has the upgraded version of the weapon
//	weaponname should only be a base weapon name
//	self is a player
has_upgrade( weaponname )
{
	has_upgrade = false;
	if( IsDefined(level.zombie_weapons[weaponname]) && IsDefined(level.zombie_weapons[weaponname].upgrade_name) )
	{
		has_upgrade = self HasWeapon( level.zombie_weapons[weaponname].upgrade_name );
	}

	// double check for the bowie variant on the ballistic knife	
	if ( !has_upgrade && "knife_ballistic_zm" == weaponname )
	{
		has_upgrade = has_upgrade( "knife_ballistic_bowie_zm" ) || has_upgrade( "knife_ballistic_sickle_zm" );
	}

	return has_upgrade;
}


//	Check to see if the player has the normal or upgraded weapon
//	weaponname should only be a base weapon name
//	self is a player
has_weapon_or_upgrade( weaponname )
{
	upgradedweaponname = weaponname;
	if ( IsDefined( level.zombie_weapons[weaponname] ) && IsDefined( level.zombie_weapons[weaponname].upgrade_name ) )
	{
		upgradedweaponname = level.zombie_weapons[weaponname].upgrade_name;
	}

	has_weapon = false;
	// If the weapon you're checking doesn't exist, it will return undefined
	if( IsDefined( level.zombie_weapons[weaponname] ) )
	{
		has_weapon = self HasWeapon( weaponname ) || self has_upgrade( weaponname );
	}

	// double check for the bowie variant on the ballistic knife	
	if ( !has_weapon && "knife_ballistic_zm" == weaponname )
	{
		has_weapon = has_weapon_or_upgrade( "knife_ballistic_bowie_zm" ) || has_weapon_or_upgrade( "knife_ballistic_sickle_zm" );
	}

	return has_weapon;
}


// for the random weapon chest
//
//	The chests need to be setup as follows:
//		trigger_use - for the chest
//			targets the lid
//		lid - script_model.  Flips open to reveal the items
//			targets the script origin inside the box
//		script_origin - inside the box, used for spawning the weapons
//			targets the box
//		box - script_model of the outer casing of the chest
//		rubble - pieces that show when the box isn't there
//			script_noteworthy should be the same as the use_trigger + "_rubble"
//


treasure_chest_init()
{
	
	//CHANGED FOR MOD
	ZHC_treasure_chest_options_init();
	//ADDED FOR MOD

	if( level.mutators["mutator_noMagicBox"])
	{
		chests = GetEntArray( "treasure_chest_use", "targetname" );
		for( i=0; i < chests.size; i++ )
		{
			chests[i] get_chest_pieces();
			chests[i] hide_chest();
		}
		return;
	}

	flag_init("moving_chest_enabled");
	flag_init("moving_chest_now");
	flag_init("chest_has_been_used");
	
	level.chest_moves = 0;
	level.chest_level = 0;	// Level 0 = normal chest, 1 = upgraded chest
	level.chests = GetEntArray( "treasure_chest_use", "targetname" );
	for (i=0; i<level.chests.size; i++ )
	{
		level.chests[i].box_hacks = [];
		
		level.chests[i].orig_origin = level.chests[i].origin;
		level.chests[i] get_chest_pieces();

		if ( isDefined( level.chests[i].zombie_cost ) )
		{
			level.chests[i].old_cost = level.chests[i].zombie_cost;
		}
		else
		{
			// default chest cost
			level.chests[i].old_cost = GetNormalChestCost(level.chests[i]);
		}
	}

	level.chest_accessed = 0;

	if (level.chests.size > 1)
	{
		if(!level.ZHC_ORDERED_BOX || (level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX || level.ZHC_ORDERED_BOX_RANDOM_TEDDY))
			flag_set("moving_chest_enabled");
	
		level.chests = array_randomize(level.chests);

		//determine magic box starting location at random or normal
		init_starting_chest_location();

		if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM){
			level.chests[level.chest_index] thread ZHC_ALL_CHESTS_box_return(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL);
		}
	}
	else
	{
		level.chest_index = 0;
	}


	if(level.ZHC_ORDERED_BOX){
		thread ZHC_assign_weapons_to_boxes();	//threadin g for testing
	}

	array_thread( level.chests, ::treasure_chest_think );

}

ZHC_assign_weapons_to_boxes(){
	//keys = GetArrayKeys( level.zombie_weapons );
	keys = ZHC_get_ordered_weapon_keys();

	times_to_randomize = 2;
	chance_to_swap = 30;
	for(t = 0; t < times_to_randomize; t++){
		for(i = 0; i < keys.size-1; i++){
			//keepInPlace
			if(RandomInt( 100 )< chance_to_swap)  //% chance to swap up
			{	//swap up
				skip = int(min(RandomInt( 3 ), keys.size - i));
				if(i+skip >= keys.size)
					continue;
				y = keys[i];
				z = keys[i+skip];
				keys[i] = z;
				keys[i+skip] = y;
			}
		}
	}

	/*wait 10;
	for(i = 0; i < keys.size-1; i++){
		IPrintLn( keys[i] );
	}*/
//keys = array_randomize( keys );

	chests_num = level.chests.size;
	if(chests_num == 0)
		return;

	if(level.ZHC_ORDERED_BOX_ONE_ORDER){
		level.ZHC_chest_owned_weapons = [];
		level.ZHC_chest_owned_weapon_index = -1; //becomes 0 at iterator
		for(i = 0; i < keys.size ; i++){
			//sif(		!get_is_in_box(keys[i])
			//	|| 	!get_is_wall_buy(keys[i])
			// )
			//continue;

			level.ZHC_chest_owned_weapons[level.ZHC_chest_owned_weapons.size] = keys[i];		//adds weapon to 
			if(RandomInt( 3 ) == 0)
				level.ZHC_chest_owned_weapons[level.ZHC_chest_owned_weapons.size] = "teddy";
		}

	}else{

		for(i = chests_num-1; i >= 0 ; i--){
			level.chests[i].chest_origin.ZHC_chest_owned_weapons = [];
			level.chests[i].chest_origin.ZHC_chest_owned_weapon_index = -1; //becomes 0 at iterator
		}
		b = 0;
		
		chests = [];
		for(i = 0; i < chests_num; i++)
			chests[i] = level.chests[i];
		
		if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL){
			chests = array_remove_index( chests,level.chest_index );
			chests_num --;
		}
		chests = array_randomize( chests );
		
		progression = [];
		progression[progression.size] = 0;
		progression[progression.size] = 0;
		progression[progression.size] = 1;
		progression[progression.size] = 1;
		progression[progression.size] = 2;

		progression_index = 0;

		for(i = chests_num * progression[progression_index]; i < keys.size ; i++){
			//if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL && chests[b] == level.chests[level.chest_index])
			//	b++;
			if(b == chests_num){
				if(progression_index < progression.size){
					i = chests_num * progression[progression_index];
					progression_index++;
				}
				chests = array_randomize( chests );
				b = 0;
				//if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL && chests[b] == level.chests[level.chest_index])
				//	b++;
			}
			if(!get_is_in_box(keys[i])
			 //|| !get_is_wall_buy(keys[i])
			 )
				continue;
			if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL && ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL_save_for_special_box(keys[i])){
				level.chests[level.chest_index].chest_origin.ZHC_chest_owned_weapons[level.chests[level.chest_index].chest_origin.ZHC_chest_owned_weapons.size] = keys[i];
				continue;
			}

			chests[b].chest_origin.ZHC_chest_owned_weapons[chests[b].chest_origin.ZHC_chest_owned_weapons.size] = keys[i];		//adds weapon to 
			b++;
		}


		//randomize box a little

		/*times_to_randomize = 4;
		chance_to_swap = 50;
		for(t = 0; t < times_to_randomize; t++){
			for(b = 0; b < chests.size; b++){
				chestSize = chests[b].chest_origin.ZHC_chest_owned_weapons.size;
				for(i = 0; i < chestSize-1; i++){
					//keepInPlace
					if(RandomInt( 100 )< chance_to_swap)  //% chance to swap up
					{	//swap up
						y = chests[b].chest_origin.ZHC_chest_owned_weapons[i];
						z = chests[b].chest_origin.ZHC_chest_owned_weapons[i+1];
						chests[b].chest_origin.ZHC_chest_owned_weapons[i] = z;
						chests[b].chest_origin.ZHC_chest_owned_weapons[i+1] = y;
					}
				}
			}
		}*/

		ZHC_add_teddy();
	}
}

ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL_save_for_special_box(weapon_name){

	//return weapon_name  == "thundergun_zm";
	//return get_weapon_cost(weapon_name) > 10000;

	switch( weapon_name ){
		case "thundergun_zm":
		case "tesla_gun_zm":
		case "freezegun_zm":
		case "zombie_black_hole_bomb":
		case "zombie_nesting_dolls":
			return true;
		default:
			return false;
	}
	//return true;
}
ZHC_add_teddy(){
	if(!level.ZHC_ORDERED_BOX)
		return;
	if(level.ZHC_ORDERED_BOX_ONE_ORDER)
		return;
	if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY){
		ZHC_ORDERED_BOX_RANDOM_TEDDY_add_random_teddy();
	}
	else if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY_EVERY_BOX)
	{
		ZHC_ORDERED_BOX_RANDOM_TEDDY_EVERY_BOX_add_random_teddies();
	}
}
ZHC_ORDERED_BOX_RANDOM_TEDDY_add_random_teddy(){
	if(level.ZHC_ORDERED_BOX_ONE_ORDER)
		return;
	chests = array_randomize( level.chests );
	for(i = 0; i < chests.size; i++){
		if(chests[i].ZHC_ALL_CHESTS_chest_active && !is_true(chests[i].chest_origin.ZHC_has_teddy)){
			chests[i].chest_origin.ZHC_chest_owned_weapons[chests[i].chest_origin.ZHC_chest_owned_weapons.size] = "teddy";
			chests[i].chest_origin.ZHC_has_teddy = true;
			break;
		}
	}
}
ZHC_ORDERED_BOX_RANDOM_TEDDY_EVERY_BOX_add_random_teddies(){
	chests = array_randomize( level.chests );
	for(b = 0; b < chests.size; b++){
		teddy_wait = ZHC_get_teddy_wait();
			
		chestSize = chests[b].chest_origin.ZHC_chest_owned_weapons.size;
		for(i = 0; i < chestSize-1; i++){
			teddy_wait--;
			if(teddy_wait <= 0){
				teddy_wait = ZHC_get_teddy_wait();
				chests[b].chest_origin.ZHC_chest_owned_weapons = array_insert( chests[b].chest_origin.ZHC_chest_owned_weapons,"teddy",i );
			}
		}
	}
}

ZHC_get_teddy_wait(){
	spins =  int(
		max(0, min(1,randomInt(6)) ) + //1/6th chance to not add 1
		max(0, min(1,randomInt(3)) ) + // 1/3rd chance to not add 1
		max(0, min(1,randomInt(3)) ) // 1/3rd chance to not add 1
	) +
	int(  
		max(0,(-1*randomInt(5))+1) + //1/5th chance to add 1
		max(0,(-1*randomInt(5))+1) + //1/5th chance to add 1
		max(0,(-1*randomInt(10))+1) //1/10th chance to add 1
	);
	return spins;
}

ZHC_remove_teddy(chest_origin, multiple){

	if(!level.ZHC_ORDERED_BOX)
		return;
	if(level.ZHC_ORDERED_BOX_ONE_ORDER)
		return;

	if(!IsDefined( multiple ))
		multiple = false;

	if(IsDefined( chest_origin )){
		chest_origin.ZHC_chest_owned_weapon = array_remove(chest_origin.ZHC_chest_owned_weapons ,"teddy");
		chest_origin.ZHC_has_teddy = false;
	}
	else{
		chests_num = level.chests.size;
		for(i = chests_num-1; i >= 0 ; i--){
			level.chests[i].chest_origin.ZHC_chest_owned_weapon = array_remove(level.chests[i].chest_origin.ZHC_chest_owned_weapons ,"teddy");
			level.chests[i].chest_origin.ZHC_has_teddy = false;
		}
	}
}

init_starting_chest_location()
{
	level.chest_index = 0;
	start_chest_found = false;
	for( i = 0; i < level.chests.size; i++ )
	{
		if(level.ZHC_ALL_CHESTS){
			if (!level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM || (!IsDefined( level.chests[i].start_exclude) || !level.chests[i].start_exclude == 1)){
				if( !isDefined( level.pandora_show_func ) )
				{
					level.pandora_show_func = ::default_pandora_show_func;
				}
				level.chests[i].ZHC_ALL_CHESTS_chest_active = true;
				level.chests[i] thread [[ level.pandora_show_func ]]();
				//level.chest_index = i;
				level.chests[i] hide_rubble();
				level.chests[i].hidden = false;
				//start_chest_found = true;
			}else{
				level.chests[i].ZHC_ALL_CHESTS_chest_active = false;
				level.chests[i] hide_chest();	
				start_chest_found = true;
				level.chest_index = i;			//in_ZHC_level.chest_index only applies to the starting room chest which is initially off.
			}
		}
		else if( isdefined( level.random_pandora_box_start ) && level.random_pandora_box_start == true )
		{
			if (start_chest_found || (IsDefined( level.chests[i].start_exclude ) && level.chests[i].start_exclude == 1) )
			{
				level.chests[i] hide_chest();	
			}
			else
			{
				level.chest_index = i;
				level.chests[level.chest_index] hide_rubble();
				level.chests[level.chest_index].hidden = false;
				start_chest_found = true;
			}

		}
		else
		{
			// Semi-random implementation (not completely random).  The list is randomized
			//	prior to getting here.
			// Pick from any box marked as the "start_chest"
			if ( start_chest_found || !IsDefined(level.chests[i].script_noteworthy ) || ( !IsSubStr( level.chests[i].script_noteworthy, "start_chest" ) ) )
			{
				level.chests[i] hide_chest();	
			}
			else
			{
				level.chest_index = i;
				level.chests[level.chest_index] hide_rubble();
				level.chests[level.chest_index].hidden = false;
				start_chest_found = true;
			}
		}
	}

	if(!level.ZHC_ALL_CHESTS){
		// Show the beacon
		if( !isDefined( level.pandora_show_func ) )
		{
			level.pandora_show_func = ::default_pandora_show_func;
		}

		level.chests[level.chest_index] thread [[ level.pandora_show_func ]]();
	}
}


//
//	Rubble is the object that is visible when the box isn't
hide_rubble()
{
	rubble = getentarray( self.script_noteworthy + "_rubble", "script_noteworthy" );
	if ( IsDefined( rubble ) )
	{
		for ( x = 0; x < rubble.size; x++ )
		{
			rubble[x] hide();
		}
	}
	else
	{
		println( "^3Warning: No rubble found for magic box" );
	}
}


//
//	Rubble is the object that is visible when the box isn't
show_rubble()
{
	if ( IsDefined( self.chest_rubble ) )
	{
		for ( x = 0; x < self.chest_rubble.size; x++ )
		{
			self.chest_rubble[x] show();
		}
	}
	else
	{
		println( "^3Warning: No rubble found for magic box" );
	}
}


set_treasure_chest_cost( cost )
{
	level.zombie_treasure_chest_cost = cost;
}

//
//	Save off the references to all of the chest pieces
//		self = trigger
get_chest_pieces()
{
	self.chest_lid		= GetEnt(self.target,				"targetname");
	self.chest_origin	= GetEnt(self.chest_lid.target,		"targetname");

//	println( "***** LOOKING FOR:  " + self.chest_origin.target );

	self.chest_box		= GetEnt(self.chest_origin.target,	"targetname");

	//TODO fix temp hax to separate multiple instances
	self.chest_rubble	= [];
	rubble = GetEntArray( self.script_noteworthy + "_rubble", "script_noteworthy" );
	for ( i=0; i<rubble.size; i++ )
	{
		if ( DistanceSquared( self.origin, rubble[i].origin ) < 10000 )
		{
			self.chest_rubble[ self.chest_rubble.size ]	= rubble[i];
		}
	}
}

play_crazi_sound()
{
	if( is_true( level.player_4_vox_override ) )
	{
		self playlocalsound( "zmb_laugh_rich" );
	}
	else
	{
		self playlocalsound( "zmb_laugh_child" );	
	}
}



//
//	Show the chest pieces
//		self = chest use_trigger
//
show_chest()
{
	self thread [[ level.pandora_show_func ]]();

	if(!level.ZHC_BOX_AUTO_OPEN)
		self enable_trigger();

	self.chest_lid show();
	self.chest_box show();

	self.chest_lid playsound( "zmb_box_poof_land" );
	self.chest_lid playsound( "zmb_couch_slam" );

	self.hidden = false;

	if(IsDefined(self.box_hacks["summon_box"]))
	{
		self [[self.box_hacks["summon_box"]]](false);
	}
	
}

hide_chest()
{
	self disable_trigger();
	self.chest_lid hide();
	self.chest_box hide();

	if ( IsDefined( self.pandora_light ) )
	{
		self.pandora_light delete();
	}
	
	self.hidden = true;
	
	if(IsDefined(self.box_hacks["summon_box"]))
	{
		self [[self.box_hacks["summon_box"]]](true);
	}
}

default_pandora_fx_func( )
{
	self.pandora_light = Spawn( "script_model", self.chest_origin.origin );
	self.pandora_light.angles = self.chest_origin.angles + (-90, 0, 0);
	//	level.pandora_light.angles = (-90, anchorTarget.angles[1] + 180, 0);
	self.pandora_light SetModel( "tag_origin" );
	playfxontag(level._effect["lght_marker"], self.pandora_light, "tag_origin");
}


//
//	Show a column of light
//
default_pandora_show_func( anchor, anchorTarget, pieces )
{
	if ( !IsDefined(self.pandora_light) )
	{
		// Show the column light effect on the box
		if( !IsDefined( level.pandora_fx_func ) )
		{
			level.pandora_fx_func = ::default_pandora_fx_func;
		}
		self thread [[ level.pandora_fx_func ]]();
	}
	playsoundatposition( "zmb_box_poof", self.chest_lid.origin );
	wait(0.5);

	playfx( level._effect["lght_marker_flare"],self.pandora_light.origin );
	
	//Add this location to the map
	//Objective_Add( 0, "active", "Mystery Box", self.chest_lid.origin, "minimap_icon_mystery_box" );
}

get_chest_zone_name(){
	zkeys = GetArrayKeys( level.zones );
	for(j = 0; j < level.zones.size; j++)
	{
		for (i = 0; i < level.zones[zkeys[j]].volumes.size; i++)
		{
			if (self IsTouching(level.zones[zkeys[j]].volumes[i]) 
				//|| (isDefined(self.entrance_nodes[0]) && (self.entrance_nodes[0] IsTouching(level.zones[zkeys[j]].volumes[i])))
				)
			{
				return zkeys[j];
			}
		}
	}
	return undefined;
}

a_player_is_close_to_origin(dist){
	players = get_players();
	//("there are"+players.size+ "players");
	for( i = 0; i < players.size; i++ )
	{
		//("player "+i +"/"+players.size+ " is valid:" + (is_player_valid( players[i])) );
		if( is_player_valid( players[i]) ) 
		{
			//( "sqrdistace from door: "+ Distance2DSquared(self.origin , players[i].origin ));
			if(abs(self.origin[2] - players[i].origin[2]) > dist/2 ){
				//IPrintLnBold( "height pass "+ false + "  "+int(abs(self.origin[2] - players[i].origin[2])) +" > "+dist);
				continue;
			}
			pdist = Distance2DSquared(self.origin, players[i].origin);
			//IprintlnBold(pdist +" < "+dist*dist);
			if(pdist < dist*dist)
				return players[i];
		}
	}
}

ZHC_wall_buy_options_init(){
	level.ZHC_LOGICAL_WEAPON_SHOW = true;

	level.ZHC_WALL_UPGRADE_WEAPON_ON_CLONE_PICK_UP = false;

	level.ZHC_WALL_GUN_BUYABLE_SPAWN_POWERUPS = true;
	level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE = false;
		level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_AMMO = false;
		level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN = false;

	level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE = false;
		level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN = true;
}

ZHC_treasure_chest_options_init(){


	level.ZHC_BOX_EQUIPMENT_REALISTIC = true;
	level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE = true;
		level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_WAIT_TO_EXPIRE_CLOSE = true;
		level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_WAIT_TO_EXPIRE_CLOSE_RUN_BOTH_COOLDOWNS = false;
		level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_DOG_KILL_ENDS_WAIT = true;

	level.ZHC_BOX_AUTO_OPEN = true;
		level.ZHC_BOX_AUTO_OPENED_ROOM_CHECK = true;

	level.ZHC_BOX_UPGRADE_WEAPON_ON_CLONE_PICK_UP = false;
		level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE = true;
			level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN = true;

	level.ZHC_BOX_GUN_BUYABLE_SPAWN_POWERUPS = true;
	level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE = true;
		level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_AMMO = true;
		//level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN = false;


	level.ZHC_ALL_CHESTS = true;
		level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM = true;
			level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL = true;

	level.ZHC_ORDERED_BOX = true;
		level.ZHC_ORDERED_BOX_ONE_ORDER = false;

		level.ZHC_ORDERED_BOX_GUNS_STORABLE = true;
			level.ZHC_ORDERED_BOX_GUNS_STORABLE_CLOSE_WHEN_EMPTY = true;
			
		level.ZHC_ORDERED_BOX_CYCLE_UNLOCK = true;

		level.ZHC_ORDERED_BOX_RANDOM_TEDDY = false;	
		level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX = true;
		level.ZHC_ORDERED_BOX_RANDOM_TEDDY_EVERY_BOX = false;

		level.ZHC_ORDERED_BOX_FIRESALE_OGISH = false;					//buggy
		level.ZHC_ORDERED_BOX_FIRESALE_REASSIGN = false;				//messy


	level.ZHC_GUN_SWAP_TIMER_RESET = true;
	level.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP = true;

	level.ZHC_FIRESALE_CAN_CREATE_TEMP_CHESTS = true;					//make sure temp chest cant get teddy because thats a bit buggy rn.

	level.ZHC_FIRESALE_GRABBED_RESPIN_BOX_OPEN = false;
	level.ZHC_FIRESALE_GRABBED_OPEN_WHEN_CLOSED = false;				//no function


	level.ZHC_BOX_GUN_STAYS_WAIT = true;   //if false doesnt expire. if true does a cooldwon wait to become expired.
	level.ZHC_BOX_GUN_STAYS_WAIT_GUN_BUYABLE_RESET_EXPIRE_TIMER = false; //if the chest is buyable gun, ammo, or upgrade will reset the timer.
	level.ZHC_BOX_GUN_BUYABLE_EXPIRE_AFTER_USE = true;	//if the chest is buyable gun, ammo, or upgrade will expire after buying. weapon will drop.
	

	//bugs
	//ZHC_FIRESALE_TEDDY_PREMATURE_END makes firesale only apply once.
	//


	level.ZHC_FIRESALE_TEDDY_PREMATURE_END = true;
	level.ZHC_FIRESALE_APPLIES_ONLY_ONCE = false;						//makes it so firesale spin only applies once.

	level.ZHC_FIRESALE_DROP_WEAPON_FIRST_AT_CLOSE = true;						//if true, drops weapon, and disables trigger., if false instantly deletes weapon and closes door.
	level.ZHC_FIRESALE_CLOSE_AFTER_USE = false;
	level.ZHC_FIRESALE_CLOSE_AFTER_FIRESALE_OFF = true;	
}

ZHC_init_chest_options(){
	ZHC_treasure_chest_options_init();
	self.ZHC_GUN_STAYS = true;
	self.ZHC_GUN_BUYABLE = true;
	self.ZHC_GUN_SWAP = false;	
	self.ZHC_GUN_CYCLE = false;
	self.ZHC_FREE_TO_OPEN = false;
	if(level.ZHC_ORDERED_BOX && level.ZHC_ORDERED_BOX_CYCLE_UNLOCK && is_true(self.chest_origin.ZHC_ORDERED_BOX_CYCLE_UNLOCK_cycle_unlocked)){
		//self.ZHC_GUN_CYCLE = true;
		//self.ZHC_GUN_STAYS = true;
	}

}
ZHC_weapon_specific_box_changes(weapon_string){
	self endon ("box_finished");
	if(self.ZHC_GUN_BUYABLE){
		if(level.ZHC_BOX_EQUIPMENT_REALISTIC && weapon_string == "zombie_cymbal_monkey"){
			//self.ZHC_GUN_STAYS = false;
			self.ZHC_GUN_BUYABLE = false;
			level.ZHC_BOX_GUN_STAYS_WAIT = false;
			level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE = true;
			self playsound( "zmb_monkey_song" );
			//self playsound( "zmb_vox_monkey_scream" );
		}else if(weapon_string == "knife_ballistic_zm" || weapon_string == "thundergun_zm"){
			self.ZHC_GUN_BUYABLE = false;
			//level.ZHC_BOX_GUN_STAYS_WAIT = false;
			level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE = true;
		}
	}
	self waittill( "zhc_box_weapon_set" );
	ZHC_init_chest_options();
}

GetNormalChestCost(chest){
	return 950;
}


treasure_chest_think(){

	self ZHC_init_chest_options();

	self endon("kill_chest_think");

	self notify("zhc_box_awaiting_openening");

	costs_money = undefined;

	if(!level.ZHC_BOX_AUTO_OPEN){
		if(self.ZHC_FREE_TO_OPEN){
			self set_hint_string( self, "default_treasure_chest_" + "FREE" );
		}
		else if( self box_currently_affect_by_firesale())
		{
			self set_hint_string( self, "powerup_fire_sale_cost" );
		}
		else 
		{
			self set_hint_string( self, "default_treasure_chest_" + self.zombie_cost );
		}
		self setCursorHint( "HINT_NOICON" );


		costs_money = true;
		level.ZHC_TESTING_LEVEL = maps\ZHC_zombiemode_zhc::get_testing_level();
		if(level.ZHC_TESTING_LEVEL > 2 || self.ZHC_FREE_TO_OPEN)
			costs_money = false;	
	}else{
		self disable_trigger();
	}
	//todo maybe make if box manually opened that the chest has a "" hinstring. has to be changed in zombemode_powerups as well

	
	user = undefined;
	user_cost = undefined;
	self.box_rerespun = undefined;
	self.weapon_out = undefined;

	while( 1 )// waittill someuses uses this
	{
		if(is_true(self.hidden)){
			wait 0.1;
			continue;
		}

		if(!level.ZHC_BOX_AUTO_OPEN){
			if(!IsDefined(self.forced_user))
			{
				self waittill( "trigger", user ); 
			}
			else
			{
				user = self.forced_user;
			}
			
			if( user in_revive_trigger() )
			{
				wait( 0.1 );
				continue;
			}
			
			if( user is_drinking() )
			{
				wait( 0.1 );
				continue;
			}

			if ( is_true( self.disabled ) )
			{
				wait( 0.1 );
				continue;
			}

			if( user GetCurrentWeapon() == "none" )
			{
				wait( 0.1 );
				continue;
			}

			if(is_true(costs_money)){
				// make sure the user is a player, and that they can afford it
				if( IsDefined(self.auto_open) && is_player_valid( user ) )
				{
					if(!IsDefined(self.no_charge))
					{
						user maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
						user_cost = self.zombie_cost; 
					}
					else
					{
						user_cost = 0;
					}			
					
					self.chest_user = user;
					break;
				}
				else if( is_player_valid( user ) && user.score >= self.zombie_cost )
				{
					user maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
					user_cost = self.zombie_cost; 
					self.chest_user = user;
					break; 
				}
				else if ( user.score < self.zombie_cost )
				{
					user maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 2 );
					continue;	
				}
			}else{
				break;
			}

			wait 0.05;
		}else{
			//if(!self.ZHC_ALL_CHESTS_chest_active && !self box_currently_affect_by_firesale())
			
			if(!isDefined(self.roomId)){	//finding zone
				user = self.chest_origin a_player_is_close_to_origin(120);
				if(!isDefined(user)){
					wait 0.5;
				}
				else{
					zone = user.current_zone;
					//zone = maps\_zombiemode_blockers::Get_Players_Current_Zone_Patient(user);	//contains waits.
					self.roomId = maps\_zombiemode_blockers::Get_Zone_Room_ID(user.current_zone);
					level.ZHC_room_info[self.roomId]["chests"][level.ZHC_room_info[self.roomId]["chests"].size] = get_chest_index(self);
					if(!isDefined(self.roomId)){
						wait(1);
					}
				}
			}else if(level.ZHC_room_info[self.roomId]["occupied"]){
				if(level.ZHC_BOX_AUTO_OPENED_ROOM_CHECK)
					break;
				user = self.chest_origin a_player_is_close_to_origin(120);
				if(isDefined(user))
					break;
				else{
					wait 0.3333;
				}
			}
			else{
				wait 0.1;
			}
		}
	}


	if(!level.ZHC_BOX_AUTO_OPEN)
		flag_set("chest_has_been_used");

	if(!IsDefined( self._box_opened_by_fire_sale ))
		self._box_opened_by_fire_sale = false;

	if ( self box_currently_affect_by_firesale() && !IsDefined(self.auto_open))
	{
		self._box_opened_by_fire_sale = true;
	}

	//open the lid
	self.chest_lid thread treasure_chest_lid_open(self);
	self.chest_lid thread wait_to_close_lid(self);

	// SRS 9/3/2008: added to help other functions know if we timed out on grabbing the item
	self.timedOut = false;

	// mario kart style weapon spawning
	self.weapon_out = true;

	self thread ZHC_wait_for_firesale();
	self thread ZHC_wait_for_firesale_end();
	
	self.chest_origin thread treasure_chest_weapon_init_spawn( self, user); 

	// the glowfx	
	if(!self.ZHC_GUN_CYCLE && !self.ZHC_GUN_SWAP && !self.ZHC_GUN_BUYABLE)						//light lasts until weapon isnt on box
		self.chest_origin thread treasure_chest_glowfx(self, "weapon_grabbed");		//leght delets when weapon is grabbed
	else
		self.chest_origin thread treasure_chest_glowfx(self);		//light doesnt delete when swapped

	self disable_trigger(); 

	self middle_box_logic(costs_money,user_cost,user);
	//if(self.ZHC_GUN_BUYABLE)		//commented out to avoid potential complications, which may or may not exist
	self notify ("weapon_stop");
	
	self.grab_weapon_hint = false;
	self.chest_origin.ZHC_teddy_here = false;

	//self._box_open = false;
	self._box_opened_by_fire_sale = false;
	self.chest_user = undefined;
	
	self notify( "chest_accessed" );

	//if(self.chest_origin ZHC_teddy_is_here())
	//	wait(5);s

	if(!is_true(self.was_temp) && level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE){
		self ZHC_box_wait_to_become_reopenable();
	}
	if(
//		!is_true(self.chest_origin.chest_moving) &&
		!level.ZHC_BOX_AUTO_OPEN &&
		!self.hidden //&&
		/*(
			self box_currently_affect_by_firesale() || 
			(!level.ZHC_ALL_CHESTS && self == level.chests[level.chest_index])  || 
			(level.ZHC_ALL_CHESTS && self.ZHC_ALL_CHESTS_chest_active) 
		)*/
	)
	{
		//IPrintLnBold( "enabled before repeat" );
		self enable_trigger();
		self setvisibletoall();
	}

	wait_network_frame();
	wait_network_frame();

	if(!IsDefined( self.times_chest_opened ))
		self.times_chest_opened = 0;
	self.times_chest_opened ++;

	self thread treasure_chest_think();
}

ZHC_box_wait_to_become_reopenable(){
	self thread firesale_make_box_reopenable();
	if(level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_DOG_KILL_ENDS_WAIT){
		dognum =min(
					min(
						define_or(self.times_chest_opened,0),
						define_or(level.zombie_total_start, 0) - define_or(level.zombie_total,0)
					),
					max( int(flag("dog_round")) * 99,
						define_or(level.ZHC_dogs_spawned_this_mixed_round,0)
					)
				);

		dogs_kills_to_open_box = min(max(1,dognum),3);
		self thread maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, undefined, undefined, undefined, undefined, dogs_kills_to_open_box);
	}
	run_small_cooldown = true;
	if(level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_WAIT_TO_EXPIRE_CLOSE && is_true(self.zhc_cooldown_waiting)){
		self waittill("zhc_end_of_cooldown");	//if expire thread is still running (which is intentional) we will use that instead.
		self.zhc_cooldown_waiting = undefined;
		run_small_cooldown = level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_WAIT_TO_EXPIRE_CLOSE_RUN_BOTH_COOLDOWNS;
		if(run_small_cooldown)
			self thread firesale_make_box_reopenable(); //rerun after cooldown is over.
	}
	if(run_small_cooldown)
		self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, int(min(72, get_or(level.zombie_total_start, 1)/6.5)+8)  , 1, undefined, true);
	//iPrintLnBold("zhc_end_of_cooldown_box_reopenable");
}
firesale_make_box_reopenable(){
	self endon( "zhc_end_of_cooldown" );
	if(!self box_currently_affect_by_firesale())
		level waittill ("powerup fire sale"); //firesale ends expiration
	else
		wait_network_frame( );//wait for cooldown to start before ending it.
	self notify ("zhc_end_of_cooldown");
}
middle_box_logic(costs_money,user_cost,user){
	self endon( "box_finished" );

	first_time = true;
	while(1)
		//first_time || 
		//self.ZHC_GUN_CYCLE)
	{
		// take away usability until model is done randomizing
		if(first_time)
			waittill_multiple_ents( self.chest_origin,"randomization_done", self.chest_lid, "lid_opened" );
		else
			self.chest_origin waittill("randomization_done"); 

		got_teddy = self.chest_origin ZHC_teddy_is_here();

		//if(got_teddy)
		//	IPrintLnBold( "MOVE THREAD SHOULD RUN" );		works
		
		if(got_teddy){

			if(isDefined(user))
				user maps\_zombiemode_blockers::haunt_player();			// doesnt need to be threaded for now
			else
				maps\_zombiemode_blockers::haunt_all_players();	
		}

		if(is_true(costs_money) && (!self.ZHC_GUN_CYCLE || first_time)){
		// refund money from teddy.
			if (got_teddy && !self._box_opened_by_fire_sale && IsDefined(user_cost))
			{
				user maps\_zombiemode_score::add_to_player_score( user_cost, false );
			}
		}

		if (got_teddy){
			self disable_trigger();
			if(!ZHC_should_take_teddy_seriously(self,true)){	//!chest moving serves as fail safe if temp_chest var was changed while randomizing.
				IPrintLnBold( "not serious teddy" );
				self thread ZHC_firesale_teddy_delete_temp_chest();
			} 
			else //if(self.chest_origin ZHC_box_has_teddy())
			{
				IPrintLnBold( "serious teddy" );
				//var stuff
				self.ZHC_ALL_CHESTS_chest_active = false;

				if(level.ZHC_FIRESALE_TEDDY_PREMATURE_END){
					//IPrintLn( "FS NO WORKY NO MORE2" );
					self.premature_firesale_end = true;
				}

				//start thread
				self thread treasure_chest_move( self.chest_user );

				//box indicator stuff

				if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY){
					chests = level.chests;
					for(i = 0; i< chests.size; i++){
						chests[i].chest_origin.ZHC_checked_for_teddy = false;
					}
				}
				//else if(level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX){
					//self.chest_origin.ZHC_checked_for_teddy = false;
				//}
				level.ZHC_update_box_indicator = true;

				//finalizer stuff
				//self notify("box_finished");
				//self.chest_origin notify("box_finished");
				//self.chest_lid notify("close_lid");		//the move thread will close the door.
				
			}
			self waittill("box_finished");
		}else{

			self thread ZHC_weapon_specific_box_changes(self.chest_origin.weapon_string);

			self enable_trigger( );

			if (first_time)
			{
				self.grab_weapon_hint = true;
				self.chest_user = user;

				self thread chest_weapon_expire_wait();

				if(!self.ZHC_GUN_BUYABLE){
					// Let the player grab the weapon and re-enable the box //
					self sethintstring( &"ZOMBIE_TRADE_WEAPONS" );
					self setCursorHint( "HINT_NOICON" ); 

					if(!self.ZHC_GUN_CYCLE && !self.ZHC_GUN_SWAP)//&& !self.ZHC_GUN_BUYABLE					//NORMAL BOX
						self.chest_origin thread wait_to_grabbed_to_end(self);

					if(self.ZHC_GUN_SWAP)
						self thread ZHC_GUN_SWAP_hintstrings();

					if(self.ZHC_GUN_CYCLE)
						self thread ZHC_GUN_CYCLE_cycle_weapons(user);

					if(!self.ZHC_GUN_CYCLE && !self.ZHC_GUN_SWAP )
						self thread decide_hide_show_hint( "weapon_grabbed", "box_finished");					//NORMAL BOX
					else
						self thread decide_hide_show_hint("box_finished");

					if(IsDefined( user ))
					self setvisibletoplayer( user );
					// Limit its visibility to the player who bought the box

					
					// make sure the guy that spent the money gets the item
					// SRS 9/3/2008: ...or item goes back into the box if we time out
					self thread weapon_to_grab_think(user,self.ZHC_GUN_SWAP, self.ZHC_GUN_CYCLE);
				}else{
					hint_string = get_weapon_hint( self.chest_origin.weapon_string ); 
					cost = get_weapon_cost( self.chest_origin.weapon_string );

					self SetHintString( hint_string, cost ); 
					self setCursorHint( "HINT_NOICON" ); 
					//self UseTriggerRequireLookAt();				//its making it hard to interact with.
					if(level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE)
						self.chest_origin thread wait_to_grabbed_to_end(self);
					self thread weapon_spawn_think(true,undefined, true, true, level.ZHC_BOX_UPGRADE_WEAPON_ON_CLONE_PICK_UP);
					
				}
			}
		}
		first_time = false;
	}
	self waittill("box_finished");
}




this_spin_is_firesale(dont_use_up){// can oonly be used once
	ret = self box_currently_affect_by_firesale();
	if(level.ZHC_FIRESALE_APPLIES_ONLY_ONCE && !is_true(dont_use_up)){
		//IPrintLn( "FS NO WORKY NO MORE1" );
		self.premature_firesale_end = true;
	}
	return ret;
}
could_get_teddy_firesale_check(chest){
	return ( (GetDvar( #"magic_chest_movable") == "1") && !is_true( chest._box_opened_by_fire_sale ) && !chest box_currently_affect_by_firesale());
}

box_currently_affect_by_firesale(){
	return 	(
				//is_true(self._box_opened_by_fire_sale) ||//nope yea nope
				(
					is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) && 
					self [[level._zombiemode_check_firesale_loc_valid_func]]()
				)
		   	) && 
			!is_true(self.premature_firesale_end);
}
ZHC_FIRESALE_CAN_CREATE_TEMP_CHESTS(){
	return level.ZHC_FIRESALE_CAN_CREATE_TEMP_CHESTS;
}
ZHC_wait_for_firesale(){
	self endon ("box_finished");
	//self endon ("weapon_expired");
	//self.chest_origin endon ("teddy_appear");

	if(!self [[level._zombiemode_check_firesale_loc_valid_func]]())
		return;

	if(self.ZHC_GUN_STAYS){

		//ZHC_FIRESALE_GRABBED_OPEN_WHEN_CLOSED = true;
		

		level waittill("powerup fire sale");
		self.premature_firesale_end = undefined;
		if(level.ZHC_FIRESALE_GRABBED_RESPIN_BOX_OPEN && is_true(self._box_open) && !is_true(self._box_opened_by_fire_sale) && !self.chest_origin ZHC_teddy_is_here() ) {
			self.chest_origin hide_weapon_model(true, true);
			self disable_trigger();
			self.chest_origin treasure_chest_weapon_spawn(self, self.chest_user);
		}
		//else if(ZHC_FIRESALE_GRABBED_OPEN_WHEN_CLOSED && !self._box_open){
			//open box;
		//}
		//if box is open respin it.

		self thread ZHC_wait_for_firesale();
	}
}

repeat_firesale_off(){
	self endon ("box_finished");
	self endon ("weapon_expired");
	level waittill("fire_sale_off");
	self thread ZHC_wait_for_firesale_end();
}
ZHC_wait_for_firesale_end(){
	if(!level.ZHC_FIRESALE_CLOSE_AFTER_FIRESALE_OFF)
		level endon("fire_sale_off");
	self endon ("box_finished");
	self endon ("weapon_expired");
	self.chest_origin endon ("teddy_appear");	

	if(!self [[level._zombiemode_check_firesale_loc_valid_func]]())
		return;

	self thread repeat_firesale_off();

	if(!is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]))
		level waittill("powerup fire sale");

	if(self.ZHC_GUN_STAYS)
	{
		if(level.ZHC_FIRESALE_CLOSE_AFTER_FIRESALE_OFF){
			if(level.ZHC_FIRESALE_CLOSE_AFTER_USE)
			{
				self.chest_origin waittill_any_ents(level,"fire_sale_off",self.chest_origin, "weapon_grabbed");
			}
			else
			{
				level waittill( "fire_sale_off");
			}
		}else{
			if(level.ZHC_FIRESALE_CLOSE_AFTER_USE)
			{
				self.chest_origin waittill("weapon_grabbed");

			}else{
				return;
			}
		}


		//self.chest_origin delete_weapon_model();
		if(!level.ZHC_FIRESALE_DROP_WEAPON_FIRST_AT_CLOSE){
			self.chest_origin.weapon_string = undefined; //this makes the box instantlly delete and close the box.
			//self disable_trigger();					// if wep string is undefined insta close disables trigger
		}

		self notify( "weapon_expired" );
		//self notify ("box_finished");
		//self chest_lid thread wait_to_close_lid(self);
		//wait_network_frame( );
		//self.chest_lid notify("close_lid");
		//self waittill ("box_finished");
		//self.chest_user = undefined;
	}
}

ZHC_firesale_teddy_delete_temp_chest(){		//this function is nessesary because the normal weapon drop func ends on teddy_appear
	//(!is_true(self.was_temp))
	//	return;
	self endon ("box_finished");
	//level endon("fire_sale_off");

	//.chest_origin waittill( "teddy_appear");
	//self disable_trigger();
	wait(1.5);
	//("closing lid cuz teddy");
	self.chest_origin delete_weapon_model(); //delete fake teddt
	self.chest_origin.weapon_string = undefined;
	//self hide_weapon_model(true,true);
	if(level.ZHC_FIRESALE_TEDDY_PREMATURE_END)
		self tempt_chest_premature_firesale_box_hide();
	else{
		playfx(level._effect["poltergeist"], self.orig_origin);
	}

	IPrintLnBold( "line1829 FORCE_CLOSE_LID" );

	self.chest_lid notify( "close_lid" );
	//failsafe
	self waittill("lid_closed");
	wait_network_frame();

	self.chest_origin notify( "box_finished" );
	self notify("box_finished");
	//self notify( "weapon_expired" );
	
	
}
tempt_chest_premature_firesale_box_hide(){
	//IPrintLn( "FS NO WORKY NO MORE3" );
	self.premature_firesale_end = true;
	self.was_temp = undefined;		// moved by mod
	playfx(level._effect["poltergeist"], self.orig_origin);
	self playsound ( "zmb_box_poof_land" );
	self playsound( "zmb_couch_slam" );
	self hide_chest();
	self show_rubble();
}

ZHC_chest_is_active(chest_index){
	if(level.ZHC_ALL_CHESTS)
		return level.chests[chest_index].ZHC_ALL_CHESTS_chest_active;
	else
		return (level.chest_index == chest_index);
}

ZHC_GUN_SWAP_hintstrings(){
	self endon ("box_finished");
	while(1){
	self.chest_origin waittill( "weapon_grabbed" );
	if(isDefined(self.chest_origin.weapon_string))
		self sethintstring( &"ZOMBIE_TRADE_WEAPONS" ); 
	else
		self setHintString( &"ZOMBIE_WEAPON_BOX_STORE" );
	}
}

wait_to_grabbed_to_end(chest){
	chest endon ("box_finished");
	//chest endon ("weapon_expired");

	self waittill( "weapon_grabbed" );
	if(!chest.timedOut){
		self delete_weapon_model();
		self.weapon_string = undefined;
	}
	//chest.chest_lid notify( "close_lid");
	chest notify ("weapon_expired");
}

weapon_to_grab_think( user, swap, cycle){
	self.chest_origin endon ("teddy_appear");
	self endon( "box_finished" );
	firstTimeActivated = true;
	while( 1 ) {
		while( 1 )
		{
			self waittill( "trigger", grabber );
			self.weapon_out = undefined;
			if( IsDefined( grabber.is_drinking ) && grabber is_drinking() )
			{
				wait( 0.1 );
				continue;
			}

			if (IsDefined( user ) && grabber == user && user GetCurrentWeapon() == "none" )
			{
				wait( 0.1 );
				continue;
			}

			if(grabber != level && ((IsDefined(self.box_rerespun) && self.box_rerespun) || !IsDefined( user ) ))
			{
				user = grabber;
			}
			
			if( grabber == user || grabber == level )			
			{
				self.box_rerespun = undefined;
				current_weapon = "none";
				
				if(is_player_valid(user))
				{
					current_weapon = user GetCurrentWeapon();
				}
				
				if( grabber == user && is_player_valid( user ) && !user is_drinking() && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && "syrette_sp" != current_weapon )
				{
					bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type magic_accept",
						user.playername, user.score, level.team_pool[ user.team_num ].score, level.round_number, self.zombie_cost, self.chest_origin.weapon_string, self.origin );
					self notify( "user_grabbed_weapon" );
					user thread treasure_chest_give_weapon( self.chest_origin.weapon_string ,self, swap);
					break; 
				}
				else if( grabber == level )
				{
					// it timed out
					unacquire_weapon_toggle( self.chest_origin.weapon_string );
					self.timedOut = true;
					if(is_player_valid(user))
					{
						bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type magic_reject",
							user.playername, user.score, level.team_pool[ user.team_num ].score, level.round_number, self.zombie_cost, self.chest_origin.weapon_string, self.origin );
					}
					break;
				}
			}
			wait 0.05; 
		}
		if(firstTimeActivated || cycle)
			chest_weapon_grabbed(true, self.chest_origin.weapon_string);
		else
			chest_weapon_grabbed(false, self.chest_origin.weapon_string);
		firstTimeActivated = false;
		if(!swap && !cycle)
			break;
	}
}

ZHC_GUN_CYCLE_cycle_weapons(player){
	self.chest_origin endon ("teddy_appear");
	self endon("box_finished");
	while(1){
		self.chest_origin waittill( "weapon_grabbed" );

		if(level.ZHC_FIRESALE_CLOSE_AFTER_USE && self box_currently_affect_by_firesale())
			//self waittill ("box_finished");
			return;

//		if(self.origin ZHC_teddy_is_here())			//teddy_appear endon should do the job
//			return;
		self.chest_origin hide_weapon_model(true, true);
		self disable_trigger();
		//wait_network_frame( ); //wait for "weapon_grabbed" to delete models
		self.chest_origin thread treasure_chest_weapon_spawn(self, player); 	//must be threaded in order for it to not be interupted by endon
	}
}

chest_weapon_grabbed(affect_counters, weapon_name){
	self.chest_origin notify( "weapon_grabbed" , weapon_name);

	if(affect_counters){
		if ( !is_true( self._box_opened_by_fire_sale ) )
		{
			//increase counter of amount of time weapon grabbed, but not during a fire sale
			level.chest_accessed += 1;
		}
			
		// PI_CHANGE_BEGIN
		// JMA - we only update counters when it's available
		if( level.chest_moves > 0 && isDefined(level.pulls_since_last_ray_gun) )
		{
			level.pulls_since_last_ray_gun += 1;
		}
		
		if( isDefined(level.pulls_since_last_tesla_gun) )
		{				
			level.pulls_since_last_tesla_gun += 1;
		}
	}
}

chest_weapon_expire_wait(strength){
	self endon("box_finished" );
	self endon("box_hacked_respin");
	self endon("weapon_expired");
	self endon("end_weapon_expire_timer");
	//kill_goal = 15 + (level.round_number * 5) + level.total_zombies_killed;
	//kill_goal = 5 + (level.round_number * 5) + level.total_zombies_killed;
	//while(kill_goal > level.total_zombies_killed){
	//	level waittill("zom_kill");
	//}
	if(!IsDefined( strength ))
		strength = 1;

	if(!self.ZHC_GUN_STAYS)
		self thread treasure_chest_timeout();
	//TODO MIGHT NEED TO ADD TIMEOUT OF SORTS TO WEAPON EXPIRE SYSTEM

	if(self.ZHC_GUN_STAYS){	//stays forever for now
		//rounds_to_wait= 1;
		//for(i = 0; i < rounds_to_wait; i++){
		//	level waittill("end_of_round");
		//}
		if(level.ZHC_BOX_GUN_STAYS_WAIT){
			if(self.ZHC_GUN_BUYABLE && level.ZHC_BOX_GUN_STAYS_WAIT_GUN_BUYABLE_RESET_EXPIRE_TIMER)
				self thread weapon_buy_reset_expire_timer();

			wait(5);
			kills = 5 + int(   
								max(
									 	//(get_weapon_cost(self.chest_origin.weapon_string)/100)  ,				//this makes more expensive weapons stay longer, but is this a good thing?
									 	20,
									 	(  (min(get_or(level.zombie_total_start, 6), 64 )/2) * (strength-1) )
								    )
							);
			if(level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE && level.ZHC_BOX_WAIT_TO_BECOME_REOPENABLE_WAIT_TO_EXPIRE_CLOSE){//here we thread it so we can reuse it later
				self.zhc_cooldown_waiting = true;
				self thread maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, kills, undefined, undefined, false);
				self waittill( "zhc_end_of_cooldown" );
				self.zhc_cooldown_waiting = undefined;
			}else
				self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, kills, undefined, undefined, false);
			//self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, undefined, 1, undefined); //waits for 16 kills and for next round
		}else
			return;
	}else{
		if(self.ZHC_GUN_SWAP && level.ZHC_GUN_SWAP_TIMER_RESET){
			self thread weapon_swap_reset_expire_timer();
		}
		wait(5);
	}
	self notify("weapon_expired");
}
get_or(def, if_undefined){
	if(isDefined (def))
		return def;
	return if_undefined;
}

weapon_swap_reset_expire_timer(){
	self endon( "box_finished" );
	self endon("box_hacked_respin");
	self endon("weapon_expired");

	self.chest_origin waittill ("weapon_grabbed");
	self notify( "end_weapon_expire_timer" );
	self thread chest_weapon_expire_wait();
}
weapon_buy_reset_expire_timer(){
	self endon( "box_finished" );
	self endon("box_hacked_respin");
	self endon("weapon_expired");
	self waittill( "reset_expire_timer", strength );
	self notify( "end_weapon_expire_timer" );
	self notify("zhc_end_of_cooldown");
	self thread chest_weapon_expire_wait(strength);
}

//-------------------------------------------------------------------------------
//	Disable trigger if can't buy weapon and also if someone else is using the chest
//	DCS: Disable magic box hint if claymores out.
//-------------------------------------------------------------------------------
decide_hide_show_chest_hint( endon_notify )
{
	if( isDefined( endon_notify ) )
	{
		self endon( endon_notify );
	}

	while( true )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			// chest_user defined if someone bought a weapon spin, false when chest closed
			if ( (IsDefined(self.chest_user) && players[i] != self.chest_user ) ||
				 !players[i] can_buy_weapon() )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], false );
			}
		}
		wait( 0.1 );
	}
}

weapon_show_hint_choke()
{
	level._weapon_show_hint_choke = 0;
	
	while(1)
	{
		wait(0.05);
		level._weapon_show_hint_choke = 0;
	}
}

decide_hide_show_hint( endon_notify, endon_notify_2 , endon_notify_3)
{
	if( isDefined( endon_notify ) )
	{
		self endon( endon_notify );
	}
	if( isDefined( endon_notify_2 ) )
	{
		self endon( endon_notify_2 );
	}
	if( IsDefined( endon_notify_3 )){
		self endon( endon_notify_3 );
	}

	if(!IsDefined(level._weapon_show_hint_choke))
	{
		level thread weapon_show_hint_choke();
	}

	use_choke = false;
	
	if(IsDefined(level._use_choke_weapon_hints) && level._use_choke_weapon_hints == 1)
	{
		use_choke = true;
	}


	while( true )
	{

		last_update = GetTime();

		if(IsDefined(self.chest_user) && !IsDefined(self.box_rerespun))
		{
			if( is_placeable_mine( self.chest_user GetCurrentWeapon() ) || self.chest_user hacker_active())
			{
				self SetInvisibleToPlayer( self.chest_user);
			}
			else
			{
				self SetVisibleToPlayer( self.chest_user );
			}
		}
		else // all players
		{	
			players = get_players();
			for( i = 0; i < players.size; i++ )
			{
				if( players[i] can_buy_weapon())
				{
					self SetInvisibleToPlayer( players[i], false );
				}
				else
				{
					self SetInvisibleToPlayer( players[i], true );
				}
			}
		}	
		
		if(use_choke)
		{
			while((level._weapon_show_hint_choke > 4) && (GetTime() < (last_update + 150)))
			{
				wait 0.05;
			}
		}
		else
		{
			wait(0.1);
		}		
		
		level._weapon_show_hint_choke ++;
	}
}

can_buy_weapon()
{
	if( IsDefined( self.is_drinking ) && self is_drinking() )
	{
		return false;
	}

	if(self hacker_active())
	{
		return false;
	}

	current_weapon = self GetCurrentWeapon();
	if( is_placeable_mine( current_weapon ) || is_equipment( current_weapon ) )
	{
		return false;
	}
	if( self in_revive_trigger() )
	{
		return false;
	}
	
	if( current_weapon == "none" )
	{
		return false;
	}

	return true;
}

default_box_move_logic()
{
	// Check to see if there's a chest selection we should use for this move
	// This is indicated by a script_noteworthy of "moveX*"
	//	(e.g. move1_chest0, move1_chest1)  We will randomly choose between 
	//		one of those two chests for that move number only.
	index = -1;
	for ( i=0; i<level.chests.size; i++ )
	{
		// Check to see if there is something that we have a choice to move to for this move number
		if ( IsSubStr( level.chests[i].script_noteworthy, ("move"+(level.chest_moves+1)) ) &&
			 i != level.chest_index )
		{
			index = i;
			break;
		}
	}

	if ( index != -1 )
	{
		level.chest_index = index;
	}
	else
	{
		level.chest_index++;
	}

	if (level.chest_index >= level.chests.size)
	{
		//PI CHANGE - this way the chests won't move in the same order the second time around
		temp_chest_name = level.chests[level.chest_index - 1].script_noteworthy;
		level.chest_index = 0;
		level.chests = array_randomize(level.chests);
		//in case it happens to randomize in such a way that the chest_index now points to the same location
		// JMA - want to avoid an infinite loop, so we use an if statement
		if (temp_chest_name == level.chests[level.chest_index].script_noteworthy)
		{
			level.chest_index++;
		}
		//END PI CHANGE
	}
}

//
//	Chest movement sequence, including lifting the box up and disappearing
//
treasure_chest_move( player_vox )
{
	level waittill("weapon_fly_away_start");

	players = get_players();
	
	array_thread(players, ::play_crazi_sound);

	level waittill("weapon_fly_away_end");

	//self.chest_lid thread treasure_chest_lid_close();
	self.chest_lid notify("close_lid");				//wont finish box due to a check

	self setvisibletoall();

	self hide_chest();

	fake_pieces = [];
	fake_pieces[0] = spawn("script_model",self.chest_lid.origin);
	fake_pieces[0].angles = self.chest_lid.angles;
	fake_pieces[0] setmodel(self.chest_lid.model);

	fake_pieces[1] = spawn("script_model",self.chest_box.origin);
	fake_pieces[1].angles = self.chest_box.angles;
	fake_pieces[1] setmodel(self.chest_box.model);


	anchor = spawn("script_origin",fake_pieces[0].origin);
	soundpoint = spawn("script_origin", self.chest_origin.origin);

	anchor playsound("zmb_box_move");
	for(i=0;i<fake_pieces.size;i++)
	{
		fake_pieces[i] linkto(anchor);
	}

	playsoundatposition ("zmb_whoosh", soundpoint.origin );
	if( is_true( level.player_4_vox_override ) )
	{
		playsoundatposition ("zmb_vox_rich_magicbox", soundpoint.origin );
	}
	else
	{
		playsoundatposition ("zmb_vox_ann_magicbox", soundpoint.origin );
	}


	anchor moveto(anchor.origin + (0,0,50),5);

	//anchor rotateyaw(360 * 10,5,5);
	if( isDefined( level.custom_vibrate_func ) )
	{
		[[ level.custom_vibrate_func ]]( anchor );
	}
	else
	{
	   //Get the normal of the box using the positional data of the box and self.chest_lid
	   direction = self.chest_box.origin - self.chest_lid.origin;
	   direction = (direction[1], direction[0], 0);
	   
	   if(direction[1] < 0 || (direction[0] > 0 && direction[1] > 0))
	   {
            direction = (direction[0], direction[1] * -1, 0);
       }
       else if(direction[0] < 0)
       {
            direction = (direction[0] * -1, direction[1], 0);
       }
	   
        anchor Vibrate( direction, 10, 0.5, 5);
	}
	
	//anchor thread rotateroll_box();
	anchor waittill("movedone");

	

	//players = get_players();
	//array_thread(players, ::play_crazi_sound);
	//wait(3.9);
	
	playfx(level._effect["poltergeist"], self.chest_origin.origin);
	
	//TUEY - Play the 'disappear' sound
	playsoundatposition ("zmb_box_poof", soundpoint.origin);
	for(i=0;i<fake_pieces.size;i++)
	{
		fake_pieces[i] delete();
	}

	// 
	self show_rubble();
	wait(0.1);
	anchor delete();
	soundpoint delete();
	
	post_selection_wait_duration = 7;
	
	//Delaying the Player Vox
	if( IsDefined( player_vox ) )
    {    
        player_vox maps\_zombiemode_audio::create_and_play_dialog( "general", "box_move" );
    }






	// DCS 072710: check if fire sale went into effect during move, reset with time left.
	if(self box_currently_affect_by_firesale())
	{
		current_sale_time = level.zombie_vars["zombie_powerup_fire_sale_time"];
		//("need to reset this box spot! Time left is ", current_sale_time);

		wait_network_frame();				
		self thread fire_sale_fix();
		level.zombie_vars["zombie_powerup_fire_sale_time"] = current_sale_time;


		self notify( "box_finished" );
    	self.chest_origin notify( "box_finished" );

		while(level.zombie_vars["zombie_powerup_fire_sale_time"] > 0)
		{
			wait(0.1);
		}	
	}	
	else
	{
		post_selection_wait_duration += 5;
		self notify( "box_finished" );
    	self.chest_origin notify( "box_finished" );
	}
	level.verify_chest = false;


	if(!level.ZHC_ALL_CHESTS)
	{
		if(IsDefined(level._zombiemode_custom_box_move_logic))
		{
			[[level._zombiemode_custom_box_move_logic]]();
		}
		else
		{
			default_box_move_logic();
		}

		if(IsDefined(level.chests[level.chest_index].box_hacks["summon_box"]))
		{
			level.chests[level.chest_index] [[level.chests[level.chest_index].box_hacks["summon_box"]]](false);
		}

		// Now choose a new location

		//wait for all the chests to reset 
		wait(post_selection_wait_duration);

		playfx(level._effect["poltergeist"], level.chests[level.chest_index].chest_origin.origin);
		level.chests[level.chest_index] show_chest();
		level.chests[level.chest_index] hide_rubble();
		
		flag_clear("moving_chest_now");
		self.chest_origin.chest_moving = false;
		
	} else
	{
		if(level.ZHC_ALL_CHESTS && IsDefined( level.ZHC_ALL_CHESTS_last_box_to_move_index ) && level.ZHC_ALL_CHESTS_last_box_to_move_index == get_chest_index(self))
			flag_clear("moving_chest_now");

		self.chest_origin.chest_moving = false;
		
		ZHC_remove_teddy(self.chest_origin);
		if(!level.ZHC_ORDERED_BOX_RANDOM_TEDDY_EVERY_BOX) //condition to avoid adding more teddies to every box 
			ZHC_add_teddy();


		self ZHC_ALL_CHESTS_box_return();
	}
	
}


ZHC_ALL_CHESTS_box_return(special_box){
	ZHC_ALL_CHESTS_box_return_wait(special_box);

	//self notify( "box_has_returned" );

	if(IsDefined(self.box_hacks["summon_box"]))
	{
		self [[self.box_hacks["summon_box"]]](false);
	}

	playfx(level._effect["poltergeist"], self.chest_origin.origin);

	self show_chest();
	self hide_rubble();

	if(level.ZHC_ORDERED_BOX_ONE_ORDER){
		//next box unlocks.
	}else
	if(level.ZHC_ORDERED_BOX)
		self.chest_origin.ZHC_chest_owned_weapon_index = -1;
	//flag_clear("moving_chest_now");
	self.ZHC_ALL_CHESTS_chest_active = true;
	level.ZHC_update_box_indicator = true;
		
}



ZHC_ALL_CHESTS_box_return_wait(special_box){

	level notify ("a_box_is_gone");
	wait_network_frame( );

	if(!IsDefined( level.special_chest_wait_mode))
		level.special_chest_wait_mode = 1;
	if(!isDefined(level.max_special_chest_waiters))
		level.max_special_chest_waiters = 1;
	if(!isDefined(level.special_chest_waiters))
		level.special_chest_waiters = 0;

	if(is_true(special_box ) && level.max_special_chest_waiters > level.special_chest_waiters){
		level.special_chest_waiters++;

		i = undefined;

		special_turn = level.max_special_chest_waiters -level.special_chest_waiters;

		if(level.special_chest_wait_mode == 1)
			i = special_turn;
		else if(level.special_chest_wait_mode == 0)
			i = level.special_chest_waiters;
		else if(level.special_chest_wait_mode == 2)
			i = int((level.special_chest_waiters + special_turn)/2);

		while(get_boxes_active_count()-i != 0){
			level waittill_either("a_box_is_gone", "end_of_round");

			if(level.special_chest_wait_mode == 0)
				i = level.special_chest_waiters;
		}

		level.special_chest_waiters--;
		level.max_special_chest_waiters ++;
		if(level.max_special_chest_waiters > level.chests.size)
			level.max_special_chest_waiters = 0;
	}else if(get_boxes_active_count() == 0 
		//&& (!IsDefined( level.special_chest_waiters ) || level.special_chest_waiters <= 0) 
		){
		level notify("bring_back_all_boxes");

		//level.special_chest_wait_mode ++;
		if(level.special_chest_wait_mode > 2)
			level.special_chest_wait_mode = 0;

		ZHC_ALL_CHESTS_box_return_wait(true);
	}else{
		level waittill("bring_back_all_boxes");
	}
}

get_boxes_active_count(chest){
	count = 0;
	chests = level.chests;
	chests_num = chests.size;
	for(i = 0; i< chests_num; i++){
		if(chests[i].ZHC_ALL_CHESTS_chest_active)
			count++;
	}
	return count;
}

get_chest_index(chest){
	chests = level.chests;
	for(i = 0; i< chests.size; i++){
		if(chests[i] == chest)
			return i;
	}
	return undefined;
}



fire_sale_fix()
{
	if( !isdefined ( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
	{
		return;
	}

	if( level.zombie_vars["zombie_powerup_fire_sale_on"] )
	{
		self.old_cost = GetNormalChestCost(self);
		self thread show_chest();
		self thread hide_rubble();
		self.zombie_cost = 10;
		self set_hint_string( self , "powerup_fire_sale_cost" );

		wait_network_frame();

		level waittill( "fire_sale_off" );
		
		while(is_true(self._box_open ))
		{
			wait(.1);
		}


		
		playfx(level._effect["poltergeist"], self.origin);
		self playsound ( "zmb_box_poof_land" );
		self playsound( "zmb_couch_slam" );

		if(is_false(self.ZHC_ALL_CHESTS_chest_active)){ //condition added for mod
			self thread hide_chest();
			self thread show_rubble();
		}
	
		self.zombie_cost = self.old_cost;
		self set_hint_string( self , "default_treasure_chest_" + self.zombie_cost );
	}
}

check_for_desirable_chest_location()
{
	if( !isdefined( level.desirable_chest_location ) )
		return level.chest_index;

	if( level.chests[level.chest_index].script_noteworthy == level.desirable_chest_location )
	{
		level.desirable_chest_location = undefined;
		return level.chest_index;
	}
	for(i = 0 ; i < level.chests.size; i++ )
	{
		if( level.chests[i].script_noteworthy == level.desirable_chest_location )
		{
			level.desirable_chest_location = undefined;
			return i;
		}
	}

	/#
		iprintln(level.desirable_chest_location + " is an invalid box location!");
#/
	level.desirable_chest_location = undefined;
	return level.chest_index;
}


rotateroll_box()
{
	angles = 40;
	angles2 = 0;
	//self endon("movedone");
	while(isdefined(self))
	{
		self RotateRoll(angles + angles2, 0.5);
		wait(0.7);
		angles2 = 40;
		self RotateRoll(angles * -2, 0.5);
		wait(0.7);
	}
	


}
//verify if that magic box is open to players or not.
verify_chest_is_open()
{

	//for(i = 0; i < 5; i++)
	//PI CHANGE - altered so that there can be more than 5 valid chest locations
	for (i = 0; i < level.open_chest_location.size; i++)
	{
		if(isdefined(level.open_chest_location[i]))
		{
			if(level.open_chest_location[i] == level.chests[level.chest_index].script_noteworthy)
			{
				level.verify_chest = true;
				return;		
			}
		}

	}

	level.verify_chest = false;


}


treasure_chest_timeout()
{
	self endon( "box_finished" );
	self endon("box_hacked_respin");
	self endon("weapon_expired");
	self endon("end_weapon_expire_timer");
	self endon( "user_grabbed_weapon" );

	self.chest_origin endon( "box_hacked_respin" );
	self.chest_origin endon( "box_hacked_rerespin" );

	wait( 12 );
	self notify( "trigger", level ); 
}

treasure_chest_lid_open(chest)
{
	openRoll = 105;
	openTime = 0.5;
	self RotateRoll( 105, openTime, ( openTime * 0.5 ) );

	play_sound_at_pos( "open_chest", self.origin );
	play_sound_at_pos( "music_chest", self.origin );

	wait(opentime);
	chest._box_open = true;

	self notify("lid_opened");
}



wait_to_close_lid(chest)
{
	//chest endon("box_finished");
	self waittill( "close_lid" );
	chest disable_trigger();
	if(!chest._box_open)
		self waittill( "lid_opened" );

	self thread treasure_chest_lid_close(chest);

	self waittill("lid_closed");

	//wait_network_frame();//wait for other lid closed related funcs to trigger.
	if(is_true(chest.chest_origin.chest_moving))
		return;
	chest notify ("box_finished");
	chest.chest_origin notify ("box_finished");
}

treasure_chest_lid_close(chest){
	closeRoll = -105;
	closeTime = 0.5;

	self RotateRoll( closeRoll, closeTime, ( closeTime * 0.5 ) );
	play_sound_at_pos( "close_chest", self.origin );
	wait(closeTime);
	wait_network_frame();
	chest._box_open = false;
	self notify("lid_closed");
}

treasure_chest_ChooseRandomWeapon( player )
{
	// this function is for display purposes only, so there's no need to bother limiting which weapons can be displayed
	// while they float, only the last selection needs to be limited, which is decided by treasure_chest_ChooseWeightedRandomWeapon()
	// plus, this is all clientsided at this point anyway
	keys = GetArrayKeys( level.zombie_weapons );
	return keys[RandomInt( keys.size )];

}

treasure_chest_ChooseWeightedRandomWeapon( player )
{
	keys = GetArrayKeys( level.zombie_weapons );

	toggle_weapons_in_use = 0;
	// Filter out any weapons the player already has
	filtered = [];
	for( i = 0; i < keys.size; i++ )
	{
		if( !get_is_in_box( keys[i] ) )
		{
			continue;
		}
		
		if( isdefined( player ) && is_player_valid(player) && player has_weapon_or_upgrade( keys[i] ) )
		{
			if ( is_weapon_toggle( keys[i] ) )
			{
				toggle_weapons_in_use++;
			}
			continue;
		}

		if( !IsDefined( keys[i] ) )
		{
			continue;
		}

		num_entries = [[ level.weapon_weighting_funcs[keys[i]] ]]();
		
		for( j = 0; j < num_entries; j++ )
		{
			filtered[filtered.size] = keys[i];
		}
	}
	
	// Filter out the limited weapons
	if( IsDefined( level.limited_weapons ) )
	{
		keys2 = GetArrayKeys( level.limited_weapons );
		players = get_players();
		pap_triggers = GetEntArray("zombie_vending_upgrade", "targetname");
		for( q = 0; q < keys2.size; q++ )
		{
			count = 0;
			for( i = 0; i < players.size; i++ )
			{
				if( players[i] has_weapon_or_upgrade( keys2[q] ) )
				{
					count++;
				}
			}

			// Check the pack a punch machines to see if they are holding what we're looking for
			for ( k=0; k<pap_triggers.size; k++ )
			{
				if ( IsDefined(pap_triggers[k].current_weapon) && pap_triggers[k].current_weapon == keys2[q] )
				{
					count++;
				}
			}

			// Check the other boxes so we don't offer something currently being offered during a fire sale
			for ( chestIndex = 0; chestIndex < level.chests.size; chestIndex++ )
			{
				if ( IsDefined( level.chests[chestIndex].chest_origin.weapon_string ) && level.chests[chestIndex].chest_origin.weapon_string == keys2[q] )
				{
					count++;
				}
			}
			
			if ( isdefined( level.random_weapon_powerups ) )
			{
				for ( powerupIndex = 0; powerupIndex < level.random_weapon_powerups.size; powerupIndex++ )
				{
					if ( IsDefined( level.random_weapon_powerups[powerupIndex] ) && level.random_weapon_powerups[powerupIndex].base_weapon == keys2[q] )
					{
						count++;
					}
				}
			}

			if ( is_weapon_toggle( keys2[q] ) )
			{
				toggle_weapons_in_use += count;
			}

			if( count >= level.limited_weapons[keys2[q]] )
			{
				filtered = array_remove( filtered, keys2[q] );
			}
		}
	}
	
	// finally, filter based on toggle mechanic
	if ( IsDefined( level.zombie_weapon_toggles ) )
	{
		keys2 = GetArrayKeys( level.zombie_weapon_toggles );
		for( q = 0; q < keys2.size; q++ )
		{
			if ( level.zombie_weapon_toggles[keys2[q]].active )
			{
				if ( toggle_weapons_in_use < level.zombie_weapon_toggle_max_active_count )
				{
					continue;
				}
			}

			filtered = array_remove( filtered, keys2[q] );
		}
	}




	// try to "force" a little more "real randomness" by randomizing the array before randomly picking a slot in it
	filtered = array_randomize( filtered );

	return filtered[RandomInt( filtered.size )];
}

// Functions namesake in _zombiemode_weapons.csc must match this one.

weapon_is_dual_wield(name)
{
	if(!IsDefined( name ))
		return false;
	switch(name)
	{
		case  "cz75dw_zm":
		case  "cz75dw_upgraded_zm":
		case  "m1911_upgraded_zm":
		case  "hs10_upgraded_zm":
		case  "pm63_upgraded_zm":
		case  "microwavegundw_zm":
		case  "microwavegundw_upgraded_zm":
			return true;
		default:
			return false;
	}
}

get_left_hand_weapon_model_name( name )
{
	switch ( name )
	{
		case  "microwavegundw_zm":
			return GetWeaponModel( "microwavegunlh_zm" );
		case  "microwavegundw_upgraded_zm":
			return GetWeaponModel( "microwavegunlh_upgraded_zm" );
		default:
			return GetWeaponModel( name );
	}
}

clean_up_hacked_box()
{
	self waittill("box_hacked_respin");
	self endon("box_spin_done");
	
	self delete_weapon_model();
}


set_box_weapon_model_to(weapon_name){
	modelname = GetWeaponModel( weapon_name );

	self.weapon_model show();
	self.weapon_model setmodel( modelname ); 
	self.weapon_model useweaponhidetags( weapon_name );

	if ( weapon_is_dual_wield(weapon_name))
	{
		floatHeight = 30;
		if(!isDefined(self.weapon_model_dw)){
			//were tryin our best not to use this
			self.weapon_model_dw = spawn( "script_model", self.weapon_model.origin - ( 3, 3, 3 ) ); // extra model for dualwield weapons
			self.weapon_model_dw.angles = self.angles +( 0, 90, 0 );
			self.weapon_model_dw LinkTo(self.weapon_model);
		}else{
			self.weapon_model_dw show();
			//self.weapon_model_dw.origin =(self.weapon_model.origin - ( 3, 3, 3 ));
			//self.weapon_model_dw LinkTo(self.weapon_model);
		}
		//self.weapon_model_dw moveto( self.origin +( 0, 0, floatHeight )- ( 3, 3, 3 ) , 3, 2, 0.9 ); 

		self.weapon_model_dw setmodel( get_left_hand_weapon_model_name( weapon_name ) ); 
		self.weapon_model_dw useweaponhidetags( weapon_name );
	} 
}



delete_weapon_model(){
	if(IsDefined(self.weapon_model))
	{
		self.weapon_model Delete();
		self.weapon_model = undefined;
	}
	
	if(IsDefined(self.weapon_model_dw))
	{
		self.weapon_model_dw Delete();
		self.weapon_model_dw = undefined;
	}
}
hide_weapon_model(base, dw){

	if(base && IsDefined(self.weapon_model))
	{
		self.weapon_model hide();
	}
	
	if(dw && IsDefined(self.weapon_model_dw))
	{
		self.weapon_model_dw hide();
	}
}
swap_box_weapon_model_to(weapon_name){

	self hide_weapon_model(true, true);

	if(isDefined(weapon_name)){
		//floatHeight = 30;
		//self.weapon_model = spawn( "script_model",self.origin +( 0, 0, floatHeight ), 3, 2, 0.9 ); 
		//self.weapon_model.angles = self.angles +( 0, 90, 0 );

		self set_box_weapon_model_to(weapon_name);
	}
}

ZHC_ORDERED_BOX_get_next_weapon(init_open){

	if(level.ZHC_ORDERED_BOX_ONE_ORDER){
		level.ZHC_chest_owned_weapon_index++;
		if(level.ZHC_chest_owned_weapon_index >= level.ZHC_chest_owned_weapons.size){
			level.ZHC_chest_owned_weapon_index = 0;
		}
		return level.ZHC_chest_owned_weapons[level.ZHC_chest_owned_weapon_index];
	}else{
		self.ZHC_chest_owned_weapon_index++;
		rand = undefined;
		if(self.ZHC_chest_owned_weapon_index >= self.ZHC_chest_owned_weapons.size){
			if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY){
				self.ZHC_checked_for_teddy = true;
				level.ZHC_update_box_indicator = true;
			}
			if(level.ZHC_ORDERED_BOX_CYCLE_UNLOCK){
				self.ZHC_ORDERED_BOX_CYCLE_UNLOCK_cycle_unlocked = true;
			}

			if(self.ZHC_chest_owned_weapons.size == 0){
				//( "BOX IS EMPTY" );
				self.ZHC_chest_owned_weapon_index = -1;
				return undefined;
			}
			if(level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX){
				self.ZHC_chest_owned_weapon_index = -1;
				return "teddy";
			}
			self.ZHC_chest_owned_weapon_index = 0;
			//TEDDY = TRUE
		}
		
		rand = self.ZHC_chest_owned_weapons[self.ZHC_chest_owned_weapon_index];
		return rand;
	}
}

ZHC_ORDERED_BOX_ZHC_ALL_CHESTS_get_next_weapon_any_box(chest, init_open){

	chests = [];
	chests_num = level.chests.size;
	for(i = 0; i < chests_num; i++)
		chests[i] = level.chests[i];

	if(level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL){
		chests = array_remove_index( level.chests,level.chest_index ); //isnt needed acually will just remove off chests instead.
		chests_num--;
	}

	chests = array_remove( chests,chest);
	chests_num--;

	chests = array_randomize( chests );

	tries_left_for_no_teddy = 3;

	for(i = 0; tries_left_for_no_teddy > 0 ; i++){
		tries_left_for_no_teddy --;
		if(i >= chests_num)
			i = 0;
		other = chests[i].chest_origin;
		rand = other ZHC_ORDERED_BOX_get_next_weapon(init_open);

		if(!IsDefined( rand ))	//box is empty
			continue;

		if(level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX && rand == "teddy")
			continue;

		if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY && rand == "teddy"){
			continue;
			//other.ZHC_chest_owned_weapons = array_remove_index(other.ZHC_chest_owned_weapons,other.ZHC_chest_owned_weapon_index);	//takes teddy
			//other.ZHC_chest_owned_weapon_index --;
			//other.ZHC_has_teddy = false;
			//self.ZHC_chest_owned_weapons = array_insert( self.ZHC_chest_owned_weapons,rand,self.ZHC_chest_owned_weapons.size );
			//continue;
		}


		other.ZHC_chest_owned_weapons = array_remove_index(other.ZHC_chest_owned_weapons,other.ZHC_chest_owned_weapon_index);
		other.ZHC_chest_owned_weapon_index --;
		self.ZHC_chest_owned_weapon_index++;
		self.ZHC_chest_owned_weapons = array_insert( self.ZHC_chest_owned_weapons,rand,self.ZHC_chest_owned_weapon_index );
		return rand;
		//for(i = 0; i < chests.size; i++){
		//	if(chests[i].ZHC_ALL_CHESTS_chest_active)
		//}
	}
	return "teddy";

}

box_weapon_model_spawn_setup(){
		// spawn the model
		self delete_weapon_model();			//add later
		//self.weapon_model_dw = undefined;
		self.weapon_model = spawn( "script_model", self.origin); 
		self.weapon_model.angles = self.angles +( 0, 90, 0 );
		self.weapon_model_dw = spawn( "script_model", self.origin - (3 ,3 ,3)); 
		self.weapon_model_dw.angles = self.angles +( 0, 90, 0 );
}
box_weapon_model_rise_start(floatHeight){
	self.weapon_model moveto( self.weapon_model.origin +( 0, 0, floatHeight ), 3, 2, 0.9 ); 
	self.weapon_model_dw moveto( self.weapon_model_dw.origin +( 0, 0, floatHeight ), 3, 2, 0.9 ); 
}

treasure_chest_weapon_init_spawn( chest, player, respin)
{

	if(chest.ZHC_GUN_CYCLE && level.ZHC_ORDERED_BOX && (!chest this_spin_is_firesale(true) && level.ZHC_FIRESALE_CLOSE_AFTER_USE)) {		//when bx is reopned goes back to first weapon. works nicer for teddy mechanic, maybe not.
		self.ZHC_chest_owned_weapon_index = -1;
	}

	//self endon("box_hacked_respin");
	//self thread clean_up_hacked_box();
	assert(IsDefined(player));

		self box_weapon_model_spawn_setup();

		floatHeight = 30;

		self box_weapon_model_rise_start(floatHeight);
		
		self.weapon_string = undefined;
		

	self treasure_chest_weapon_spawn( chest, player, respin, true);

	self thread timer_til_despawn(chest, floatHeight);

	//self waittill_either( "box_moving" , "box_finished" );

	//	self.weapon_string = undefined;
	//	self notify("box_spin_done");
}


treasure_chest_weapon_spawn( chest, player, respin, init_open){
	//floatHeight = 30;
	rand = undefined; 

	chest.chest_box setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	

	//	ZHC
	guarenteed_teddy = false;

		

	
	firesale = chest this_spin_is_firesale();

	mariocycle = (!level.ZHC_ORDERED_BOX ||  (firesale && (level.ZHC_ORDERED_BOX_FIRESALE_OGISH || level.ZHC_ORDERED_BOX_FIRESALE_REASSIGN )));
	//	ZHC^

	serious_teddy = true;


	if(mariocycle)
	{
		number_cycles = 40;
		for( i = 0; i < number_cycles; i++ )
		{
			if( i < 20 )
			{
				wait( 0.05 ); 
			}
			else if( i < 30 )
			{
				wait( 0.1 ); 
			}
			else if( i < 35 )
			{
				wait( 0.2 ); 
			}
			else if( i < 38 )
			{
				wait( 0.3 ); 
			}

			if( i + 1 < number_cycles )
			{
				rand = treasure_chest_ChooseRandomWeapon( player );
			}
			else
			{
				break;
			}
		}
	}
	chest.chest_box clearclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	//s = "";
	if(level.ZHC_ORDERED_BOX) {				//ZHC
		//s += firesale + " " + is_true(chest.was_temp)  +" " + (level.chests[level.chest_index] == chest) ;
		if(firesale){
			if(level.ZHC_ORDERED_BOX_FIRESALE_OGISH)
				rand = self ZHC_ORDERED_BOX_ZHC_ALL_CHESTS_get_next_weapon_any_box(chest);
			else
			{
				if(level.ZHC_ORDERED_BOX_FIRESALE_REASSIGN)
					ZHC_assign_weapons_to_boxes();
				rand = self ZHC_ORDERED_BOX_get_next_weapon();

				//firesale temp chests cant be used to get legendary weapons.
				//s += IsDefined( rand )+" "+ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL_save_for_special_box (rand);
				if(level.ZHC_ALL_CHESTS && level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM && level.ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL && 
					isDefined(rand) && is_true(chest.was_temp) && level.chests[level.chest_index] == chest && ZHC_ALL_CHESTS_EXEPT_STARTING_ROOM_SPECIAL_save_for_special_box (rand)
					)
				{
					//s += "got teddy";
					rand = "teddy";
					serious_teddy = false;
				}else{
					//s += "got "+rand;
				}
			}

		}
		else
			rand = self ZHC_ORDERED_BOX_get_next_weapon(is_true(init_open));
			//if(rand == "teddy")
			//	treasure_chest_ChooseWeightedRandomWeapon( player )
		
	}else{
		rand = treasure_chest_ChooseWeightedRandomWeapon( player );		//might change to something else
	}
	//IPrintLn( s );

	
	if(!isDefined(rand)){
		serious_teddy = false;
		guarenteed_teddy = true;

		//debug vvv
		s = "rand is undefined." + self.ZHC_chest_owned_weapon_index +"/"+self.ZHC_chest_owned_weapons.size + " " ;
		for(i = 0; i < self.ZHC_chest_owned_weapons.size; i++){
			if(isDefined(self.ZHC_chest_owned_weapons[i]))
				s += self.ZHC_chest_owned_weapons[i] + ", ";
			else
				s += "UNDEFINED ";
		}
		IPrintLnBold( s );
		//^^^^
	}
	else if(rand == "teddy"){
		guarenteed_teddy = true;
	}

	if(!guarenteed_teddy){

		self set_box_weapon_model_to(rand);
		//self swap_box_weapon_model_to(rand);

		/#
		weapon = GetDvar( #"scr_force_weapon" );
		if ( weapon != "" && IsDefined( level.zombie_weapons[ weapon ] ) )
		{
			rand = weapon;
			SetDvar( "scr_force_weapon", "" );
		}
		#/
		// Here's where the org get it's weapon type for the give function
		self.weapon_string = rand; 

		chest notify("zhc_box_weapon_set");
	}else{
		self.weapon_string = undefined;
	}

	


	wait_network_frame();


	// Increase the chance of joker appearing from 0-100 based on amount of the time chest has been opened.
	//zhc could use firesale var simplicity but ill refrain just for some specific case senarios.


	//rng chance of teddy
	if(!level.ZHC_ORDERED_BOX && !guarenteed_teddy){
		if(could_get_teddy_firesale_check(chest))
		{
			// random change of getting the joker that moves the box
			random = Randomint(100);
			chance_of_joker = -1;

			if( !isdefined( level.chest_min_move_usage ) )
			{
				level.chest_min_move_usage = 4;
			}

			if( level.chest_accessed < level.chest_min_move_usage )
			{		
				chance_of_joker = -1;
			}

			chance_of_joker = level.chest_accessed + 20;
			// make sure teddy bear appears on the 8th pull if it hasn't moved from the initial spot
			if ( level.chest_moves == 0 && level.chest_accessed >= 8 )
			{
				chance_of_joker = 100;
			}

			// pulls 4 thru 8, there is a 15% chance of getting the teddy bear
			// NOTE:  this happens in all cases
			if( level.chest_accessed >= 4 && level.chest_accessed < 8 )
			{
				if( random < 15 )
				{
					chance_of_joker = 100;
				}
				else
				{
					chance_of_joker = -1;
				}
			}

			// after the first magic box move the teddy bear percentages changes
			if ( level.chest_moves > 0 )
			{
				// between pulls 8 thru 12, the teddy bear percent is 30%
				if( level.chest_accessed >= 8 && level.chest_accessed < 13 )
				{
					if( random < 30 )
					{
						chance_of_joker = 100;
					}
					else
					{
						chance_of_joker = -1;
					}
				}
				
				// after 12th pull, the teddy bear percent is 50%
				if( level.chest_accessed >= 13 )
				{
					if( random < 50 )
					{
						chance_of_joker = 100;
					}
					else
					{
						chance_of_joker = -1;
					}
				}
			}

			if(IsDefined(chest.no_fly_away))
			{
				chance_of_joker = -1;
			}

			if(IsDefined(level._zombiemode_chest_joker_chance_mutator_func))
			{
				chance_of_joker = [[level._zombiemode_chest_joker_chance_mutator_func]](chance_of_joker);
			}

			if ( chance_of_joker > random )
			{
				guarenteed_teddy = true;
			}
		}
	}

	//spawn teddy. teddy is here
	if(guarenteed_teddy){
		self.weapon_string = undefined;

		self.weapon_model show();

		self.weapon_model SetModel("zombie_teddybear");

		//self.weapon_model.origin = self.weapon_model.origin +( 0, 0, floatHeight );
		//	model rotateto(level.chests[level.chest_index].angles, 0.01);
		//wait(1);
		self.weapon_model.angles = self.angles;		
		
		//if(IsDefined(self.weapon_model_dw))
		//{
		//	self.weapon_model_dw Delete();
		//	self.weapon_model_dw = undefined;
		//}
		self hide_weapon_model(false, true);
		
		self.ZHC_teddy_here = true;

		if(ZHC_should_take_teddy_seriously(chest,false)
		 && is_true(serious_teddy)
		 ){
			if(level.ZHC_ALL_CHESTS){
				level.ZHC_ALL_CHESTS_last_box_to_move_index = get_chest_index(chest);
			}
			self.chest_moving = true;
			flag_set("moving_chest_now");
			level.chest_accessed = 0;
			//allow power weapon to be accessed.
			level.chest_moves++;
		}

	}

	if(!mariocycle && !is_true(chest._box_open) && !guarenteed_teddy)
		wait 0.75;

	self notify( "randomization_done" );


	if (self ZHC_teddy_is_here())
	{
		if(IsDefined( self.weapon_model ))
			self.weapon_model notify("kill_weapon_movement");
		self notify("teddy_appear");
		wait .5;	// we need a wait here before this notify
		level notify("weapon_fly_away_start");
		wait 2;

		if(IsDefined(self.weapon_model))
			self.weapon_model MoveZ(500, 4, 3);
		
		if(IsDefined(self.weapon_model_dw))
			self.weapon_model_dw MoveZ(500,4,3);

		if(IsDefined(self.weapon_model))
			self.weapon_model waittill("movedone");

		self delete_weapon_model();

		if(ZHC_should_take_teddy_seriously(chest,true)){
			//box can have teddy duuring fire sale but it wont fly away
			self notify( "box_moving" );
			level notify("weapon_fly_away_end");
		}
	}
	else
	{
		acquire_weapon_toggle( rand, player );

		//turn off power weapon, since player just got one
		if( rand == "tesla_gun_zm" || rand == "ray_gun_zm" )
		{
			if( rand == "ray_gun_zm" )
			{
			//level.chest_moves = false;
				level.pulls_since_last_ray_gun = 0;
			}
			
			if( rand == "tesla_gun_zm" )
			{
				level.pulls_since_last_tesla_gun = 0;
				level.player_seen_tesla_gun = true;
			}			
		}

		if(!IsDefined(respin))
		{
			if(IsDefined(chest.box_hacks["respin"]))
			{
				self [[chest.box_hacks["respin"]]](chest, player);
			}
		}
		else
		{
			if(IsDefined(chest.box_hacks["respin_respin"]))
			{
				self [[chest.box_hacks["respin_respin"]]](chest, player);
			}
		}
	}
}

ZHC_teddy_is_here(){
	return is_true(self.ZHC_teddy_here);
}

ZHC_should_take_teddy_seriously(chest, post_selection){;
	if(is_true(post_selection))
		//return is_true(chest.chest_origin.chest_moving)	//commented out and switched 3/20/2023
		return is_true(chest.chest_origin.chest_moving);
	return !is_true(chest.was_temp);
}

ZHC_box_has_teddy(){									//not a needed func
	if(level.ZHC_ORDERED_BOX_TEDDY_AT_END_OF_EVERY_BOX)
		return true;
	if(level.ZHC_ORDERED_BOX_RANDOM_TEDDY)
		return self.ZHC_has_teddy;
}
//
//
chest_get_min_usage()
{
	min_usage = 4;

	/*
	players = get_players();

	// Special case min box pulls before 1st box move
	if( level.chest_moves == 0 )
	{
		if( players.size == 1 )
		{
			min_usage = 2;
		}
		else if( players.size == 2 )
		{
			min_usage = 2;
		}
		else if( players.size == 3 )
		{
		}
			min_usage = 3;
		else
		{
			min_usage = 4;
		}
	}
	// Box has moved, what is the minimum number of times it can move again?
	else
	{
		if( players.size == 1 )
		{
			min_usage = 2;
		}
		else if( players.size == 2 )
		{
			min_usage = 2;
		}
		else if( players.size == 3 )
		{
			min_usage = 3;
		}
		else
		{
			min_usage = 3;
		}
	}
	*/

	return( min_usage );
}

//
//
chest_get_max_usage()
{
	max_usage = 6;

	players = get_players();

	// Special case max box pulls before 1st box move
	if( level.chest_moves == 0 )
	{
		if( players.size == 1 )
		{
			max_usage = 3;
		}
		else if( players.size == 2 )
		{
			max_usage = 4;
		}
		else if( players.size == 3 )
		{
			max_usage = 5;
		}
		else
		{
			max_usage = 6;
		}
	}
	// Box has moved, what is the maximum number of times it can move again?
	else
	{
		if( players.size == 1 )
		{
			max_usage = 4;
		}
		else if( players.size == 2 )
		{
			max_usage = 4;
		}
		else if( players.size == 3 )
		{
			max_usage = 5;
		}
		else
		{
			max_usage = 7;
		}
	}
	return( max_usage );
}
//ZHC_gun_swapping(){

//}

timer_til_despawn(chest, floatHeight)
{
	chest endon ("box_finished");		//this runs last.
	self endon ("teddy_appear");
	
	chest waittill("weapon_expired");


	//( "dropping weapon" );


	//TODO MAYBE recycle WEAPON MODEL

	if(IsDefined( self.weapon_string )){
		put_back_time = 6;
		if(chest.ZHC_GUN_SWAP && level.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP && is_true(self.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP_swapped)){
			self.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP_swapped = undefined;
			put_back_time = 1.5;

			//stop model then add some small delay before drop. nice feel (not at all nessary)
			if(IsDefined( self.weapon_model ))
				self.weapon_model moveTo(self.weapon_model.origin,0.1,0.1);
			if(IsDefined( self.weapon_model_dw ))
				self.weapon_model_dw moveTo(self.weapon_model_dw.origin,0.1,0.1);
			wait(0.5); 
			//

			
		}
		//IPrintLn( self.weapon_string +" expired");
		put_back_time *= Distance( self.weapon_model.origin, self.origin)/floatHeight;//increase the speed of weapon drop based on weapons position
		//put_back_time = max(put_back_time, 0.5);
		//IPrintLn( put_back_time );
		if(IsDefined( self.weapon_model ))
			self.weapon_model thread weapon_drop_down(self.origin, put_back_time, floatHeight);
		if(isDefined(self.weapon_model_dw))
			self.weapon_model_dw thread weapon_drop_down(self.origin - (3,3,3),put_back_time, floatHeight);
		if(put_back_time > 0.5)
			wait(put_back_time - 0.5);
	}else{
		//IPrintLn( "chest expired, no weapon" );
		//chest disable_trigger();
		self.weapon_string = undefined;
		self hide_weapon_model(true,true);
	}
	chest.chest_lid notify( "close_lid" );

	self waittill( "box_finished" );//this runs before endon box_finished which allows for next line to happen.
	self delete_weapon_model();
}

weapon_drop_down(chest_origin, put_back_time, floatHeight){
	self endon("kill_weapon_movement");
	// SRS 9/3/2008: if we timed out, move the weapon back into the box instead of deleting it
	//self MoveTo( self.origin - ( 0, 0, floatHeight ), put_back_time, ( put_back_time * 0.5 ) );
	if(put_back_time <= 0)
		self MoveTo(chest_origin);
	else{
		self MoveTo(chest_origin,put_back_time, (put_back_time*0.5));
		//wait( put_back_time );
	}
	/*if(isdefined(self))	//deletion done by other func
	{	
		self Delete();
	}*/
}
treasure_chest_glowfx(chest, waitToString)
{
	fxObj = spawn( "script_model", self.origin +( 0, 0, 0 ) ); 
	fxobj setmodel( "tag_origin" ); 
	fxobj.angles = self.angles +( 90, 0, 0 ); 

	playfxontag( level._effect["chest_light"], fxObj, "tag_origin"  ); 

	if(IsDefined( waitToString ))
		self waittill_any_ents( self, waitToString, self, "box_finished", chest.chest_lid,"close_lid",self, "box_moving" ); 
	else
		self waittill_any_ents(self, "box_finished", chest.chest_lid,"close_lid",self, "box_moving"  ); 
	fxobj delete(); 
}
ZHC_upgrade_weapon(weapon_string, effect_origin){
	if(level.ZHC_UPGRADE_WEAPON_SYSTEM){
		self maps\ZHC_zombiemode_weapons::upgrade_weapon(weapon_string);
		playfx(level._effect["poltergeist"], effect_origin);
	}
}
// self is the player string comes from the randomization function
treasure_chest_give_weapon( weapon_string, chest, swap)
{
	//cycle = false;

	if(!IsDefined( chest ))
		swap = false;

	/*if(!isDefined(cycle))
		cycle = false;\
	*/
	self.last_box_weapon = GetTime();
	primaryWeapons = self GetWeaponsListPrimaries(); 
	current_weapon = undefined; 

	current_weapon = self getCurrentWeapon(); // ADDED FOR MOD

	weapon_limit = level.zhc_starting_weapon_slots;
	if ( self HasPerk( "specialty_additionalprimaryweapon" ) )
	{
		weapon_limit = level.zhc_starting_weapon_slots+1;
		if(level.PERK_LEVELS){
			weapon_limit = level.zhc_starting_weapon_slots + self maps\_zombiemode_perks::GetPerkLevel("specialty_additionalprimaryweapon");
		}
	}

	can_take_weapon = true;
	box_empty = false;

	already_has_weapon = false;
	

	if(isDefined(weapon_string)){
		if( self has_weapon_or_upgrade( weapon_string ) )
		{
			can_take_weapon = false;
			already_has_weapon = true;
			if ( issubstr( weapon_string, "knife_ballistic_" ) ){
				self notify( "zmb_lost_knife" );
			}
			//return;
		}
	}else{
		box_empty = true;
	}

	is_equipment = is_equipment(weapon_string) || is_placeable_mine(weapon_string) || (WeaponType( weapon_string ) == "grenade"); //
	if(can_take_weapon && !box_empty) {
		self play_sound_on_ent( "purchase" );
		
		if( IsDefined( level.zombiemode_offhand_weapon_give_override ) )
		{
			self [[ level.zombiemode_offhand_weapon_give_override ]]( weapon_string );
		}

		if(weapon_string == "zombie_cymbal_monkey" )
		{
			self maps\_zombiemode_weap_cymbal_monkey::player_give_cymbal_monkey();
			self play_weapon_vo(weapon_string);
			is_equipment = true;	
			//return;
		}else{
			if(!is_equipment){
				if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "bowie_knife_zm" ) )
				{
					weapon_string = "knife_ballistic_bowie_zm";
				}
				else if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "sickle_knife_zm" ) )
				{
					weapon_string = "knife_ballistic_sickle_zm";
				}
				if (weapon_string == "ray_gun_zm")
				{
					playsoundatposition ("mus_raygun_stinger", (0,0,0));		
				}
			}

			self GiveWeapon( weapon_string, 0 );

			//self GiveStartAmmo( weapon_string );
			self SwitchToWeapon( weapon_string );

			self play_weapon_vo(weapon_string);
			
		}
		self maps\ZHC_zombiemode_weapons::give_weapon(weapon_string, true);
		if(is_equipment && level.ZHC_BOX_EQUIPMENT_REALISTIC){
			self maps\ZHC_zombiemode_weapons::set_weapon_ammo(weapon_string, 1);
		}
		
	}

	if(already_has_weapon){
		if(level.ZHC_BOX_UPGRADE_WEAPON_ON_CLONE_PICK_UP)				//will upgrade regardless
			self ZHC_upgrade_weapon(weapon_string, chest.origin);
		if(is_equipment && level.ZHC_BOX_EQUIPMENT_REALISTIC){
			self maps\ZHC_zombiemode_weapons::add_weapon_ammo(weapon_string,1); // this is just a way of making monkies in the box only refill one to make it feel more consistent.
		}else{
			self maps\ZHC_zombiemode_weapons::refill_weapon_ammo(weapon_string);
		}
		
	}


		// means a weapon must be dropped
		// if wep slots are full, or if box is prompted to place gun
	if(!is_equipment && can_take_weapon && (primaryWeapons.size >= weapon_limit || swap && box_empty))
	{
		//current_weapon = self getCurrentWeapon(); // CHANGED FOR MOD
		if ( is_placeable_mine( current_weapon ) || is_equipment( current_weapon )) 
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !is_offhand_weapon( weapon_string ) || box_empty)
			{
				// PI_CHANGE_BEGIN
				// JMA - player dropped the tesla gun
				if( current_weapon == "tesla_gun_zm" )
				{
					level.player_drops_tesla_gun = true;
				}
				// PI_CHANGE_END
				
				if ( issubstr( current_weapon, "knife_ballistic_" ) )
				{
					self notify( "zmb_lost_knife" );
				}
				
				self maps\ZHC_zombiemode_weapons::take_weapon(current_weapon);
				self TakeWeapon( current_weapon );

				unacquire_weapon_toggle( current_weapon );
				if ( current_weapon == "m1911_zm" )
				{
					self.last_pistol_swap = GetTime();
				}

			} 
		}
		if(swap){
			//( "swapped model to "+current_weapon );

			//wait_network_frame();	// wait for "weapon_grabbed" to delete models

			//chest.chest_origin set_box_weapon_model_to(current_weapon);

			//if(cycle){

				//TODO: if chest has current weapon

				//else

				//CYCLE SHOULD DO EVERYTHING ELSE

				//TODO: remove "current_weapon" from every other box.
			//}
			//else{
				if(!isDefined(weapon_string)){			// if box is empty, means cur weapon is added to box, so switch to other gun
					primaryWeapons = self GetWeaponsListPrimaries();
					if(isDefined(primaryWeapons[0]))
						self SwitchToWeapon( primaryWeapons[0]);
					if(level.ZHC_ORDERED_BOX && level.ZHC_ORDERED_BOX_GUNS_STORABLE ){
						if(level.ZHC_ORDERED_BOX_ONE_ORDER)
							level.ZHC_chest_owned_weapons = array_insert( level.ZHC_chest_owned_weapons,current_weapon,level.ZHC_chest_owned_weapon_index );
						else
							chest.chest_origin.ZHC_chest_owned_weapons = array_insert( chest.chest_origin.ZHC_chest_owned_weapons,current_weapon,chest.chest_origin.ZHC_chest_owned_weapon_index );
						//if(box_empty)
						//	chest.chest_origin.ZHC_chest_owned_weapon_index ++;
					}
				} else if(level.ZHC_ORDERED_BOX && level.ZHC_ORDERED_BOX_GUNS_STORABLE){
					if(level.ZHC_ORDERED_BOX_ONE_ORDER){
						level.ZHC_chest_owned_weapons[level.ZHC_chest_owned_weapon_index] = current_weapon;
					}
					else
						chest.chest_origin.ZHC_chest_owned_weapons[chest.chest_origin.ZHC_chest_owned_weapon_index] = current_weapon;
				}


				//if(cycle)
				chest.chest_origin.weapon_string = current_weapon;
				chest.chest_origin swap_box_weapon_model_to(current_weapon);

				chest notify("zhc_box_weapon_set");

				/#
				weapon = GetDvar( #"scr_force_weapon" );
				if ( weapon != "" && IsDefined( level.zombie_weapons[ weapon ] ) )
				{
					current_weapon = weapon;
					SetDvar( "scr_force_weapon", "" );
				}
				#/

				if(level.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP){
					chest.chest_origin.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP_swapped = true;
					chest notify ("weapon_expired");
				}
			//}
		}
	}else if(swap){
		//weapon slots arent full
		//take gun dont swap weapon into box
		chest.chest_origin hide_weapon_model(true, true);
		chest.chest_origin.weapon_string = undefined;


		if(level.ZHC_ORDERED_BOX && level.ZHC_ORDERED_BOX_GUNS_STORABLE){
			if(level.ZHC_ORDERED_BOX_ONE_ORDER){
				index = level.ZHC_chest_owned_weapon_index;
				level.ZHC_chest_owned_weapons[index] = undefined;
				level.ZHC_chest_owned_weapons = array_remove_index( level.ZHC_chest_owned_weapons,index );
			}else{
				index = chest.chest_origin.ZHC_chest_owned_weapon_index;
				chest.chest_origin.ZHC_chest_owned_weapons[index] = undefined;
				chest.chest_origin.ZHC_chest_owned_weapons = array_remove_index( chest.chest_origin.ZHC_chest_owned_weapons,index );
			}
			thread reduce_chest_index(chest);
			//chest.chest_origin.ZHC_chest_owned_weapon_index --;
			if(!chest.ZHC_GUN_CYCLE && level.ZHC_ORDERED_BOX_GUNS_STORABLE_CLOSE_WHEN_EMPTY){
				//chest.chest_lid notify ("close_lid");
				chest notify ("weapon_expired");
			}
		}else if(level.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP){
			chest.chest_origin.ZHC_GUN_SWAP_CLOSE_AFTER_SWAP_swapped = true;
			chest notify ("weapon_expired");
		}

		//chest.chest_origin swap_box_weapon_model_to();	//should get deleted by other thing
	}

	//IPrintLn( chest.chest_origin.ZHC_chest_owned_weapon_index + " / " + chest.chest_origin.ZHC_chest_owned_weapons.size);
}


reduce_chest_index(chest){
	chest endon ("user_grabbed_weapon");
	chest waittill("box_finished");
	if(level.ZHC_ORDERED_BOX_ONE_ORDER){
		level.ZHC_chest_owned_weapon_index --;
	}else{
		//chest.chest_origin.ZHC_chest_owned_weapons = array_remove_index( chest.chest_origin.ZHC_chest_owned_weapons,chest.chest_origin.ZHC_chest_owned_weapon_index );
		chest.chest_origin.ZHC_chest_owned_weapon_index --;
	}
}

pay_turret_think( cost )
{
	if( !isDefined( self.target ) )
	{
		return;
	}
	turret = GetEnt( self.target, "targetname" );

	if( !isDefined( turret ) )
	{
		return;
	}
	
	turret makeTurretUnusable();
	
	// figure out what zone it's in
	zone_name = turret get_current_zone();
	if ( !IsDefined( zone_name ) )
	{
		zone_name = "";
	}
	

	while( true )
	{
		self waittill( "trigger", player );
		
		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( player in_revive_trigger() )
		{
			wait( 0.1 );
			continue;
		}

		if( player is_drinking() )
		{
			wait(0.1);
			continue;
		}
		
		if( player.score >= cost )
		{
			player maps\_zombiemode_score::minus_to_player_score( cost );
			bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type turret", player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, zone_name, self.origin );
			turret makeTurretUsable();
			turret UseBy( player );
			self disable_trigger();
			
			player maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "mg" );
			
			player.curr_pay_turret = turret;
			
			turret thread watch_for_laststand( player );
			turret thread watch_for_fake_death( player );
			if( isDefined( level.turret_timer ) )
			{
				turret thread watch_for_timeout( player, level.turret_timer );
			}
			
			while( isDefined( turret getTurretOwner() ) && turret getTurretOwner() == player )
			{
				wait( 0.05 );
			}
			
			turret notify( "stop watching" );
			
			player.curr_pay_turret = undefined;
			
			turret makeTurretUnusable();
			self enable_trigger();
		}
		else // not enough money
		{
			play_sound_on_ent( "no_purchase" );
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 0 );
		}
	}
}

watch_for_laststand( player )
{
	self endon( "stop watching" );
	
	while( !player maps\_laststand::player_is_in_laststand() )
	{
		if( isDefined( level.intermission ) && level.intermission )
		{
			intermission = true;
		}
		wait( 0.05 );
	}
	
	if( isDefined( self getTurretOwner() ) && self getTurretOwner() == player )
	{
		self UseBy( player );
	}
}

watch_for_fake_death( player )
{
	self endon( "stop watching" );
	
	player waittill( "fake_death" );
	
	if( isDefined( self getTurretOwner() ) && self getTurretOwner() == player )
	{
		self UseBy( player );
	}
}

watch_for_timeout( player, time )
{
	self endon( "stop watching" );
	
	self thread cancel_timer_on_end( player );
	
//	player thread maps\_zombiemode_timer::start_timer( time, "stop watching" );
	
	wait( time );
	
	if( isDefined( self getTurretOwner() ) && self getTurretOwner() == player )
	{
		self UseBy( player );
	}
}

cancel_timer_on_end( player )
{
	self waittill( "stop watching" );
	player notify( "stop watching" );
}

weapon_cabinet_door_open( left_or_right )
{
	if( left_or_right == "left" )
	{
		self rotateyaw( 120, 0.3, 0.2, 0.1 ); 	
	}
	else if( left_or_right == "right" )
	{
		self rotateyaw( -120, 0.3, 0.2, 0.1 ); 	
	}	
}

check_collector_achievement( bought_weapon )
{
	if ( !isdefined( self.bought_weapons ) )
	{
		self.bought_weapons = [];
		self.bought_weapons = array_add( self.bought_weapons, bought_weapon );
	}
	else if ( !is_in_array( self.bought_weapons, bought_weapon ) )
	{
		self.bought_weapons = array_add( self.bought_weapons, bought_weapon );
	}
	else
	{
		// don't bother checking, they've bought it before
		return;
	}
	
	for( i = 0; i < level.collector_achievement_weapons.size; i++ )
	{
		if ( !is_in_array( self.bought_weapons, level.collector_achievement_weapons[i] ) )
		{
			return;
		}
	}
	
	self giveachievement_wrapper( "SP_ZOM_COLLECTOR" );
}

ZHC_set_weapon_hint( cost, ammo_cost, upgraded_ammo_cost, weapon_string, weapon_name, can_buy_weapon, can_buy_ammo, can_buy_upgraded_ammo, can_buy_weapon_upgrade, weapon_upgrade_cost, weapon_upgrade_level) //added for mod
{
	if(!IsDefined( upgraded_ammo_cost ))
		upgraded_ammo_cost = 4500;
	if(!IsDefined( can_buy_weapon ))
		can_buy_weapon = true;
	if(!IsDefined( can_buy_ammo ))
		can_buy_ammo = true;
	if(!IsDefined( can_buy_upgraded_ammo ))
		can_buy_upgraded_ammo = can_buy_ammo;

	if(!IsDefined( can_buy_weapon_upgrade ))
		can_buy_weapon_upgrade = false;
	else if(!IsDefined( weapon_upgrade_level ) || !IsDefined( weapon_upgrade_cost ))
		can_buy_weapon_upgrade = false;

	if(is_equipment(weapon_string) || is_placeable_mine(weapon_string) || (WeaponType( weapon_string ) == "grenade"))
		self SetHintString( get_weapon_hint( weapon_string ), cost );

	can_use_zombie_weap_hint = false;
	if(isDefined(weapon_string) &&isDefined(level.zombie_weapons[weapon_string]) && IsDefined(level.zombie_weapons[weapon_string].weapon_name )){
		if(!isDefined(weapon_name))
			weapon_name = level.zombie_weapons[weapon_string].weapon_name;
		if(weapon_name == level.zombie_weapons[weapon_string].weapon_name && can_buy_weapon && !can_buy_ammo && !can_buy_upgraded_ammo && !can_buy_weapon_upgrade){
			//IPrintLn( "get_weapon_hint" );
			self SetHintString( get_weapon_hint( weapon_string ), cost);	//has more language options
			return;
		}
	}
	if(!isDefined(weapon_name)){
		if(upgraded_ammo_cost == 4500 && can_buy_weapon && can_buy_ammo && !can_buy_weapon_upgrade){
			//IPrintLn( "weapon_set_first_time_hint" );
			weapon_set_first_time_hint( cost, ammo_cost, can_buy_upgraded_ammo);	//has more language options
			return;
		}
		weapon_name = "Weapon";
	}

	pre_weapon_name_string = "";
	weapon_buy_string_1 = "";
	weapon_buy_string_2 = "";
	ammo_buy_string_1 = "";
	ammo_buy_string_2 = "";
	upgraded_ammo_buy_string_1 = "";
	upgraded_ammo_buy_string_2 = "";
	weapon_upgrade_string_1 = "";
	weapon_upgrade_string_2 = "";
	to_buy_string = " to buy";
	cost_string = "Cost: ";
	total_num_of_prices = 0;


	if(can_buy_weapon){//buy weapon price display
		weapon_buy_string_1 +=  "[";	//first part of price
		weapon_buy_string_2 += cost+"]";//second part of price
		total_num_of_prices++;
	}
	if(can_buy_ammo){//buy ammo price display
		if(total_num_of_prices > 0)
			ammo_buy_string_1 += ", ";	//add comma before next price display
		ammo_buy_string_1 += "Ammo [";
		ammo_buy_string_2 += ammo_cost+"]";
		total_num_of_prices++;
	}
	if(can_buy_upgraded_ammo && !is_false(level.has_pack_a_punch)){	//buy upgraded ammo price display
		if(total_num_of_prices > 0)
			upgraded_ammo_buy_string_1 += ", ";
		upgraded_ammo_buy_string_1 += "Upgraded Ammo [";
		upgraded_ammo_buy_string_2 += upgraded_ammo_cost+"]";
		total_num_of_prices++;
	}
	if(can_buy_weapon_upgrade){	//buy upgraded ammo price display
		if(total_num_of_prices > 0)
			upgraded_ammo_buy_string_1 += ", ";
		pre_weapon_name_string += " Level "+weapon_upgrade_level;
		upgraded_ammo_buy_string_1 += "[";
		upgraded_ammo_buy_string_2 += weapon_upgrade_cost+"]";
		total_num_of_prices++;
	}

	if(total_num_of_prices > 1){	//if more than once price exists simplifies the price display
		cost_string = "";
		to_buy_string = "";
	}	

	text = "Hold &&1"+to_buy_string+pre_weapon_name_string+" "+weapon_name+" "+ 
		util_connect_strings(weapon_buy_string_1, cost_string, weapon_buy_string_2) +
		util_connect_strings(ammo_buy_string_1, cost_string, ammo_buy_string_2) +
		util_connect_strings(upgraded_ammo_buy_string_1, cost_string, upgraded_ammo_buy_string_2);
	//IPrintLn (text);
	self SetHintString( text
		); 
}
//returns the combined string only if both the first and last given substrings are not empty.
//otherwise returns the remaining the non empty string.
util_connect_strings(str1, connectorStr, str2){	
	if(str1 == "")
		return str2;
	if(str2 == "")
		return str1;
	return str1 + connectorStr + str2;
}
weapon_set_first_time_hint( cost, ammo_cost, can_buy_upgraded_ammo)
{
	if ( is_false(can_buy_upgraded_ammo) ||  is_false(level.has_pack_a_punch) )
	{
		self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO", cost, ammo_cost ); 
	}
	else
	{
		self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO_UPGRADE", cost, ammo_cost ); 
	}
}
zhc_managa_upgrade_hintstrings( can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string, endon_string1, endon_string2){
	if(IsDefined( endon_string1 ))
		self endon( endon_string1 );
	if(IsDefined( endon_string2 ))
		self endon( endon_string2 );

	if (is_placeable_mine( weapon_string ) || is_equipment( weapon_string ) || (WeaponType( weapon_string ) == "grenade")){
		//wait(0.3);
		return;
	}
	self thread weapon_pick_up_update_hintstrings(can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string, endon_string1, endon_string2);
	for(;;)
	{
		wait(self update_wall_upgrade_weapon_hintstrings(can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string));
	}
}

weapon_pick_up_update_hintstrings(can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string, endon_string1, endon_string2){
	if(IsDefined( endon_string1 ))
		self endon( endon_string1 );
	if(IsDefined( endon_string2 ))
		self endon( endon_string2 );
	for(;;){
		self waittill( "update_hintstrings" );
		self update_wall_upgrade_weapon_hintstrings(can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string);
	}
}

update_wall_upgrade_weapon_hintstrings(can_init_buy, can_buy_ammo, cost, ammo_cost, weapon_string){
	waitTime = 0.5;
	if(is_true(self.ZHC_WALL_GUN_can_upgrade)){
		//weapon_string = self.chest_origin.weapon_string;
		//check weapon_sting is valid
		players = get_players();
		a_player_has_weapon = false;
		closest_has_weapon = false;
		//affordibility_system
		closests_can_afford_next_level = false;

		if(players.size >= 1){  //testo //changed temp for testing purposes. change to " > 1"
			closest = players[0];
			if(!is_player_valid( closest )){
				//IPrintLnBold( "player not valid :(" );
				return 0.5;
			}
			closest_distance = Distance2DSquared(self.origin, closest.origin);
			
			a_player_has_weapon = closest has_weapon_or_upgrade( weapon_string );

			if(!can_buy_ammo)
				closest_has_weapon = a_player_has_weapon;

			dif = 10000000000;

			for( i = 1; i < players.size; i++ )
			{
				if(!players[i] has_weapon_or_upgrade( weapon_string )){
					if(!can_buy_ammo && closest_has_weapon){
						dist = DistanceSquared(self.origin, players[i].origin);
						if(dist < closest_distance){
							closest_has_weapon = false;
						}
					}
					continue;
				}

				dist = DistanceSquared(self.origin, players[i].origin);
				if(dist < closest_distance){
					closest = players[i];
					closest_distance = dist;
					dif = closest_distance - dist;
					if(!can_buy_ammo)
						closest_has_weapon = true;
				}else if (!a_player_has_weapon){
					closest = players[i];
					closest_distance = dist;
				}
				a_player_has_weapon = true;
			}
			if(a_player_has_weapon){
				zws = maps\ZHC_zombiemode_weapons::weapon_name_check(weapon_string);
				zwzid = closest.ZHC_weapons[zws];
				if(!IsDefined( zwzid )){
					IPrintLnBold( "player " +zws+ " not supscribed" );
					return 0.5;
				}
				closest_level = closest.ZHC_weapon_levels[zwzid];
				self.ZHC_weapon_upgrade_lvl = closest_level + 1;
				self.ZHC_weapon_upgrade_cost = maps\ZHC_zombiemode_weapons::get_upgrade_weapon_cost(cost,closest_level);
				closests_can_afford_next_level = self.ZHC_weapon_upgrade_cost <= closest.score;
				//if(!can_init_buy || (!can_buy_ammo && closest_has_weapon) || closests_can_afford_next_level)
				//	cost = self.ZHC_weapon_upgrade_cost;
				waitTime = min(max(0.3, sqrt(dif)/250),7.1 + RandomInt( 3 ));
			}
		}else{
			player = players[0];
			if(!is_player_valid( player )){
				//IPrintLnBold( "player not valid :(" );
				return 0.5;
			}

			a_player_has_weapon = player has_weapon_or_upgrade( weapon_string );
			if(a_player_has_weapon){
				zws = maps\ZHC_zombiemode_weapons::weapon_name_check(weapon_string);
				if(!isDefined(player.ZHC_weapons[zws])){
					IPrintLnBold( "player " +zws+ " not supscribed" );
					return 0.3;
				}
				player_level = player.ZHC_weapon_levels[player.ZHC_weapons[zws]];
				self.ZHC_weapon_upgrade_lvl = player_level + 1;
				self.ZHC_weapon_upgrade_cost = maps\ZHC_zombiemode_weapons::get_upgrade_weapon_cost(cost,player_level);
				closests_can_afford_next_level = self.ZHC_weapon_upgrade_cost <= player.score;
				closest_has_weapon = true;
				//if(!can_init_buy || !can_buy_ammo || closests_can_afford_next_level)
				//	cost = self.ZHC_weapon_upgrade_cost;
			}
		}
		/*if( can_buy_ammo && (a_player_has_weapon || self.first_time_triggered) && !closests_can_afford_next_level){
			self weapon_set_first_time_hint( cost, ammo_cost );
		}else{
			self SetHintString( get_weapon_hint( weapon_string ), cost);
		}*/
		self ZHC_set_weapon_hint( cost, ammo_cost, 4500, weapon_string, undefined, can_init_buy && !closest_has_weapon, can_buy_ammo && (a_player_has_weapon || self.first_time_triggered), can_buy_ammo && (a_player_has_weapon || self.first_time_triggered), closest_has_weapon, self.ZHC_weapon_upgrade_cost, self.ZHC_weapon_upgrade_lvl);
	}else{
		/*if(can_buy_ammo && self.first_time_triggered)
			self weapon_set_first_time_hint( cost, ammo_cost );
		else if(can_init_buy){
			self SetHintString( get_weapon_hint( weapon_string ), cost);
		}else{
			self SetHintString( "Upgrade Unavailable." );
		}*/
		if(can_init_buy || (can_buy_ammo && self.first_time_triggered))
			self ZHC_set_weapon_hint( cost, ammo_cost, 4500, weapon_string, undefined, can_init_buy, can_buy_ammo && self.first_time_triggered, can_buy_ammo && self.first_time_triggered);
		else
			self SetHintString( "Upgrade Unavailable." );
		waitTime = 0.1; 
	}
	
	return waitTime;
}

wall_weapon_wait_to_return(strength){	//this function hs=should only run for wall weapons, real wall weapons, not chests or barr weapons

	self notify("weapon_stop");
	self disable_trigger();
	self.weapon_disabled = true;
	if(strength > 0){
		//IPrintLnBold("firing_wall_gun_goals");
		self.weapon_model maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, undefined, 1, undefined, true);
		iPrintLnBold("zhc_end_of_cooldown_wall_weapon");
	}

	if(level.ZHC_LOGICAL_WEAPON_SHOW){
		self thread show_weapon_model();
		wait(1);
		wait_network_frame();
		self.first_time_triggered = false;
	}
	self.weapon_disabled = false;
	self enable_trigger();
	self thread weapon_spawn_think();
}

wall_weapon_is_active(){
	return !is_true(self.weapon_disabled);
}

wall_upgrade_wait_to_return(is_chest, strength){
	//if we dont want the first init buy to disable next upgrade
	self.ZHC_WALL_GUN_can_upgrade = false;
	if(strength > 0){
		ent = self.weapon_model;
		if(is_chest)
			ent = self.chest_origin;
		ent maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(1, undefined, undefined, 1, undefined, true);
		//iPrintLnBold("zhc_end_of_cooldown_wall_weapon_upgrade");
	}

	if(level.ZHC_LOGICAL_WEAPON_SHOW){
		if(!is_chest){
			self thread show_weapon_model();
			wait(1);
			wait_network_frame();
		}
		self.first_time_triggered = false;
	}

	self.ZHC_WALL_GUN_can_upgrade = true;
	self notify ("update_hintstrings");
}

swap_weapon_buyable(is_chest, can_init_buy, can_buy_ammo, can_upgrade, weapon){
	last_weapon = undefined;
	if(is_chest){
		last_weapon = self.chest_origin.weapon_string;
	}
	else{
		last_weapon = self.zombie_weapon_upgrade;
	}

	if(IsDefined( last_weapon ) ){
		if(!isDefined(self.original_weapon))
			self.original_weapon = last_weapon;
	}

	self notify( "weapon_stop" );

	if(IsDefined( self.ZHC_WALL_GUN_can_upgrade ) || can_upgrade){
		self.ZHC_WALL_GUN_can_upgrade = undefined;
		self.ZHC_weapon_upgrade_lvl = undefined;
		self.ZHC_weapon_upgrade_cost = undefined;
	}

	if(!IsDefined( last_weapon ) || weapon != last_weapon){
		self thread weapon_model_hide(undefined, true);
		wait(1);
		self wait_network_frame( );
	}
	self set_box_weapon_model_to(weapon);
	self thread show_weapon_model();
	wait(1);
	wait_network_frame();
	self ZHC_set_weapon_hint(get_weapon_cost(weapon), get_ammo_cost(weapon), 4500, weapon, undefined, false, true, true);
	self thread weapon_spawn_think(is_chest, undefined, can_init_buy, can_buy_ammo, can_upgrade, weapon);
}

weapon_spawn_think(is_chest, player_has_weapon, can_init_buy, can_buy_ammo, can_upgrade, weapon)
{
	if(!IsDefined( is_chest ))
		is_chest = false;
	if(!IsDefined( can_init_buy ))
		can_init_buy = true;
	if(!IsDefined( can_upgrade ))
		can_upgrade = level.ZHC_WALL_UPGRADE_WEAPON_ON_CLONE_PICK_UP;
	if(!IsDefined( can_buy_ammo ))
		can_buy_ammo = true;

	if(!level.ZHC_UPGRADE_WEAPON_SYSTEM)
		can_upgrade = false;

	/*if(is_chest){
		self endon ("weapon_stop");
		self endon ("box_hacked_respin");
		self endon ("box_finished");	////might be better to make weapon stop fire in the chest code, trather than rely on box finished.
	}else{*/
		self endon ("weapon_stop");		//should work for all cases
	//}

	if(!IsDefined( weapon )){
		if(is_chest){
			weapon = self.chest_origin.weapon_string;
		}
		else{
			weapon = self.zombie_weapon_upgrade;
		}
	}
	spawns_powerups = (	level.ZHC_WEAPONS_KILL_NOTIFY &&
							(is_chest && level.ZHC_BOX_GUN_BUYABLE_SPAWN_POWERUPS) || 
							(!is_chest && level.ZHC_WALL_GUN_BUYABLE_SPAWN_POWERUPS)
						);
	if(spawns_powerups)	//chest only?
	{
		self thread ZHC_wall_buy_manage_power_up_spawn(weapon);
	}

	cost = undefined;
	if(can_init_buy || can_buy_ammo)
		cost = get_weapon_cost( weapon );

	ammo_cost = undefined;
	if(can_buy_ammo)
		ammo_cost = get_ammo_cost( weapon );



	is_grenade = (WeaponType( weapon ) == "grenade");


	self.first_time_triggered = false;



	if(!is_chest && !IsDefined( self.weapon_model )){
		self.weapon_model = getent( self.target, "targetname" ); 
		if(level.ZHC_LOGICAL_WEAPON_SHOW && !can_upgrade){	//only runs
			self.weapon_model show();								//if we want the weapon to show up on first spawn. 
																	//decided to have it off when upgradable because its more consistent with the upgrade 
																	//system if it weapon only appears when an upgrade is availables.
		}
	}


	/*if(is_chest && level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE)
		self thread decide_hide_show_hint("weapon_grabbed", "box_finished", "weapon_stop");
	else if (is_chest)
		self thread decide_hide_show_hint("box_finished", "weapon_stop");
	else*/
		self thread decide_hide_show_hint("weapon_stop");	//should work for all cases.

	//IPrintLn(!can_upgrade +""+ !isDefined(player_has_weapon) +""+can_buy_ammo+""+ !is_grenade);
	if(can_upgrade){	
		//endon_string = undefined;
		//if(is_chest)
		//	endon_string = "box_finished";
		if(!isDefined(self.ZHC_WALL_GUN_can_upgrade))
			self.ZHC_WALL_GUN_can_upgrade = true;
		self thread zhc_managa_upgrade_hintstrings( can_init_buy, can_buy_ammo, cost, ammo_cost, weapon, "weapon_stop" );//, endon_string );
		
	}
	else if(!isDefined(player_has_weapon) && can_buy_ammo && !is_grenade)
	//checks if any player has weapon if so update hintstring. 
	//we could potentially turn this into a function and loop it for closest player
	{	
		players = get_players();
		player_has_weapon = false;
		for(i = 0; i < players.size; i++){
			if(players[i] has_weapon_or_upgrade( weapon )){
				player_has_weapon = true;
				break;
			}
		}
		//if(player_has_weapon)
			//self weapon_set_first_time_hint( cost, ammo_cost );
		//IPrintLn("player_has_weapon" + player_has_weapon);
	}
	//IPrintLn(!can_upgrade+"" + IsDefined( player_has_weapon ));
	if(!can_upgrade && IsDefined( player_has_weapon )){
		self ZHC_set_weapon_hint( cost, ammo_cost, 4500, weapon, undefined, can_init_buy, can_buy_ammo && player_has_weapon, can_buy_ammo && player_has_weapon); //added for mod
	}



	for( ;; )
	{
		self waittill( "trigger", player ); 		
		// if not first time and they have the weapon give ammo
		if(!is_chest && spawns_powerups)	//needed for powerups
			self.weapon_model wall_buy_set_weapon_yaw(player);

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( !player can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}
		
		if( player has_powerup_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		// Allow people to get ammo off the wall for upgraded weapons
		player_has_weapon = player has_weapon_or_upgrade( weapon ); 

		if( !player_has_weapon
		// && !is_grenade
		)
		{
			// else make the weapon show and give it
			if(can_init_buy && player.score >= cost )
			{


				player maps\_zombiemode_score::minus_to_player_score( cost ); 

				bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type weapon",
				player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, weapon, self.origin );

				if ( is_lethal_grenade( weapon ) )
				{	
					player maps\ZHC_zombiemode_weapons::take_weapon(player get_player_lethal_grenade());
					player takeweapon( player get_player_lethal_grenade() );
					player set_player_lethal_grenade( weapon );
				}

				if(is_chest && level.ZHC_MAX_AMMO_SYSTEM && isDefined(player.ZHC_weapons[weapon]))	//if getting weapon from chest && player has gotten weapon before, increase max amm of weapon.
					player maps\ZHC_zombiemode_weapons::upgrade_stock_ammo(weapon);

				player weapon_give( weapon );
				player check_collector_achievement( weapon );

				first_time_triggered = self.first_time_triggered;
				if( self.first_time_triggered == false )
				{
					if(can_buy_ammo && !is_grenade)
					{
						if(!can_upgrade)
						//self weapon_set_first_time_hint( cost, ammo_cost );
							self ZHC_set_weapon_hint( cost, ammo_cost, 4500, weapon, undefined, can_init_buy, can_buy_ammo, can_buy_ammo); //added for mod
					}
					if(!is_chest){
						if(level.ZHC_LOGICAL_WEAPON_SHOW){
							self thread weapon_model_hide( player );
						}else{ 
							self thread show_weapon_model( player ); 
						}
					}
					self.first_time_triggered = true;
				}

				if(is_chest){
					if(level.ZHC_BOX_GUN_BUYABLE_EXPIRE_AFTER_USE)
						self notify("weapon_expired");
					else if(self.ZHC_GUN_STAYS && level.ZHC_BOX_GUN_STAYS_WAIT_GUN_BUYABLE_RESET_EXPIRE_TIMER)
						self notify ("reset_expire_timer", 1);

					chest_weapon_grabbed(!first_time_triggered, weapon);
					if(can_upgrade && level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE){
						if(self.ZHC_WALL_GUN_can_upgrade == true){								//if simply buying gun, wont reset upgrade timer 
																								//(espcially given the fact that we currently have it at stength 1 which skips cooldown entirely)
																								//hence this is important for avoiding an exploit (drop and pick up gun to reset upgrade timer)
							self.ZHC_WALL_GUN_can_upgrade = false;
							if(level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
								self thread wall_upgrade_wait_to_return(is_chest, 0);			//no wait
						}
					}
				}else{
					self notify("weapon_grabbed");//uses same notif as chest does.
					if(level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE)
					{
						if(level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
							self thread wall_weapon_wait_to_return( 1);
						return;
					}else if(can_upgrade && level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE){
						if(self.ZHC_WALL_GUN_can_upgrade == true){	
							self.ZHC_WALL_GUN_can_upgrade = false;
							if(level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
								self thread wall_upgrade_wait_to_return(is_chest, 0);				//no wait
						}
					}else if(can_upgrade && level.ZHC_LOGICAL_WEAPON_SHOW){
						//self thread wall_upgrade_wait_to_return(is_chest, 0);
						self thread show_weapon_model( player ); 
					}
				}
				if(can_upgrade)
					self notify("update_hintstrings");
						
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );
				
			}
		}
		else
		{
			if(
				can_upgrade && is_true(self.ZHC_WALL_GUN_can_upgrade)
			 	&& (isDefined(self.ZHC_weapon_upgrade_lvl) && IsDefined(self.ZHC_weapon_upgrade_cost )) 
			 	&& !(is_grenade || is_placeable_mine( weapon ) || is_equipment( weapon ))
			  )
			{//added for mod

				zhcweapon = maps\ZHC_zombiemode_weapons::weapon_name_check(weapon);

				if(IsDefined( player.ZHC_weapons[zhcweapon])){
					zombweap = zhcweapon;
					if(is_weapon_upgraded(weapon)){
						zombweap = player.ZHC_weapon_other_weapon[player.ZHC_weapons[zhcweapon]];
					}

					//TODO: check if has gotten upgrade from this weapon in this box
					
					//upgrade_cost = maps\ZHC_zombiemode_weapons::get_upgrade_weapon_cost(get_weapon_cost(zombweap),pow);

					if(
						int(player.ZHC_weapon_levels[player.ZHC_weapons[zhcweapon]]) == self.ZHC_weapon_upgrade_lvl - 1 && 
						player.score >= self.ZHC_weapon_upgrade_cost 
					  )
					{
						if( self.first_time_triggered == false )
						{
							if(can_buy_ammo && !is_grenade)
							{
								if(!can_upgrade)
								//self weapon_set_first_time_hint( cost, ammo_cost );
									self ZHC_set_weapon_hint( cost, ammo_cost, 4500, weapon, undefined, can_init_buy, can_buy_ammo && player_has_weapon, can_buy_ammo && player_has_weapon); //added for mod
							}
							if(!is_chest){
								if(level.ZHC_LOGICAL_WEAPON_SHOW){
									self thread weapon_model_hide( player );
								}else{ 
									self thread show_weapon_model( player ); 
								}
							}
							self.first_time_triggered = true;
						}

						//IPrintLn( "zhcweapon: " +zhcweapon );
						player ZHC_upgrade_weapon(zhcweapon, self.origin);
						player maps\ZHC_zombiemode_weapons::refill_weapon_ammo(weapon);

						player maps\_zombiemode_score::minus_to_player_score( self.ZHC_weapon_upgrade_cost );

						bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type ammo",
						player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, self.ZHC_weapon_upgrade_cost, weapon, self.origin );

						self notify("weapon_upgrade_bought");

						if(is_chest){
							if(level.ZHC_BOX_GUN_BUYABLE_EXPIRE_AFTER_USE)
								self notify("weapon_expired");
							else if(self.ZHC_GUN_STAYS && level.ZHC_BOX_GUN_STAYS_WAIT_GUN_BUYABLE_RESET_EXPIRE_TIMER)
								self notify ("reset_expire_timer",self.ZHC_weapon_upgrade_lvl);

							if(level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE )
								chest_weapon_grabbed(true, weapon);
							else if(level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE){
								self.ZHC_WALL_GUN_can_upgrade = false;
								if(level.ZHC_BOX_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
									self thread wall_upgrade_wait_to_return(is_chest,self.ZHC_weapon_upgrade_lvl);
							}

						}else{
							if(level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE)
							{
								if(level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
									self thread wall_weapon_wait_to_return( self.ZHC_weapon_upgrade_lvl);
								return;
							}else if(level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE){
								self.ZHC_WALL_GUN_can_upgrade = false;
								if(level.ZHC_WALL_GUN_UPGRADE_CAN_ONLY_BUY_ONCE_WAIT_TO_RETURN)
									self thread wall_upgrade_wait_to_return(is_chest,self.ZHC_weapon_upgrade_lvl);
							}else if(level.ZHC_LOGICAL_WEAPON_SHOW){
								//self thread wall_upgrade_wait_to_return(is_chest, 0);
								self thread show_weapon_model( player ); 
							}
						}
						
						//if(can_upgrade)
						self notify("update_hintstrings");

						continue;
					}
				}
			}

			if(!can_buy_ammo)
				continue;
			// MM - need to check and see if the player has an upgraded weapon.  If so, the ammo cost is much higher
			if(IsDefined(self.hacked) && self.hacked)	// hacked wall buys have their costs reversed...
			{
				if ( !player has_upgrade( weapon ) )
				{
					ammo_cost = 4500;
				}
				else
				{
					ammo_cost = get_ammo_cost( weapon );
				}
			}
			else
			{
				if ( player has_upgrade( weapon ) )
				{
					ammo_cost = 4500;
				}
				else
				{
					ammo_cost = get_ammo_cost( weapon );
				}
			}
			// if the player does have this then give him ammo.
			if( player.score >= ammo_cost )
			{
				if( self.first_time_triggered == false )
				{
					if(!is_grenade)
					{
						self weapon_set_first_time_hint( cost, ammo_cost );
					}
					if(!level.ZHC_LOGICAL_WEAPON_SHOW){
						if(!is_chest){
							self thread show_weapon_model( player );
						}
						self.first_time_triggered = true;
					}
				}

				player check_collector_achievement( weapon );


				//ammo_given = .... check how gernade varifies ammo given. proabbaly a clip check.

				if(is_grenade){
					max_nades = WeaponMaxAmmo( weapon );
					cur_nades = player getammocount( weapon );
					ammo_given = cur_nades < max_nades;
					player GiveStartAmmo( weapon );
				}else{
					if( player has_upgrade( weapon ) )
					{
						ammo_given = player ammo_give( level.zombie_weapons[ weapon ].upgrade_name, !is_chest);	//dont do zhc check if its a chest that way we can upgrade ammo.
					}
					else
					{
						ammo_given = player ammo_give( weapon, !is_chest ); //dont do zhc check if its a chest that way we can upgrade ammo.
					}
				}

				
				if( ammo_given )
				{
					if(is_chest)
						player maps\ZHC_zombiemode_weapons::upgrade_stock_ammo(weapon);

					if(is_chest){

						if(level.ZHC_BOX_GUN_BUYABLE_EXPIRE_AFTER_USE)
							self notify("weapon_expired");
						else if(self.ZHC_GUN_STAYS && level.ZHC_BOX_GUN_STAYS_WAIT_GUN_BUYABLE_RESET_EXPIRE_TIMER //&&
							//vvv makes it so only happens if player is at lease half way close to buying upgrade, ok but why?
							//(can_upgrade && self.upgrade_cost && self.ZHC_weapon_upgrade_cost > player.score && player.score > self.ZHC_weapon_upgrade_cost/2)
							//vvv makes it so only happens if player is at lease half way close to buying ammo.
							//(ammo_cost > player.score - ammo_cost && player.score - ammo_cost > ammo_cost/2)
						)
							//currently making it so you have to be upgrade in order to work.
							self notify ("reset_expire_timer", 1);
						if(level.ZHC_BOX_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_AMMO)
							chest_weapon_grabbed(true, weapon);
					}else if(level.ZHC_WALL_GUN_BUYABLE_CAN_ONLY_BUY_ONCE_AMMO)
						chest_weapon_grabbed(true, weapon);

					player maps\_zombiemode_score::minus_to_player_score( ammo_cost ); // this give him ammo to early

					bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type ammo",
						player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, ammo_cost, weapon, self.origin );
					
					self notify("weapon_ammo_bought");
				}
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 0 );
			}
		}
	}
}
show_weapon_model(player){
	if(IsDefined( self.weapon_model_dw ))
		self.weapon_model_dw thread weapon_show(player);
	self.weapon_model thread weapon_show(player);
}
weapon_model_hide(player, slow_hide){
	if(IsDefined( self.weapon_model_dw ))
		self.weapon_model_dw thread weapon_hide(player, slow_hide);
	self.weapon_model thread weapon_hide(player, slow_hide);
}
wall_buy_set_weapon_yaw(player){
	player_angles = VectorToAngles( player.origin - self.origin ); 

	player_yaw = player_angles[1]; 
	weapon_yaw = self.angles[1];

	if ( isdefined( self.script_int ) )
	{
		weapon_yaw -= self.script_int;
	}

	yaw_diff = AngleClamp180( player_yaw - weapon_yaw ); 

	if( yaw_diff > 0 )
	{
		yaw = weapon_yaw - 90; 
	}
	else
	{
		yaw = weapon_yaw + 90; 
	}
	self.yaw = yaw;
}
weapon_show( player )
{
	if(!IsDefined( self.yaw )){
		if(!isDefined(player)){
			self Show();
			return;
		}
		self wall_buy_set_weapon_yaw(player);
	}
	if(!isdefined(self.og_origin))
		self.og_origin = self.origin; 

	self.origin = self.origin +( AnglesToForward( ( 0, self.yaw, 0 ) ) * 8 ); 

	wait( 0.05 ); 
	self Show(); 

	play_sound_at_pos( "weapon_show", self.origin, self );

	time = 1; 
	self MoveTo( self.og_origin, time ); 
}

weapon_hide(player, slow_hide){
	if(!IsDefined( self.yaw ) && isDefined(player)){
		self wall_buy_set_weapon_yaw(player);
	}
	if(is_true(slow_hide)){
		if(!isdefined(self.og_origin))
			self.og_origin = self.origin; 
		self Show(); 
		play_sound_at_pos( "weapon_show", self.origin, self );
		time = 1; 
		self MoveTo( self.origin +( AnglesToForward( ( 0, self.yaw, 0 ) ) * 8 ), time );
		wait(time);
		self Hide();
		wait(0.05);
		self.origin = self.og_origin;
	} else
		self Hide();
}

ZHC_wall_buy_get_power_up_spawn_position(){
	yaw = 0;
	if(IsDefined( self.weapon_model ) && IsDefined( self.weapon_model.yaw ))
		yaw = self.weapon_model.yaw;
	return self.origin + ( AnglesToForward( ( 0, yaw, 0)  ) * -35 ) + (0,0,45); 
}
ZHC_wall_buy_get_power_up_drop_position(){
	yaw = 0;
	if(IsDefined( self.weapon_model ) && IsDefined( self.weapon_model.yaw ))
		yaw = self.weapon_model.yaw;
	return self.origin + ( AnglesToForward( ( 0, yaw, 0)  ) * -35 ); 
}
ZHC_wall_buy_manage_power_up_spawn(weapon){
	self endon ("weapon_stop");
	if(!level.ZHC_WEAPONS_KILL_NOTIFY)
		return;
	round_to_reset_kill_goal = define_or(level.next_dog_round,0);
	starting_kills = define_or(level.ZHC_weapon_total_kills[weapon],0);
	kill_goal = starting_kills + min(define_or(level.zombie_total_start,6) + 1, 18);
	IPrintLn("kill_goal " + kill_goal);
	while(1){
		TESTING = false;
		if(TESTING){
			self waittill_any( "weapon_grabbed","weapon_ammo_bought","weapon_upgrade_bought","weapon_stop");	//testo
		}else{
			while(define_or(level.ZHC_weapon_total_kills[weapon],0) < kill_goal){
				level waittill("zhc_"+weapon +"_kill");
				IPrintLn( weapon +" "+(level.ZHC_weapon_total_kills[weapon] - starting_kills) +"/"+ (kill_goal - starting_kills) );
			}
			while(
				//level.zombie_vars["zombie_drop_item"] != 1 || 
				IsDefined( self.ZHC_powerup )
				){
				wait_network_frame();
			}
		}
		level.zombie_vars["zombie_drop_item"] = 0;
		self thread ZHC_cycle_power_ups(maps\ZHC_zombiemode_weapons::GetWeaponPowerupCycle(weapon));
		self thread ZHC_wall_buy_drop_power_up();
		self waittill("stop_zhc_powerup_cycle");
		starting_kills = level.ZHC_weapon_total_kills[weapon];
		if(level.round_number >= round_to_reset_kill_goal)
			kill_goal = starting_kills + min(define_or(level.zombie_total_start,6) + 1, 18);
		else
			kill_goal = starting_kills + int(kill_goal * 1.5);

	}

}
ZHC_wall_buy_drop_power_up(){
	ret = self waittill_any_return( "weapon_grabbed","weapon_ammo_bought","weapon_upgrade_bought","weapon_stop");//common_scripts\utility.gsc: );
	if(!isDefined(ret))
		IPrintLnBold( "ret is not defined" );
	if(!isDefined(ret) || ret == "weapon_stop"){
		self.ZHC_powerup maps\_zombiemode_powerups::powerup_timeout(2.5);
		return;
	}
	self notify ("stop_zhc_powerup_cycle");
	self.ZHC_powerup thread  maps\_zombiemode_powerups::powerup_grab();
	self.ZHC_powerup thread  maps\_zombiemode_powerups::powerup_timeout(60);
	self.ZHC_powerup MoveTo( self ZHC_wall_buy_get_power_up_drop_position(),4,0.2,1);
	self.ZHC_powerup waittill_any( "powerup_grabbed", "powerup_timedout" );
	self.ZHC_powerup = undefined;
}
ZHC_cycle_power_ups(cycle){
	self endon( "stop_zhc_powerup_cycle" );
	self endon( "weapon_stop" );
	index = 0;
	while(1){
		if(!IsDefined( self.ZHC_powerup) || (index == 0 && cycle[0] != cycle[cycle.size-1]) || (cycle.size > 1 && cycle[index] != cycle[index-1]) ){	
			if(IsDefined( self.ZHC_powerup) )
				self.ZHC_powerup maps\_zombiemode_powerups::powerup_timeout(0);//instantly times out powerup
			self.ZHC_powerup = level maps\_zombiemode_powerups::specific_powerup_drop( cycle[index], self ZHC_wall_buy_get_power_up_spawn_position(),false, undefined, false);
		}
		self.ZHC_powerup maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(
		1,//	goals_required, 
		undefined,//	wait_time, 
		undefined,//	additional_kills_wanted, 
		1,//	additional_rounds_to_wait, 
		undefined,//	dog_rounds_to_wait, 
		true,//	round_goals_on_round_end, 
		1//	additional_dog_kills_wanted
		);
		index++;
		if(index >= level.ZHC_wall_buy_powerup_cycle.size)
			index = 0;
	}

}

get_pack_a_punch_weapon_options( weapon )
{
	if ( !isDefined( self.pack_a_punch_weapon_options ) )
	{
		self.pack_a_punch_weapon_options = [];
	}

	if ( !is_weapon_upgraded( weapon ) )
	{
		return self CalcWeaponOptions( 0 );
	}

	if ( isDefined( self.pack_a_punch_weapon_options[weapon] ) )
	{
		return self.pack_a_punch_weapon_options[weapon];
	}

	smiley_face_reticle_index = 21; // smiley face is reserved for the upgraded famas, keep it at the end of the list

	camo_index = 15;
	lens_index = randomIntRange( 0, 6 );
	reticle_index = randomIntRange( 0, smiley_face_reticle_index );
	reticle_color_index = randomIntRange( 0, 6 );

	if ( "famas_upgraded_zm" == weapon )
	{
		reticle_index = smiley_face_reticle_index;
	}
	
/*
/#
	if ( GetDvarInt( #"scr_force_reticle_index" ) )
	{
		reticle_index = GetDvarInt( #"scr_force_reticle_index" );
	}
#/
*/

	scary_eyes_reticle_index = 8; // weapon_reticle_zom_eyes
	purple_reticle_color_index = 3; // 175 0 255
	if ( reticle_index == scary_eyes_reticle_index )
	{
		reticle_color_index = purple_reticle_color_index;
	}
	letter_a_reticle_index = 2; // weapon_reticle_zom_a
	pink_reticle_color_index = 6; // 255 105 180
	if ( reticle_index == letter_a_reticle_index )
	{
		reticle_color_index = pink_reticle_color_index;
	}
	letter_e_reticle_index = 7; // weapon_reticle_zom_e
	green_reticle_color_index = 1; // 0 255 0
	if ( reticle_index == letter_e_reticle_index )
	{
		reticle_color_index = green_reticle_color_index;
	}

	self.pack_a_punch_weapon_options[weapon] = self CalcWeaponOptions( camo_index, lens_index, reticle_index, reticle_color_index );
	return self.pack_a_punch_weapon_options[weapon];
}

weapon_give( weapon, is_upgrade )
{
	primaryWeapons = self GetWeaponsListPrimaries(); 
	current_weapon = undefined;
	////////////////////////////////////ZHC CHANGED FOR MOD
	weapon_limit = level.zhc_starting_weapon_slots;
	if ( self HasPerk( "specialty_additionalprimaryweapon" ) )
	{
		weapon_limit = level.zhc_starting_weapon_slots+1;
		if(level.PERK_LEVELS){
			weapon_limit = level.zhc_starting_weapon_slots + self maps\_zombiemode_perks::GetPerkLevel("specialty_additionalprimaryweapon");
		}
	}
	////////////////////////////////////

	//if is not an upgraded perk purchase
	if( !IsDefined( is_upgrade ) )
	{
		is_upgrade = false;
	}


	// This should never be true for the first time.
	if( primaryWeapons.size >= weapon_limit )
	{
		current_weapon = self getCurrentWeapon(); // get his current weapon

		if ( is_placeable_mine( current_weapon ) || is_equipment( current_weapon ) )
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !is_offhand_weapon( weapon ) )
			{
				if ( issubstr( current_weapon, "knife_ballistic_" ) )
				{
					self notify( "zmb_lost_knife" );
				}
				self maps\ZHC_zombiemode_weapons::take_weapon(current_weapon);
				self TakeWeapon( current_weapon ); 
				unacquire_weapon_toggle( current_weapon );
				if ( current_weapon == "m1911_zm" )
				{
					self.last_pistol_swap = GetTime();
				}
			}
		} 
	}
	
	if( IsDefined( level.zombiemode_offhand_weapon_give_override ) )
	{
		if( self [[ level.zombiemode_offhand_weapon_give_override ]]( weapon ) )
		{
			return;
		}
	}

	if( weapon == "zombie_cymbal_monkey" )
	{
		self maps\_zombiemode_weap_cymbal_monkey::player_give_cymbal_monkey();
		self play_weapon_vo( weapon );
		return;
	}

	self play_sound_on_ent( "purchase" );

	if ( !is_weapon_upgraded( weapon ) )
	{
		self GiveWeapon( weapon );
	}
	else
	{
		self GiveWeapon( weapon, 0, self get_pack_a_punch_weapon_options( weapon ) );
	}
	self maps\ZHC_zombiemode_weapons::give_weapon(weapon);

	acquire_weapon_toggle( weapon, self );
	self GiveStartAmmo( weapon );
	self SwitchToWeapon( weapon );
	 
	self play_weapon_vo(weapon);
}

play_weapon_vo(weapon)
{
	//Added this in for special instances of New characters with differing favorite weapons
	if ( isDefined( level._audio_custom_weapon_check ) )
	{
		type = self [[ level._audio_custom_weapon_check ]]( weapon );
	}
	else
	{
	    type = self weapon_type_check(weapon);
	}
				
	self maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", type );
}

weapon_type_check(weapon)
{
    if( !IsDefined( self.entity_num ) )
        return "crappy";    
    
    switch(self.entity_num)
    {
        case 0:   //DEMPSEY'S FAVORITE WEAPON: M16 UPGRADED: ROTTWEIL72
            if( weapon == "m16_zm" )
                return "favorite";
            else if( weapon == "rottweil72_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 1:   //NIKOLAI'S FAVORITE WEAPON: FNFAL UPGRADED: HK21
            if( weapon == "fnfal_zm" )
                return "favorite";
            else if( weapon == "hk21_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 2:   //TAKEO'S FAVORITE WEAPON: M202 UPGRADED: THUNDERGUN
            if( weapon == "china_lake_zm" )
                return "favorite";
            else if( weapon == "thundergun_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 3:   //RICHTOFEN'S FAVORITE WEAPON: MP40 UPGRADED: CROSSBOW
            if( weapon == "mp40_zm" )
                return "favorite";
            else if( weapon == "crossbow_explosive_upgraded_zm" )
                return "favorite_upgrade";   
            break;                
    }
    
    if( IsSubStr( weapon, "upgraded" ) )
        return "upgrade";
    else
        return level.zombie_weapons[weapon].vox;
}


get_player_index(player)
{
	assert( IsPlayer( player ) );
	assert( IsDefined( player.entity_num ) );
/#
	// used for testing to switch player's VO in-game from devgui
	if( player.entity_num == 0 && GetDvar( #"zombie_player_vo_overwrite" ) != "" )
	{
		new_vo_index = GetDvarInt( #"zombie_player_vo_overwrite" );
		return new_vo_index;
	}
#/
	return player.entity_num;
}

ammo_give( weapon , zhc_max_check_override)
{
	// We assume before calling this function we already checked to see if the player has this weapon...

	// Should we give ammo to the player
	give_ammo = false; 

	// Check to see if ammo belongs to a primary weapon
	if( !is_offhand_weapon( weapon ) )
	{
		if( isdefined( weapon ) )  
		{
			// get the max allowed ammo on the current weapon
			stockMax = 0;	// scope declaration
			stockMax = WeaponStartAmmo( weapon ); 
			if(is_true(zhc_max_check_override) && level.ZHC_MAX_AMMO_SYSTEM){
				stockMax = self.ZHC_weapon_ammos_max[self.ZHC_weapons[weapon]];
			}

			// Get the current weapon clip count
			clipCount = self GetWeaponAmmoClip( weapon ); 

			currStock = self GetAmmoCount( weapon );

			// compare it with the ammo player actually has, if more or equal just dont give the ammo, else do
			if( ( currStock - clipcount ) >= stockMax )	
			{
				give_ammo = false; 
			}
			else
			{
				give_ammo = true; // give the ammo to the player
			}
		}
	}
	else
	{
		// Ammo belongs to secondary weapon
		if( self has_weapon_or_upgrade( weapon ) )
		{
			// Check if the player has less than max stock, if no give ammo
			if( self getammocount( weapon ) < WeaponMaxAmmo( weapon ) )
			{
				// give the ammo to the player
				give_ammo = true; 					
			}
		}		
	}	

	if( give_ammo )
	{
		self play_sound_on_ent( "purchase" ); 
		self GiveStartAmmo( weapon );
// 		if( also_has_upgrade )
// 		{
// 			self GiveMaxAmmo( weapon+"_upgraded" );
// 		}
		return true;
	}

	if( !give_ammo )
	{
		return false;
	}
}

get_upgraded_weapon_model_index(weapon)
{
	/*(if(IsSubStr(level.script, "zombie_cod5_"))
	{
		if(weapon == "tesla_gun_upgraded_zm" || weapon == "mp40_upgraded_zm")
		{
			return 1;
		}
	}*/

	return 0;
}
