#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

init(){
	level.ZHC_MAX_AMMO_SYSTEM = true;
	level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT = false;
	level.ZHC_UPGRADE_WEAPON_SYSTEM = true;
	level.ZCH_UPGRADE_FLOW_INTREVAL = -1;
	level.ZHC_CERTAIN_WEAPONS_DONT_REFILL_ON_MAX_AMMO = 1;

	level.ZHC_WEAPONS_KILL_NOTIFY = true;
	if(level.ZHC_WEAPONS_KILL_NOTIFY){
		level.ZHC_WEAPONS_KILL_NOTIFY_PLAYER = false;
		level.ZHC_WEAPONS_KILL_NOTIFY_WEAPON_BUY_DROPS = true;
	}

	thread set_up_weapon_system();
}
set_up_weapon_system(){
	flag_wait( "all_players_connected" );
	players = get_players();
	level.ZHC_disqualified_weapon_names = [];
	for ( i = 0; i < players.size; i++ ){
		players[i] init_weapon_vars();
		players[i] check_primary_ids();
		if(level.ZHC_MAX_AMMO_SYSTEM)
			players[i] thread  manage_player_ammo();
	}
}

GetDamageOverride(mod, hit_location, player, amount, weapon){ //damage to add 

	//IPrintLn( mod +"  "+weapon );
	if(!isDefined(weapon))
		return 0;
	headshot = hit_location == "head";
	weapon_name = weapon_name_check(weapon);
	mult = GetWeaponBalancingDamageMult(weapon_name,mod, headshot);
	//because melee currently doenst have upgrades. melee attacks derive damage upgrades from ballistic knives. 
	if((mod == "MOD_MELEE"  || mod == "MOD_BAYONET") && weapon_name != "knife_ballistic_upgraded_zm")	//exclude melee attacks preformed with upgraded ballistic knife that may potentially have more damage.
		mult *= player get_weapon_upgrade_damage_mult("knife_ballistic_zm");

	//because gerandes currently doenst have upgrades. gernades derive damage upgrades from explosive weapons. 
	else if(mod == "MOD_GRENADE_SPLASH" && weapon_name == "frag_grenade_zm")
		mult *= player get_weapon_upgrade_damage_mult("china_lake_zm") + 
				player get_weapon_upgrade_damage_mult("m72_law_zm") +
				player get_weapon_upgrade_damage_mult("crossbow_explosive_zm");

	else {
		//if(headshot){
		//	mult *= level.ZHC_weapon_damage_mult_headshot[id];
		//else
			mult *= player get_weapon_upgrade_damage_mult(weapon_name);
	}
	return (mult-1)*amount;
}
get_weapon_upgrade_damage_mult(weapon_name){
	id = self.ZHC_weapons[weapon_name];
	if(!isDefined(id))
		return 1;
	return self.ZHC_weapon_damage_mult[id];
}
//weapon balancing vvv
GetWeaponBalancingDamageMult(weapon_name,mod, headshot){
	switch(weapon_name){
		case"dragunov_zm":
			return 1.7;
		case"l96a1_zm":
			return 3.5;
		case"m72_law_zm":
			return 4;
		case"china_lake_zm":
			return 2;
		case"spas_zm":
			return 2.3;
		case"hk21_zm":
			return 1.6;
		case"rpk_zm":
			return 1.4;
		case"rottweil72_zm":
			return 3;
		case"hs10_zm":
			if(headshot)
				return 0.8;
			else
				return 1.75;	//great escape weapon
		case"g11_lps_zm":
			if(headshot)
				return 2.1;
			else
				return 0.65;
		case"m16_zm":
			if(headshot)
				return 1.5;
			else
				return 1;
		case"mp5k_zm":
			if(headshot)
				return 1;
			else
				return 1.3;
		case"galil_zm":
			if(headshot)
				return 1.3;
			else
				return 1.15;
		case"aug_acog_zm":
			if(headshot)
				return 1.08;
			else
				return 0.87;
		default:
			if(weapon_name!="knife_zm" && (mod == "MOD_MELEE"  || mod == "MOD_BAYONET")) //all buyable melee weapons nerfed
				return 0.4;
			return 1;
	}
}
GetWeaponBalancingAmmoStockMult(weapon_name){
	switch(weapon_name){
		case"hk21_zm":
			return 1.65;
		case"rpk_zm":
			return 1.5;
		case"commando_zm":
			return 1.45;
		case"galil_zm":
			return 1.5;
		case"aug_acog_zm":
			return 1.2;
		case"l96a1_zm":
			return 1.5;
		case"m72_law_zm":
			return 1.3;
		case"dragunov_zm":
			return 0.75;
		case"china_lake_zm":
			return 0.5;
		case"g11_lps_zm":
		case"m16_zm":
			return 1.2;
		case"famas_zm":
		case"mpl_zm":
		case"spectre_zm":
			return 1.3;
		case"pm63_zm":
			return 1.2;
		case"mp5k_zm":
		case"ak74u_zm":
		case"mp40_zm":
			return 1.15;
		default:
			return 1;
	}
}
GetWeaponBalancingAmmoClipMult(weapon_name){
	switch(weapon_name){
		case"dragunov_zm":
			return 0.85;
		case"aug_acog_zm":
		case"famas_zm":
		case"mpl_zm":
		case"pm63_zm":
		case"spectre_zm":
		case"mp5k_zm":
			return 1.15;
		case"commando_zm":
			return 1.25;
		default:
			return 1;
	}
}

GetWeaponPowerupCycle(weapon_name){
	if(!isDefined(level.ZHC_wall_buy_powerup_cycle)){
		level.ZHC_wall_buy_powerup_cycle = [];
		level.ZHC_wall_buy_powerup_cycle[level.ZHC_wall_buy_powerup_cycle.size] = "insta_kill";
		level.ZHC_wall_buy_powerup_cycle[level.ZHC_wall_buy_powerup_cycle.size] = "double_points";
		level.ZHC_wall_buy_powerup_cycle[level.ZHC_wall_buy_powerup_cycle.size] = "carpenter";
		level.ZHC_wall_buy_powerup_cycle[level.ZHC_wall_buy_powerup_cycle.size] = "nuke";
	}


	switch(weapon_name){
		case "china_lake_zm":
			cycle = [];
			cycle[cycle.size] = "double_points";
			cycle[cycle.size] = "double_points";
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "carpenter";
			return cycle;
		case "dragunov_zm":
			cycle = [];
			cycle[cycle.size] = "double_points";
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "nuke";
			return cycle;
		case "l96a1_zm":
			cycle = [];
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "double_points";
			cycle[cycle.size] = "double_points";
			cycle[cycle.size] = "double_points";
			return cycle;
		case "crossbow_explosive_zm":
			cycle = [];
			cycle[cycle.size] = "nuke";
			return cycle;
		case "knife_ballistic_zm":
			cycle = [];
			cycle[cycle.size] = "insta_kill";
			return cycle;
		case "g11_lps_zm":
			cycle = [];
			cycle[cycle.size] = "carpenter";
			return cycle;
		case "m72_law_zm":
			cycle = [];
			cycle[cycle.size] = "double_points";
			return cycle;
		case "frag_grenade_zm":
			cycle = [];
			cycle[cycle.size] = "full_ammo";
			return cycle;
		case"spas_zm":
			cycle = [];
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "nuke";
			return cycle;
		case"hk21_zm":
			cycle = [];
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "carpenter";
			return cycle;
		case "cz75dw_zm":
		case"cz75_zm":
			cycle = [];
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "insta_kill";
			cycle[cycle.size] = "full_ammo";
			return cycle;
		case"python_zm":
			cycle = [];
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "carpenter";
			cycle[cycle.size] = "full_ammo";
		default:
			if(maps\_zombiemode_weapons::get_is_wall_buy(weapon_name))
				return array_randomize(level.ZHC_wall_buy_powerup_cycle);
			return array_swap( level.ZHC_wall_buy_powerup_cycle,RandomInt( level.ZHC_wall_buy_powerup_cycle.size ),RandomInt( level.ZHC_wall_buy_powerup_cycle.size ) );
	} 
}
//weapon balancing ^^^


init_weapon_vars()
{
	self.has_better_knife_perk = false;
	self.has_refill_ammo_perk = false;
	self.has_collateral_points_perk = false;
	self.has_1_shot_1_kill_points_perk = false;

	self.ZHC_weapons = [];
	self.ZHC_weapon_names = [];
	self.ZHC_weapon_levels= [];
	self.ZHC_weapon_other_weapon = [];

	self.ZHC_weapon_is_equipment_or_grenade = [];

	if(level.ZHC_MAX_AMMO_SYSTEM){
		self.ZHC_weapon_ammos_max = [];
		self.ZHC_weapon_ammos_max_clip = [];
	}
	self.ZHC_weapon_prev_ammos = [];
	self.ZHC_weapon_prev_ammos_clip = [];

	//DAMAGE
	
	self.ZHC_weapon_damage_mult = [];
	//self.ZHC_weapon_damage_mult_headshot = [];
	//self.ZHC_weapon_damage_add = [];
	//self.ZHC_weapon_damage_percent = [];

	//level manager
}


weapon_name_check(weapon_name){
	if(weapon_name == "knife_ballistic_bowie_zm" || weapon_name == "knife_ballistic_sickle_zm")
		return "knife_ballistic_zm";
	if(weapon_name == "knife_ballistic_bowie_upgraded_zm" || weapon_name == "knife_ballistic_sickle_upgraded_zm")
		return "knife_ballistic_upgraded_zm";
	return weapon_name;
}

add_weapon_info(weapon_name){

	
	for(i = 0; i < level.ZHC_disqualified_weapon_names.size; i++ ){
		if(level.ZHC_disqualified_weapon_names[i] == weapon_name)
			return undefined;
	}

	other_id = undefined;
	ziw_keys = GetArrayKeys( level.zombie_weapons );
	for ( i=0; i<level.zombie_weapons.size; i++ )
	{
		if ( IsDefined(level.zombie_weapons[ ziw_keys[i] ].upgrade_name) && 
		level.zombie_weapons[ ziw_keys[i] ].upgrade_name == weapon_name )
		{
			other_id = check_has_id(ziw_keys[i]);
		}
	}

	if(!isdefined(other_id) && !isdefined (level.zombie_weapons[weapon_name]) ){
		IprintLnBold("weapon " +weapon_name+  " disqualified");
		level.ZHC_disqualified_weapon_names[level.ZHC_disqualified_weapon_names.size] = weapon_name;
		return undefined;
	}

	id = self.ZHC_weapons.size;
	self.ZHC_weapons[weapon_name] = id;
	self.ZHC_weapon_names[id] = weapon_name;
	self.ZHC_weapon_levels[id] = 1;

	self.ZHC_weapon_is_equipment_or_grenade[id] = (is_placeable_mine( weapon_name ) || is_equipment( weapon_name ) || (WeaponType( weapon_name ) == "grenade"));

	if(level.ZHC_MAX_AMMO_SYSTEM && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)){
		self update_max_ammo(weapon_name, id);
	}
	else{
		if(!self.ZHC_weapon_is_equipment_or_grenade[id])
			self.ZHC_weapon_prev_ammos[id] = WeaponMaxAmmo( weapon_name );
		self.ZHC_weapon_prev_ammos_clip[id] = WeaponClipSize( weapon_name );
	}

	self.ZHC_weapon_damage_mult[id] = 1;
	//self.ZHC_weapon_damage_mult_headshot[id] = 1;
	//self.ZHC_weapon_damage_add[id] = 0;
	//self.ZHC_weapon_damage_percent[id] = 0;
	if (IsDefined( other_id ) ){
		self.ZHC_weapon_other_weapon[id] = self.ZHC_weapon_names[other_id];
	}else if(IsDefined( level.zombie_weapons[weapon_name] ) && isDefined(level.zombie_weapons[weapon_name].upgrade_name) ){
		other_id = check_has_id(level.zombie_weapons[weapon_name].upgrade_name );
		if(IsDefined( id ))
			self.ZHC_weapon_other_weapon[id] =  self.ZHC_weapon_names[other_id];
	}

	return id;
}

update_max_ammo(weapon_name, id){
	ammo = WeaponMaxAmmo( weapon_name );
	clip = WeaponClipSize( weapon_name );

	//if(weapon_name == "zombie_cymbal_monkey"){
	//	IPrintLnBold( "monkey is gernade: "+ self.ZHC_weapon_is_equipment_or_grenade[id] + "ammo: " + ammo + "clip: " + clip );
	//}

	//cost = level.zombie_weapons[weapon_name].cost;
	weapon_level = self.ZHC_weapon_levels[id];

	weapon_level_stock_ammo = weapon_level;
	weapon_level_clip_ammo = weapon_level;

	if(IsDefined( self.ZHC_weapon_level_stock_ammos) && IsDefined( self.ZHC_weapon_level_stock_ammos[id] )){
		weapon_level_stock_ammo = self.ZHC_weapon_level_stock_ammos[id];
	}
	if(IsDefined( self.ZHC_weapon_level_clip_ammos) && IsDefined( self.ZHC_weapon_level_clip_ammos[id] )){
		weapon_level_clip_ammo = self.ZHC_weapon_level_clip_ammos[id];
	}



	newAmmo = undefined;
	clipSize = undefined;

	if(!self.ZHC_weapon_is_equipment_or_grenade[id])
	{

		clipSize = clip;
		if(!maps\_zombiemode_weapons::weapon_is_dual_wield(self.ZHC_weapon_names[id]) && !(level.DOUBLETAP_INCREASE_CLIP_SIZE && self maps\_zombiemode_perks::HasThePerk( "specialty_rof" ))) //because dual wield weapons are buggy when adjusting the clip of the second weapon.
		{
			clipPercent = (2+weapon_level_clip_ammo)/6;
			clipPercent *= GetWeaponBalancingAmmoClipMult(weapon_name);

			clipSize = int(clipPercent * clip);
			clipSize += 3;
			clipSize = min(clipSize, clip);
			clipSize = max(clipSize, 1);

			if(clipSize == 7 && clip == 8)
				clipSize = 8;

			clipSize = int(clipSize);

		}

		clipsubdivisions = 1;

		halfClip = int(clipSize/clipsubdivisions);
		if(clip % clipsubdivisions != 0)
			halfClip++;

		clipAmountpercent = (1+weapon_level_stock_ammo)/4;
		clipAmountpercent *= GetWeaponBalancingAmmoStockMult(weapon_name);
		halfclipAmount = int(((clipAmountpercent * ammo) + 3 )/halfClip);

		newAmmo = halfclipAmount * halfClip;
		newAmmo = min(newAmmo, ammo);
		newAmmo = max(newAmmo, 1);

		newAmmo = int(newAmmo);

		self.ZHC_weapon_ammos_max[id] = newAmmo;

		if(!IsDefined( self.ZHC_weapon_prev_ammos[id] ))
			self.ZHC_weapon_prev_ammos[id] = newAmmo;
		
	}else{
		clipSize = int(min(weapon_level, clip));
	}

	self.ZHC_weapon_ammos_max_clip[id] = clipSize;

	if(!IsDefined( self.ZHC_weapon_prev_ammos_clip[id] ))
		self.ZHC_weapon_prev_ammos_clip[id] = clipSize;

	//level.ZHC_WEAPON_MAX_UPGRADE_AMOUNT_ammos_max[id] = Ammo/newAmmo;	
}

check_weapon_ammo(og_weapon_name,weapon_name){	//name should already be checked.
	if(!level.ZHC_MAX_AMMO_SYSTEM)
		return;

	id = self.ZHC_weapons[weapon_name];
	if(!isDefined (id))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)
		return;

	max_ammo = self.ZHC_weapon_ammos_max_clip[id];
	if(self GetWeaponAmmoClip(og_weapon_name) > max_ammo){//reload logic
		toSetTo = self GetWeaponAmmoStock(og_weapon_name) + (self GetWeaponAmmoClip(og_weapon_name) - max_ammo);
		//IprintLnBold(self GetWeaponAmmoStock(weapon_name)+ ": "+max_ammo_1+" + r"+(self GetWeaponAmmoClip(weapon_name) - max_ammo)+" = "+ toSetTo);
		self SetWeaponAmmoStock(og_weapon_name, toSetTo);
		self SetWeaponAmmoClip(og_weapon_name, max_ammo);
	}

	if(self.ZHC_weapon_is_equipment_or_grenade[id])
		return;
		
	max_ammo_1 = self.ZHC_weapon_ammos_max[id];
	if(self GetWeaponAmmoStock(og_weapon_name) > max_ammo_1)
		self SetWeaponAmmoStock(og_weapon_name, max_ammo_1);
}

check_has_id(weapon_name){
	id = self.ZHC_weapons[weapon_name];
	if(!IsDefined( id )){
		return self add_weapon_info(weapon_name);
	}
	else
		return id;
}

take_weapon(weapon_name){//lose weapon
	//IPrintLnBold( weapon_name +" taken" );
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self.ZHC_weapons[weapon_name];
	if(!IsDefined( id ))
		IPrintLnBold( weapon_name +" not ID'ed into ZHC weapon system" );
	else
		self update_prev_ammo(og_weapon_name, id);
}

update_prev_ammo(og_weapon_name, id){
	self.ZHC_weapon_prev_ammos[id] = self GetAmmoCount( og_weapon_name );
	self.ZHC_weapon_prev_ammos_clip[id] = self GetWeaponAmmoClip( og_weapon_name );
}

give_weapon(weapon_name, set_to_prev_ammo){
	//IPrintLnBold( weapon_name+" given " + set_to_prev_ammo );
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	if(is_true(set_to_prev_ammo)){
		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			ammo = self.ZHC_weapon_prev_ammos[id];
			self SetWeaponAmmoStock(og_weapon_name, ammo);
		}
		ammo = self.ZHC_weapon_prev_ammos_clip[id];
		self SetWeaponAmmoClip(og_weapon_name, ammo);
	}

	
	self check_weapon_ammo(og_weapon_name,weapon_name);	//weapon ammo is only for primary weapons.
}

refill_weapon_ammo(weapon_name){
	if(level.ZHC_MAX_AMMO_SYSTEM){
		og_weapon_name = weapon_name;
		weapon_name = weapon_name_check(weapon_name);
		id = self check_has_id(weapon_name);

		if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT){
			self GiveMaxAmmo( weapon_name );
			return;
		}

		if(!IsDefined( id ))
		return;

		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			max_ammo = self.ZHC_weapon_ammos_max[id];
			self SetWeaponAmmoStock(og_weapon_name, max_ammo);
		}else{
			max_grenade_total = int(self.ZHC_weapon_ammos_max_clip[id]);
			self SetWeaponAmmoClip( og_weapon_name, max_grenade_total );
		}	
	}else{
		//self GiveStartAmmo( weapon_name );
		self GiveMaxAmmo( weapon_name );
	}
}

max_ammo_override(weapon_name){ //if false, no override. and carries out as normal.
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);
	if(!IsDefined( id ))
		return false;


	if(level.ZHC_CERTAIN_WEAPONS_DONT_REFILL_ON_MAX_AMMO > -1){
		if (level.ZHC_CERTAIN_WEAPONS_DONT_REFILL_ON_MAX_AMMO >= 0){
			if(weapon_name == "thundergun_zm" || weapon_name == "thundergun_upgraded_zm"){
				return true;
			}																		//
		}
		if(level.ZHC_CERTAIN_WEAPONS_DONT_REFILL_ON_MAX_AMMO >= 1 && weapon_name == "zombie_cymbal_monkey"){ //REALISTIC EQUIPMENT
			//if(level.ZHC_MAX_AMMO_SYSTEM)
				//add_weapon_ammo(weapon_name, 1);												//if we only want to add 1 monkey.
			return true; 																		//for now max ammo wont work at all on monkies.
		}
	}
		
	if(level.ZHC_MAX_AMMO_SYSTEM ){
		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			max_ammo = self.ZHC_weapon_ammos_max[id];
			self SetWeaponAmmoStock(og_weapon_name, max_ammo);
		}else{
			if(!level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)
				return false;
			max_grenade_total = int(self.ZHC_weapon_ammos_max_clip[id]);
			self SetWeaponAmmoClip( og_weapon_name, max_grenade_total );
		}
		return true;	
	}

	return false;
}

add_weapon_ammo(weapon_name, amount){
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self.ZHC_weapons[weapon_name];
	if(!IsDefined( id )){
		if(is_placeable_mine( weapon_name ) || is_equipment( weapon_name ) || (WeaponType( weapon_name ) == "grenade"))
			self SetWeaponAmmoClip(weapon_name, self GetWeaponAmmoClip( weapon_name ) + amount);
		else
			self SetWeaponAmmoStock( weapon_name, self GetWeaponAmmoStock( weapon_name ) + amount);
	}else if(level.ZHC_MAX_AMMO_SYSTEM && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)) {
		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			new_ammo_total = int(min(self GetWeaponAmmoStock( og_weapon_name )+amount, self.ZHC_weapon_ammos_max[id]));
			self SetWeaponAmmoStock(og_weapon_name, new_ammo_total);
		}else{
			new_grenade_total = int(min(self GetWeaponAmmoClip( og_weapon_name )+amount, self.ZHC_weapon_ammos_max_clip[id]));
			self SetWeaponAmmoClip( og_weapon_name, new_grenade_total );
		}
	}else{
		if(self.ZHC_weapon_is_equipment_or_grenade[id])
			self SetWeaponAmmoClip(weapon_name, self GetWeaponAmmoClip( weapon_name ) + amount);
		else
			self SetWeaponAmmoStock( weapon_name, self GetWeaponAmmoStock( weapon_name ) + amount);
	}
}
set_weapon_ammo(weapon_name, amount){
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self.ZHC_weapons[weapon_name];
	if(!IsDefined( id )){
		if( (is_placeable_mine( weapon_name ) || is_equipment( weapon_name ) || (WeaponType( weapon_name ) == "grenade")))
			self SetWeaponAmmoClip(weapon_name, amount);
		else
			self SetWeaponAmmoStock( weapon_name, amount);
	}else if(level.ZHC_MAX_AMMO_SYSTEM  && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)){
		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			new_ammo_total = int(min(amount, self.ZHC_weapon_ammos_max[id]));
			self SetWeaponAmmoStock(og_weapon_name, new_ammo_total);
		}else{
			new_grenade_total = int(min(amount, self.ZHC_weapon_ammos_max_clip[id]));
			self SetWeaponAmmoClip( og_weapon_name, new_grenade_total );
		}	
	}else{
		if(self.ZHC_weapon_is_equipment_or_grenade[id])
			self SetWeaponAmmoClip(weapon_name, amount);
		else
			self SetWeaponAmmoStock( weapon_name, amount);
	}	
}
get_upgrade_weapon_cost(original_cost, cur_lvl){
	upgrade_cost = max(original_cost, 1000);
	for(i = 1; i <= cur_lvl; i++){
		if(i%level.ZCH_UPGRADE_FLOW_INTREVAL == 1)
			upgrade_cost = upgrade_cost * 2;
		else
			upgrade_cost += max(original_cost, 1000*i);
	}
	return int(upgrade_cost);
}

upgrade_weapon(weapon_name, dont_upgrade_other){
	//if(is_placeable_mine( weapon_name ) || is_equipment( weapon_name ) || (WeaponType( weapon_name ) == "grenade"))
	//	return;
	weapon_name = weapon_name_check(weapon_name);
	id = check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	self.ZHC_weapon_levels[id] ++;

	lvl = self.ZHC_weapon_levels[id];

	if(level.ZHC_MAX_AMMO_SYSTEM  && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT) ){
		if(IsDefined( self.ZHC_weapon_level_stock_ammos ) && IsDefined( self.ZHC_weapon_level_stock_ammos[id] ))
			self.ZHC_weapon_level_stock_ammos[id]++;
		if(IsDefined( self.ZHC_weapon_level_clip_ammos )&& IsDefined( self.ZHC_weapon_level_clip_ammos[id] ))
			self.ZHC_weapon_level_clip_ammos[id]++;
		self update_max_ammo(weapon_name, id);
	}

	self.ZHC_weapon_damage_mult[id] = 1 + ((lvl - 1) * 0.7) + ((lvl-1) * (lvl-1) * 0.04) + (  max(0,int((lvl/level.ZCH_UPGRADE_FLOW_INTREVAL) -0.1)) * 2.5) ;
	IPrintLnBold( "upgrade damage mult "+self.ZHC_weapon_damage_mult[id] );
	//self.ZHC_weapon_damage_mult_headshot[id] = ((lvl - 1) * 0.7);
	//self.ZHC_weapon_damage_add[id] = 0;
	//self.ZHC_weapon_damage_percent[id] = 0;

	if(!is_true(dont_upgrade_other)){
		other = self.ZHC_weapon_other_weapon[id];
		if(IsDefined( other ))
			upgrade_weapon(other, true);
	}

	return id;
}
upgrade_stock_ammo(weapon_name){
	if(!level.ZHC_MAX_AMMO_SYSTEM)
		return;
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id]){
		if(level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)
			self upgrade_clip_size(weapon_name);
		return;
	}

	if(!IsDefined( self.ZHC_weapon_level_stock_ammos ))
		self.ZHC_weapon_level_stock_ammos = [];

	if(!IsDefined( self.ZHC_weapon_level_stock_ammos[id] ))
		self.ZHC_weapon_level_stock_ammos[id] = self.ZHC_weapon_levels[id];

	self.ZHC_weapon_level_stock_ammos[id]++;
	update_max_ammo(weapon_name, id);
}
upgrade_clip_size(weapon_name){
	if(level.DOUBLETAP_INCREASE_CLIP_SIZE)
		return;
	if(!level.ZHC_MAX_AMMO_SYSTEM)
		return;
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.ZHC_MAX_AMMO_SYSTEM_EQUIPMENT)
		return;
	
	if(!IsDefined( self.ZHC_weapon_level_clip_ammos ))
		self.ZHC_weapon_level_clip_ammos = [];

	if(!IsDefined( self.ZHC_weapon_level_clip_ammos[id] ))
		self.ZHC_weapon_level_clip_ammos[id] = self.ZHC_weapon_levels[id];

	self.ZHC_weapon_level_clip_ammos[id]++;
	update_max_ammo(weapon_name, id);
}

check_primary_ids(){
	player_weapons = self GetWeaponsList();
	for( i=0; i<player_weapons.size; i++ )
	{
		weapon_name = weapon_name_check(player_weapons[i]);
		self check_has_id(weapon_name);		//checks starting weapons
	}
}

manage_player_ammo(){
	while(1)
	{	
		player_weapons = self GetWeaponsList();
		for( i=0; i<player_weapons.size; i++ )
		{
			weapon_name = weapon_name_check(player_weapons[i]);
			self check_weapon_ammo(player_weapons[i],weapon_name);
		}
		wait .05;
	}
}


