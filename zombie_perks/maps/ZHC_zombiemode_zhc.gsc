#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

get_testing_level(){
	return 1;
	//
	//level 0.5: extra points
	//level 6 : power on
	//level 7 : common powerups
	//level 8 : only firesales
}

init(){

	//level.ZHC_TESTING_LEVEL = 0; //use the function above
	level.MAX_AMMO_SYSTEM = true;
	level.MAX_AMMO_SYSTEM_EQUIPMENT = false;
	level.UPGRADE_WEAPON_SYSTEM = true;
	level.ZCH_UPGRADE_FLOW_INTREVAL = -1;
	level.ZHC_CERTAIN_WEAPONS_DONT_REFILL_ON_MAX_AMMO = 1;

	level.ZHC_ROUND_FLOW = 1; //0 = default| 1 = alternate| 2 = "harder"

	difficulty = 1;
	column = int(difficulty) + 1;

	if(level.ZHC_ROUND_FLOW == 1)
		set_zombie_var( "zombie_health_increase", 			75,	false,	column );
	else if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_increase", 			150,	false,	column );

	if(level.ZHC_ROUND_FLOW == 1)
		set_zombie_var( "zombie_health_increase_multiplier",0.5, 	true,	column );	//	after round 10 multiply the zombies' starting health by this amount
	else if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_increase_multiplier",0.1, 	true,	column );	//	after round 10 multiply the zombies' starting health by this amount

	 if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_start", 				300,	false,	column );	//	starting health of a zombie at round 1

	//maps\_zombiemode::register_player_damage_callback(::player_damaged_func);
	//maps\_zombiemode_spawner::register_zombie_damage_callback(::zombie_damage); //Bucha perk, knifed zombies turn into crawlers.


	thread testing_ground();		//testo

	thread set_up_weapon_system();
	thread dog_round_counter();

	init_quad_zombie_stuff();

}

testing_ground(){
	flag_wait( "all_players_connected" );//common_scripts\utility.gsc:
	wait_network_frame();
	players = get_players();

	if(level.ZHC_TESTING_LEVEL == 10){
		players[0] thread MEGA_carpenter();
	}

	if(level.ZHC_TESTING_LEVEL >= 0.5){
		for ( i = 0; i < players.size; i++ ){
			players[i] maps\_zombiemode_score::add_to_player_score(150000 - 500);
		}
	}



	/*while(1){
		wait(1);
		maps\_zombiemode_blockers::Get_Players_Current_Zone_Bruteforce( players[0] );
	}*/

	//if(level.ZHC_TESTING_LEVEL > 0)
	//thread drop_powerups_on_players(); 	//testo
	//thread haunt_all_players();
}

//called from maps\_zombiemode.gsc line 5122.
kill( inflictor, attacker, damage, mod, weapon, vdir, sHitLoc, psOffsetTime ){	//damage is nagative based on damage.
	//IPrintLn( damage + " damage to inflictor with " + self.health + " hp."); 
	if(IsPlayer( attacker ) && IsDefined( attacker ) && IsAlive( attacker )){
		oneShot1Kill = attacker give1ShotKillBonusPoints(self, mod, damage, sHitLoc);
		attacker addToCollateralPointBonus(mod, weapon, oneShot1Kill);
	}
}
//called from maps\_zombiemode.gsc line 5048.
damage( inflictor, attacker, damage, flags, mod, weapon, vpoint, vdir, sHitLoc, modelIndex, psOffsetTime ){
	if(IsPlayer( attacker ) && IsDefined( attacker ) && IsAlive( attacker )){
		attacker maps\_zombiemode_perks::chamberfill_func(attacker, mod,undefined,false);
		//IPrintLn( mod +"  "+weapon );
		damage = inflictor zombie_damage(mod, sHitLoc, undefined, attacker, damage, weapon);
	}
	return damage;
	//commented out in _zombiemode.gsc.
}

give1ShotKillBonusPoints(target, mod, damage, hit_location){
	if( 
		(////
			//(damage >= target.health && target.health > target.maxhealth*0.75) 
			target.health + damage == target.maxhealth 
			||(!level.mutators["mutator_noPowerups"] && (level.zombie_vars["zombie_insta_kill"] || is_true( self.personal_instakill ))) //should insta kill count?
		)//// 
		&& 
		(mod == "MOD_RIFLE_BULLET" || MOD == "MOD_PISTOL_BULLET")
	  )
	{
		//self maps\_zombiemode_score::player_add_points( "1shot1kill", 20);
		if(hit_location != "head" && hit_location != "helmet")					//doesnt stack with head shot bonus.
			self maps\_zombiemode_score::player_add_points( "reviver", 20);
		return true;
	}
	return false;
}
addToCollateralPointBonus(mod, weapon, special){
	if(weapon == "none")
		return;
	if(!special && !WeaponIsSemiAuto( weapon ))
		return;
	if(isDefined(self.curCollateralKills) && weapon == self.curCollateralWeapon){
		self.curCollateralKills ++;
		//if(!isDefined(self.curCollateralMostPointsForKill) || self.curCollateralMostPointsForKill < pointsRewardedForKill)
		//self.curCollateralMostPointsForKill = pointsRewardedForKill;
		//self.curCollateralTotalPoints += pointsRewardedForKill - 10;
	}
	else if(!IsDefined( self.curCollateralWeapon ))
	{
		self resetCollateralValues(mod, weapon, special);
		self thread giveCollateralKillBonus(true);
		
	}else{
		self giveCollateralKillBonus();
		self resetCollateralValues(mod, weapon, special);
	}
}

resetCollateralValues(mod, weapon, special){
	self.curCollateralMod = mod;
	self.curCollateralWeapon = weapon;
	self.curCollateralKills = 1;
	self.curCollateralSpecial = (special || mod == "MOD_PISTOL_BULLET"  || mod == "MOD_RIFLE_BULLET" );
	//self.curCollateralSpecial = (special || mod == "MOD_PISTOL_BULLET"  || (mod == "MOD_RIFLE_BULLET" && ( player_using_hi_score_weapon( self)));
	//self.curCollateralTotalPoints = pointsRewardedForKill - 10;
}
giveCollateralKillBonus(waitFirst){
	if(is_true(waitFirst))
		wait_network_frame();
	if(self.curCollateralKills > 1)
	{
		reward = 0;
		//additional = 0;
		//if(self.curCollateralSpecial)
		//	additional = 20;
		if(self.curCollateralSpecial)
			reward = self.curCollateralKills*20;
		else{
			reward = 30;
			for( i = 3; i <= self.curCollateralKills && i < 8; i++){
				reward += i * 10;
				//if(self.curCollateralSpecial){
				//	reward += (30 - ((i-2)*10));
				//}
			}
		}
		//you wont get more than double the regular kill points.
		//reward = min(self.curCollateralKills * self.curCollateralTotalPoints, reward);
		//reward = max(reward, 0);
		//reward = min(self.curCollateralKills * self.curCollateralMostPointsForKill, reward);
		//reward = (self.curCollateralKills*self.curCollateralKills*10);
		IPrintLnBold("curScore"+self.score+"  +  "+reward );
		//self maps\_zombiemode_score::player_add_points( "collateral", reward);
		self maps\_zombiemode_score::player_add_points( "reviver", reward);
	}
	self.curCollateralWeapon = undefined;
	self.curCollateralMod = undefined;
	self.curCollateralKills = undefined;
	//self.curCollateralMostPointsForKill = 0;
	//self.curCollateralTotalPoints = 0;

}
zombie_damage( mod, hit_location, hit_origin, player, amount, weapon ){
	additional_amount = self GetDamageOverride(mod, hit_location, player, amount, weapon);   //zhc_ damage bonus
	

	new_amount = additional_amount + amount;

	if(
		self maps\_zombiemode_perks::bucha_func(player,mod,new_amount,player GetCurrentWeapon(),hit_location,false)
		)
		return 0;

	//if(
		additional_amount+= self maps\_zombiemode_perks::double_tap_2_func(mod, hit_location, player, new_amount);
		//)
		//return false;
	//if(
		additional_amount += self maps\_zombiemode_perks::phd_flopper_2_func(mod, hit_location, player, new_amount);
		//)
		//return false;
	//iprintln("ad_"+additional_amount);
	
	return additional_amount + amount;

	if(additional_amount > 0){
		if(additional_amount > self.health){
			player maps\_zombiemode_score::player_add_points( "death", mod, hit_location, self.isdog );
			//self DoDamage( additional_amount, player.origin );
			//return false;
		}
		////funcs below deal additional damage.
		self DoDamage( additional_amount, player.origin );
	}



	return false;
}

/*player_damaged_func( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	return iDamage;
}*/

GetDamageOverride(mod, hit_location, player, amount, weapon){ //damage to add 

	//IPrintLn( mod +"  "+weapon );
	if(!isDefined(weapon))
		return 0;

	weapon_name = weapon_name_check(weapon);
	mult = GetBalancingMult(weapon_name,mod);
	id = player.ZHC_weapons[weapon_name];

	if(!isDefined(id))
		return  (mult-1)*amount;;

	//if(hit_location == "head"){
	//	mult = level.ZHC_weapon_damage_mult_headshot[id];
	//}else{
	mult *= player.ZHC_weapon_damage_mult[id];
	//}

	return (mult-1)*amount;
}

GetBalancingMult(weapon_name,mod){
	switch(weapon_name){
		case"l96a1_zm":
			return 2;
		case"m72_law_zm":
			return 3;
		case"china_lake_zm":
			return 1.5;
		case"spas_zm":
			return 2.3;
		default:
			if(weapon_name!="knife_zm" && mod == "MOD_MELEE") //ll buyable melee weapons nerfed
				return 0.4;
			return 1;
	}

}

set_up_weapon_system(){
	flag_wait( "all_players_connected" );
	players = get_players();
	level.ZHC_disqualified_weapon_names = [];
	for ( i = 0; i < players.size; i++ ){
		players[i] init_weapon_vars();
		players[i] check_primary_ids();
		if(level.MAX_AMMO_SYSTEM)
			players[i] thread  manage_player_ammo();
	}
}

haunt_all_players(){
	flag_wait( "all_players_connected" );
	players = get_players();
	for ( i = 0; i < players.size; i++ ){
		players[i] maps\_zombiemode_blockers::haunt_player(20);
	}
}
drop_powerups_on_players(){
	flag_wait( "all_players_connected" );
	//waittill("between_round_over"  );
	wait( 0.5 );
	//players = get_players();
	//for ( i = 0; i < players.size; i++ ){
		maps\_zombiemode_powerups::start_fire_sale();
	//}
}

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

	if(level.MAX_AMMO_SYSTEM){
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

	if(level.MAX_AMMO_SYSTEM && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.MAX_AMMO_SYSTEM_EQUIPMENT)){
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
		if(!maps\_zombiemode_weapons::weapon_is_dual_wield(self.ZHC_weapon_names[id])) //because dual wield weapons are buggy when adjusting the clip of the second weapon.
		{

			clipPercent = (2+weapon_level_clip_ammo)/6;

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
	if(!level.MAX_AMMO_SYSTEM)
		return;

	id = self.ZHC_weapons[weapon_name];
	if(!isDefined (id))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.MAX_AMMO_SYSTEM_EQUIPMENT)
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
	if(level.MAX_AMMO_SYSTEM){
		og_weapon_name = weapon_name;
		weapon_name = weapon_name_check(weapon_name);
		id = self check_has_id(weapon_name);

		if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.MAX_AMMO_SYSTEM_EQUIPMENT){
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
			//if(level.MAX_AMMO_SYSTEM)
				//add_weapon_ammo(weapon_name, 1);												//if we only want to add 1 monkey.
			return true; 																		//for now max ammo wont work at all on monkies.
		}
	}
		
	if(level.MAX_AMMO_SYSTEM ){
		if (!self.ZHC_weapon_is_equipment_or_grenade[id]){
			max_ammo = self.ZHC_weapon_ammos_max[id];
			self SetWeaponAmmoStock(og_weapon_name, max_ammo);
		}else{
			if(!level.MAX_AMMO_SYSTEM_EQUIPMENT)
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
	}else if(level.MAX_AMMO_SYSTEM && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.MAX_AMMO_SYSTEM_EQUIPMENT)) {
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
	}else if(level.MAX_AMMO_SYSTEM  && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.MAX_AMMO_SYSTEM_EQUIPMENT)){
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

	if(level.MAX_AMMO_SYSTEM  && (!self.ZHC_weapon_is_equipment_or_grenade[id] || level.MAX_AMMO_SYSTEM_EQUIPMENT) ){
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
	if(!level.MAX_AMMO_SYSTEM)
		return;
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id]){
		if(level.MAX_AMMO_SYSTEM_EQUIPMENT)
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
	if(!level.MAX_AMMO_SYSTEM)
		return;
	og_weapon_name = weapon_name;
	weapon_name = weapon_name_check(weapon_name);
	id = self check_has_id(weapon_name);

	if(!IsDefined( id ))
		return;

	if(self.ZHC_weapon_is_equipment_or_grenade[id] && !level.MAX_AMMO_SYSTEM_EQUIPMENT)
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

dog_round_counter(){

	GAIN_PERK_SLOTS_AFTER_DOG_ROUND = true;
	INCREASE_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND = true;

	//TURN_ON_PERK_AFTER_DOG_ROUND = true;

	while(1){
		while(1){
			level waittill( "end_of_round" );
			if(level.ZHC_TESTING_LEVEL >= 4 || flag("dog_round"))
				break;
		}
		//dog round happened
		
		level notify ("zhc_dog_round_over");
		if(GAIN_PERK_SLOTS_AFTER_DOG_ROUND)
			gain_perk_slot_all_players();
		if(INCREASE_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND)
			level.PERK_LEVEL_LIMIT++;


	}
}


gain_perk_slot_all_players(){
	//IPrintLn( "gained a perk slot" );
	players = get_players();
	for ( i = 0; i < players.size; i++ ){
		players[i] maps\_zombiemode_perks::give_perk_slot();
	}
}

turn_on_nearest_perk(origin, max_distance, wait_time){

	if(level.power_on)	// might eventually add to check if perk if off instead. currently no variable exists to see if perk if off.
		return false;

	perk_trigger = GetClosest( origin, GetEntArray( "zombie_vending", "targetname" ) );
	perk = perk_trigger.script_noteworthy;

	if(isDefined(max_distance) && DistanceSquared(  perk_trigger.origin, origin ) > max_distance*max_distance)
		return false;

	level notify( perk + "_on");

	if(!IsDefined( wait_time ))
		return true;

	level endon ("electricity_on");
	level endon( perk+"_on" );

	wait(wait_time);

	level notify( perk + "_off");

	level waittill( perk+"_power_off" );

	playfx(level._effect["poltergeist"], perk_trigger.origin);

	return true;
}


zombie_door_cost_mult(){
	return 10/3;
}

/////////////////////////////ROUND STUFF //////////////////////
ZHC_get_dog_max_add(){
	if(level.ZHC_ROUND_FLOW == 1){
		//level.dog_round_count in this context always includes the current round.
		/*IPrintLnBold( "dog max add: "
			+  ((level.dog_round_count-1)*0.5) + " + "
			+  "("+int(level.zombie_total <= level.zombie_total_start/2) + " * " 
			+   (0.5 * (level.dog_round_count-1) ) + ")"
			+  " - 0.5"

			+ " = " + 
				(((level.dog_round_count-1)*0.5) + 
					(
						int(level.zombie_total <= level.zombie_total_start/2) // 0 to 1 when half of total dogs are killed
						* (0.5 + (level.dog_round_count-1) * 0.5 ) //more 
					) 
				- 1)
		);*/
		return ((level.dog_round_count-1)*0.5) + 
			(
				int(level.zombie_total <= level.zombie_total_start/2) // 0 to 1 when half of total dogs are killed
				* (0.5 * (level.dog_round_count-1) ) //more 
			) 
		- 1;
	}
	return 0;
}
ZHC_get_dog_wait_mult(enemy_count, num_player_valid){
	if(level.ZHC_ROUND_FLOW == 1){
		enemy_count /= max(1,num_player_valid);
		difficulty_mult = (((100 - min(level.round_number,100) )/100)*0.7) + 0.3;
		return min(12,enemy_count *enemy_count)*difficulty_mult;
	}
	return 1;
}
ZHC_spawn_dog_override(enemy_count){				//note: dogs are only able to spawn in other zones that are not occupied. 
	if(level.ZHC_ROUND_FLOW == 1 ){
		if(level.ZHC_dogs_to_spawn_this_round > level.ZHC_dogs_spawned_this_round){

			left_to_spawn = level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_round;

			//dogs_spawned_percent = level.ZHC_dogs_spawned_this_round/level.ZHC_dogs_to_spawn_this_round;	//0-1 as dogs are spawned
			//cur_round_percent = (level.zombie_total_start - (level.zombie_total + enemy_count) )/level.zombie_total_start;	//0-1 as round continues
			//interprolated_round_progression = interpolate(cur_round_percent, 0.1, 0.9); //can be negative or greater than one. 1 - 0 when round_percent is between 1.0 and 0.9.
			//percent_pass = interprolated_round_progression > dogs_spawned_percent;

			spawn_dog_percent = (level.ZHC_dogs_spawned_this_round + 1)/(level.ZHC_dogs_to_spawn_this_round+1);	// if 0 dogs spawned and 1 dog to spawn its 1/2. so it will spawn the dog at 1/5 the round is done. 
			cur_round_percent = (level.zombie_total_start - (level.zombie_total + enemy_count + 24) )/level.zombie_total_start;	//1-0 as round continues	//adding 24 makes it so the last dog spawns when there are 24 zombies left..
			percent_pass = cur_round_percent > spawn_dog_percent;

			if( percent_pass  || randomInt( int((level.zombie_total_start/left_to_spawn) * 1.5) ) == 1 ){
				to_spawn = int( min( left_to_spawn, max( 1, randomInt(level.dog_round_count-1) ) ) );
				IPrintLn( "spawning " + to_spawn + " dog/s..." );
				return to_spawn;
			}else{
				return 0;
			}
		}else{
			return 0;
		}
	}
	return undefined;
}
interpolate(value, minimum, maximum){
   return (value - minimum) / (maximum - minimum);
}

ZHC_get_cur_enemy_limit(enemyCount){ // MOD FUNC
	spawns = level.enemy_spawns.size ;
	for(i = 0; i < level.enemy_spawns.size; i++){
		if(level.enemy_spawns[i].script_noteworthy == "quad_zombie_spawner")
			spawns--;
	}

	limit = 8 + (spawns*0.5) + (level.round_number*0.25) + (spawns * level.round_number* 0.125);
	limit *= get_zombie_limit_mult();
	zombie_total = level.zombie_total + enemyCount;

	if(zombie_total <= level.zombie_total_start/2){
		bonus_percent = 1 - ((zombie_total/2)/(level.zombie_total_start/2));
		limit += 5 * bonus_percent;
		limit += spawns * 0.5 * bonus_percent;
	}

	if(limit > level.zombie_ai_limit)
		limit = level.zombie_ai_limit;

	//IPrintLnBold("zhc_limit: "+ limit + " allSpawns: + " | level.enemy_spawns.size + " | zombie onlySpawns:" + spawns);
	return limit;
}

get_spawning_speed_mult(enemyCount, cur_enemy_limit){		//more time is easier
	if(level.ZHC_ROUND_FLOW == 1){
		if(!IsDefined( level.ZHC_round_spawning_speed_mult ))
			return 1;
		return level.ZHC_round_spawning_speed_mult
			* ((1*(enemyCount/cur_enemy_limit))+0.5)	//turns current spawn percentage into a value between 0.5 - 1.5
			* (1.2 - int(level.zombie_total <= level.zombie_total_start/2)*0.4);	// if half of round has spawned change speed form 1.2 - 0.8
	}
	return 1;
}
get_zombie_limit_mult(){
	if(level.ZHC_ROUND_FLOW == 1){
		if(!IsDefined( level.ZHC_round_zombie_limit_mult ))
			return 1;
		return level.ZHC_round_zombie_limit_mult;
	}
	return 1;
}
get_score_to_drop_powerup_mult(){
	if(level.ZHC_ROUND_FLOW==1){
		if(!IsDefined( level.ZHC_score_to_drop_powerup_mult) )
			return 1;
		return level.ZHC_score_to_drop_powerup_mult;
	}
	return 1;
}

additional_round_logic(){
	if(level.ZHC_ROUND_FLOW == 1){
		update_round_flow_difficulty(1);
	}

}

update_round_flow_difficulty(round_completion_percent){

	fr = level.round_number - (level.dog_round_count-1); //flow round number - excludes dog rounds 

	FLOW_ROUND_LENGTH = 4;
	flow_difficulty = ((fr-1) % FLOW_ROUND_LENGTH);						 //fluctuates from 0 -> FLOW_ROUND_LENGTH-1 based on stage in FLOW_ROUND_LENGTH
	flow_difficulty_percent = flow_difficulty/(FLOW_ROUND_LENGTH-1);		 //fluctuates from 0 -> 1 based on stage in FLOW_ROUND_LENGTH
	inverse_flow_difficulty_percent = ((FLOW_ROUND_LENGTH-flow_difficulty)/FLOW_ROUND_LENGTH); //fructuates from 1 -> 0 based on stage in FLOW_ROUND_LENGTH.
	flows_completed = int((fr-1) / FLOW_ROUND_LENGTH);


	IPrintLnBold( "flow_difficulty: " + flow_difficulty );
			//    (   (((1                 -1) - 10) , 0)) /10; == 0
			//    (   (((10                -1) - 10) , 0)) /10; == 0.9
	dampener = abs(min(((level.round_number-1) - 10) , 0)) /10; //fluctuates from 1 - 0 from (r1 to r11)


	damp25 =  abs(min(((level.round_number-1) - 25) , 0)) /25; //fluctuates from 1 - 0 from (r1 to r25)

	mult_go_to_health_instead = 0.3 * damp25 * flow_difficulty_percent; //

	//IPrintLnBold( "flow_diffic:" + flow_difficulty + " damp10:"+ int(dampener*100)/100 + " damp25:" + int(damp25*100)/100 + " mgtH:" + int(mult_go_to_health_instead*100)/100 );

	//spawning speed
	diminished_IFD = (0.5 * flow_difficulty_percent * damp25) + 1;	//fluctuares between 1 and 1.5. effect deminishes until round 25.
	//diminished_IFD = (0.3 * inverse_flow_difficulty_percent * dampner) + (1 - 0.3 * dampner);	// == 1 when dampner is 0. 
																								// == (ifdp * 0.3)+0.7 when dampener is 1. 
																									//(ifdp * 0.3)+0.7 fluctuates between 1 - 0.5 as the FLOW_ROUND_LENGTH progresses
	level.ZHC_round_spawning_speed_mult = diminished_IFD * (1+mult_go_to_health_instead);
	////IPrintLn( "ZHC_round_spawning_speed_mult: "+level.ZHC_round_spawning_speed_mult);

	//zombie total
	diminished_dampner = ((dampener * 0.4)+(1 - 0.4));



	ZHC_round_zombie_total_mult = (flow_difficulty_percent * 0.5 *  diminished_dampner) +1;
	level.zombie_total = int(level.zombie_total * ZHC_round_zombie_total_mult);
	
	//level.zombie_total = level.round_number; //testo
	//level.zombie_total = 1;//testo

	////IPrintLn( "ZHC_round_zombie_total: "+level.zombie_total);
	level.ZHC_score_to_drop_powerup_mult = ZHC_round_zombie_total_mult;


	//zombie limit
	diminished_dampner = ((dampener * 0.5)+(1 - 0.5));
	level.ZHC_round_zombie_limit_mult = (flow_difficulty * 0.5 * diminished_dampner)+1;
	////IPrintLn( "ZHC_round_zombie_limit_mult: "+level.ZHC_round_zombie_limit_mult);

	
	FLOW2_ROUND_LENGTH = FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH;
	flow2_difficulty = ((fr-1)%FLOW2_ROUND_LENGTH)/FLOW_ROUND_LENGTH; //0-(FLOW_ROUND_LENGTH-1) based on as fr goes from 1 - 16. this repeats every 16 rounds. 16 = (FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)
	flows2_completed = int((fr-1)/FLOW2_ROUND_LENGTH);		//the number of time 16 rounds were reached
	
	//zombie health
	animSpeed = 
		1 +
		//min((fr-1)*0.25,1) +
		(flow_difficulty)+
		(flows_completed*0.05) + 
		(flow2_difficulty)  						//from 0 - 2 based on FLOW2_ROUND_LENGTH difficulty.
		;

	IPrintLn( "1 +" );
	IPrintLn( "min((fr-1)*0.25,1) =" + min((fr-1)*0.25,1) +"+" );
	IPrintLn( "(flow_difficulty*0.4) = "+ (flow_difficulty*0.4)+ "+" );
	IPrintLn( "(flows_completed*0.08) = "+(flows_completed*0.08)+"+" );
	IPrintLn( "(flow2_difficulty * 0.55) = " + (flow2_difficulty * 0.55) +"+" );
	IPrintLn( "flows2_completed*(FLOW_ROUND_LENGTH*0.75) = "+flows2_completed*(FLOW_ROUND_LENGTH*0.75)+"+" );
	IPrintLn("animSpeed = " + animSpeed );

	//animSpeed *= (1-mult_go_to_health_instead);
	//IPrintLn( "pre_zombie_health: "+level.zombie_health);

	// undo the health gain on the zombies.

	if(level.round_number > 1 && flow_difficulty == 0){					//permanatly adds more health every new FLOW_ROUND_LENGTH
		level.zombie_health = int(level.zombie_health * ((FLOW_ROUND_LENGTH*0.1) + 1));
		//level.zombie_health += FLOW_ROUND_LENGTH * 40;
		//animSpeed  =  max(animSpeed - (FLOW_ROUND_LENGTH-1.5), flows_completed * 1.75) ;
	}

	//make weaker FLOW_ROUND_LENGTH rounds have proportinally stronger zombies. expirimental
	if(isDefined(level.zhc_zombie_health_mult))
		level.zombie_health = int((1/level.zhc_zombie_health_mult)*level.zombie_health); // undo previous mult;
	level.zhc_zombie_health_mult = 1;
	//level.zhc_zombie_health_mult *= min(fr-1,9) * 0.1;
	level.zhc_zombie_health_mult *= (  inverse_flow_difficulty_percent  *3* min((flows_completed*0.333),3) )  +1; 
	level.zhc_zombie_health_mult *= 1 + mult_go_to_health_instead;
	level.zombie_health = int(level.zhc_zombie_health_mult * level.zombie_health);

	////IPrintLn( "post_zombie_health: "+level.zombie_health);

	//zombie movement speed
	
	level.zombie_move_speed = int(animSpeed * level.zombie_vars["zombie_move_speed_multiplier"]); //0-40 = walk, 41-70 = run, 71+ = sprint
	


	level.ZHC_zombie_move_speed_spike_chance = int( 10 + (flow2_difficulty * FLOW_ROUND_LENGTH) + min(flows_completed*1.5,15) );
	level.ZHC_zombie_move_speed_spike = 10 +
		int(level.zombie_move_speed * (
			1 +
			(flow_difficulty*0.5/FLOW_ROUND_LENGTH) //[0 - 1]
			+
			(flow2_difficulty*0.35/FLOW_ROUND_LENGTH)//[0 - 1]
			+ 
			flows_completed * 0.1
		));




	IPrintLnBold( "zombie_move_speed: "+level.zombie_move_speed +"   spike "+ level.ZHC_zombie_move_speed_spike +"    chance "+level.ZHC_zombie_move_speed_spike_chance+"%");
	


	dog_left_to_spawn_from_previous_round = 0;
	if(isDefined(level.ZHC_dogs_spawned_this_round) && IsDefined( level.ZHC_dogs_to_spawn_this_round )){
		dog_left_to_spawn_from_previous_round = int(max(0,level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_round));
	}
	
	level.ZHC_dogs_to_spawn_this_round = 
	int(	
		(flows2_completed*2) + //ads a small but base amount of dogs per rounds.
			(inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) *  
			min(level.zombie_total/36, ( int(flows_completed > 0) * level.dog_round_count )*1.5) *
			max(1+(flows2_completed * 0.25), 2)
	   ) 
	+ dog_left_to_spawn_from_previous_round;																	//dogs not spawnwed from previous rounds are added to this round.

	level.mixed_rounds_enabled =  int(level.ZHC_dogs_to_spawn_this_round > 0) && level.dog_round_count-1 > 0;	//can only spawns dogs after dog round. 

	level.ZHC_dogs_spawned_this_round = 0;

	////IPrintLnBold("dog_round_count: "+level.dog_round_count + "  ZHC_dogs_to_spawn_this_round: "+ level.ZHC_dogs_to_spawn_this_round + "  mixed_rounds_enabled: " +level.mixed_rounds_enabled );
	
	/*IPrintLnBold( 
		"dogs_to_be_spawned = " + (fr/(FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)) + " + " + (inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) + " * " + (level.zombie_total/36 + (level.dog_round_count-1)*1.5)
		+ " = " +(	
			(fr/(FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)) + //ads a small but base amount of dogs per rounds.
			(inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) *  
			(level.zombie_total/36 + (level.dog_round_count-1)*1.5)
	   ) + " to int-> " + level.ZHC_dogs_to_spawn_this_round
	 );*/	

}

pathfinding_kill(){ //called by _zombiemode_spawner slef is the zombie entity
	//if(level.zombie_total > 0) 	//you can kill the last horde via doors but that wont work if zombies are still spawning.
							    //we add this condition to avoid complication with the 
							   	//zombie_spawning while loop [while(level.zombie_total > 0)]
							   	//adds some knowledge-cap, altho its a bit unclear and may unknowingly promote counter productive strategies.
		level.zombie_total++;
	//IPrintLnBold( "pf kill" +" zt:"+ level.zombie_total);
	self DoDamage( self.health + 10, self.origin );
}



init_quad_zombie_stuff(){
	level.ZHC_quad_prespawn_original = level.quad_prespawn;
	level.quad_prespawn = ::ZHC_quad_prespawn;
}
ZHC_quad_prespawn(){
	if(isDefined(level.ZHC_quad_prespawn_original))
		self thread [[level.ZHC_quad_prespawn_original]]();
	self.death_gas_time = 60;
}
MEGA_nuke(){
		//ends round
		//turn off power
	//make zombies slow for 5 rounds.
	//make zombies have more hp for 5 rounds.
	//make zombies rounds have less zombies.
	//all effects reduce after each round.

}

MEGA_carpenter(){
	self endon("zhc_mega_carpenter_over");
	//no more zombies spawn for this round.
	//Perma bars nearest barrier.
	//bars all doors. 
	
	min_distance = 1000;
	min_distance_to_avoid_switching_between_barriers = 500; //used to reduce checks
	current_barrier = undefined;
	current_barrier_trigger_pos = undefined;		//we are assuming barriers arent moving around. bad assumption???


	while(1)
	{
		wait(1);
		closest_distance = min_distance * min_distance; //min distance;
		closest_barrier = undefined;
		closest_trigger_location = undefined;


		if(isDefined(current_barrier)){
			dist = DistanceSquared(self.origin, current_barrier_trigger_pos );
			if(dist < min_distance_to_avoid_switching_between_barriers * min_distance_to_avoid_switching_between_barriers){
				continue;
			}
		}

		for( i = 0; i < level.exterior_goals.size; i++ )
		{
			cself = level.exterior_goals[i];
			if( IsDefined( cself.trigger_location ) ) // this is current_barrier_trigger_pos
				trigger_location = cself.trigger_location.origin; // trigger_location is the new name for exterior_goal targets -- which is auto1 in all cases
			else
				trigger_location = cself.origin; // if it is not defined then just use self as the trigger_location
			dist = DistanceSquared( self.origin,trigger_location );
			if(dist < closest_distance){
				closest_distance = dist;
				closest_barrier = cself;
				closest_trigger_location = trigger_location;
			}
		}

		if(		IsDefined( current_barrier ) &&
			 	(	!isDefined(closest_barrier) ||
		  			(closest_barrier != current_barrier)
		  	 	)
		  )
			current_barrier end_mega_carpenter();

		//if( (!isDefined(closest_barrier) && IsDefined( current_barrier )) ||
		//	(isDefined(closest_barrier) && IsDefined( current_barrier ) &&  closest_barrier != current_barrier)
		// ) {


			current_barrier = closest_barrier;
			current_barrier_trigger_pos = closest_trigger_location;
			if(IsDefined( current_barrier ))
				current_barrier thread start_mega_carpenter(self);
		//}
	}
}

start_mega_carpenter(player_to_reward){
	self endon("end_mega_carpenter_for_barrier");
	self.self_repair = true;

	if(!isDefined(self.repair_overrlap)){
		self.repair_overrlap = 1;
	}else{
		self.repair_overrlap ++;		//maybe make the barrier repair faster if multiple people. probly no point in it tho..
	}

	if(isDefined (self.trigger) ){
		self.trigger notify("trigger", player_to_reward);
	}
	self waittill("zhc_mega_carpenter_over");
	self end_mega_carpenter();
}

end_mega_carpenter(){
	if(IsDefined( self.repair_overrlap ))
		self.repair_overrlap--;
	if(!IsDefined( self.repair_over ) ||  self.repair_overrlap <= 0){
		self.self_repair = undefined;
		self notify( "end_mega_carpenter_for_barrier" );
	}
}

MEGA_instakill(){
	//
}



Nuke_Upgrade(){
	//Resistant to explosions and fall damage.
	//Small explosion when you dophin dive or take fall damage.
}

Nuke_Upgrade_2(){
	//Nuke the world at low health
	//Lost after use.
}




Carpenter_Instakill_Upgrade(){
	//repairing kills zombies behind barrier.
}
Carpenter_MaxAmmo_Upgrade(){
	//Reloading repairs 
}
Carpenter_Nuke_Upgrade(){
	//Lock all doors, end round.
}
Carpenter_Double_Points(){
	//Repair 2 barriers at once.
}
Carpenter_Perk_Bottle(){
	//Get Carpenter Perk
	//automaticlly repair closest barrier
}


Instakill_upgrade(){
	//Headshots instakill.
}











//GENERAL WAITS

//self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(2, 0, 16, 1, 0); //waits for 16 kills and for next round
ZHC_basic_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end){
	if(level.ZHC_TESTING_LEVEL > 9){
		if(isDefined(wait_time))
			wait_time = min(5, wait_time);
		if(isDefined(additional_kills_wanted))
			additional_kills_wanted = min(1, additional_kills_wanted);
		if(
			   (isDefined(additional_rounds_to_wait) && additional_rounds_to_wait > 0)
			|| (isDefined(dog_rounds_to_wait) && dog_rounds_to_wait > 0)
		  ){
			additional_kills_wanted = 1;
			additional_rounds_to_wait = undefined;
			dog_rounds_to_wait = undefined;
		}
	}
	IPrintLnBold("gr:"+ dstr(goals_required) +" wt:" + dstr(wait_time)+" addkill:" +dstr(additional_kills_wanted)+" addrnd:"+dstr(additional_rounds_to_wait)+" dogrnd:"+dstr(dog_rounds_to_wait));
	self thread ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end);
	self waittill( "zhc_end_of_cooldown" );
}

dstr(string){
	if(IsDefined( string ))
		return string;
	else
		return "--";
}

//self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown(2, 0, 0, 0, 1); //waits for next dog ground
ZHC_basic_goal_cooldown(goals_required_min_1, wait_time, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end){
	if(level.ZHC_TESTING_LEVEL > 9){
		if(isDefined(wait_time))
			wait_time = min(5, wait_time);
		if(isDefined(kill_goal))
			kill_goal = min(level.total_zombies_killed + 1, kill_goal);
		if(
			   (isDefined(round_goal) && round_goal > level.round_number)
			|| (isDefined(dog_rounds_to_wait) && dog_rounds_to_wait > 0)
		  ){
			kill_goal = level.total_zombies_killed + 1;
			round_goal = 0;
			dog_rounds_to_wait = 0;
		}
	}
	if(!isDefined(goals_required_min_1))
		goals_required_min_1 = 1;
	//IPrintLnBold("gr"+ goals_required_min_1 +" wt" + wait_time+" addkill" +kill_goal+" addrnd"+round_goal+" dogrnd"+dog_rounds_to_wait );
	self thread ZHC_fire_threads_goal_cooldown(max(1,goals_required_min_1), wait_time, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end);
	self waittill( "zhc_end_of_cooldown" );
}

//thread maps\ZHC_zombiemode_zhc::ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait);
ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end){

//additional kills wanted
	zhc_cooldown_kill_goal = undefined;
	if(isDefined(additional_kills_wanted)){
		zhc_cooldown_kill_goal = level.total_zombies_killed + additional_kills_wanted;
		//IPrintLn("zhc_cooldown_kill_goal: "+ zhc_cooldown_kill_goal );
	}
//addtional_rounds_to_wait
	zhc_cooldown_round_goal = undefined;
	if(isDefined(additional_rounds_to_wait))
		zhc_cooldown_round_goal = level.round_number + additional_rounds_to_wait;

	self ZHC_fire_threads_goal_cooldown(goals_required, wait_time, zhc_cooldown_kill_goal, zhc_cooldown_round_goal, dog_rounds_to_wait, round_goals_on_round_end);
}

//maps\ZHC_zombiemode_zhc::ZHC_fire_threads_goal_cooldown(goals_required, wait_goal, kill_goal, round_goal, dog_round_goal);
ZHC_fire_threads_goal_cooldown(goals_required, wait_goal, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end){
	/*WAIT_GOAL_SYSTEM = IsDefined( wait_goal ) && wait_goal > 0;
	KILL_GOAL_SYSTEM = isDefined(kill_goal) && kill_goal > level.total_zombies_killed;
	ROUND_WAIT_SYSTEM = isDefined(round_goal) && round_goal > level.round_number;
	DOG_ROUND_WAIT_SYSTEM = IsDefined( dog_rounds_to_wait ) && dog_rounds_to_wait > 0;
	
	IPrintLnBold( "goals found: " +  (WAIT_GOAL_SYSTEM + KILL_GOAL_SYSTEM + ROUND_WAIT_SYSTEM + DOG_ROUND_WAIT_SYSTEM) + ". goals_required:" + goals_required);*/


	goal_strings = [];


	if(IsDefined( wait_goal )){
		goal_strings[goal_strings.size] = "zhc_wait_goal_reached";
	}

	if(isDefined(kill_goal)){
		goal_strings[goal_strings.size] = "zhc_kill_goal_reached";
	}

	if(isDefined(round_goal)){
		goal_strings[goal_strings.size] = "zch_round_goal_reached";
	}

	if(IsDefined( dog_rounds_to_wait ) ){
		goal_strings[goal_strings.size] = "zhc_dog_round_goal_reached";
	}

	if(isDefined(goals_required )){
		//IPrintLnBold( "goals found: " +  (goal_strings.size) + ". goals_required:" + goals_required);
		goals_required = min(goal_strings.size, goals_required);
		self thread ZHC_wait_for_goals(goals_required, goal_strings); 
	}



	if(IsDefined( wait_goal )){
		self thread wait_goal_cooldown(wait_goal);
	}

	if(isDefined(kill_goal)){
		self thread kill_goal_cooldown(kill_goal);
	}

	if(isDefined(round_goal)){
		self thread round_wait_cooldown(round_goal, round_goals_on_round_end);
	}

	if(IsDefined( dog_rounds_to_wait ) ){
		self thread dog_round_wait_cooldown(dog_rounds_to_wait, round_goals_on_round_end);
	}

}
ZHC_wait_for_goals(goals_required, goal_strings){
	self endon( "zhc_end_of_cooldown" );
	for(i = 0; i < goals_required; i++){
		
		self zhc_waittill_any(goal_strings);//common_scripts\utility.gsc: );
	}
	//IPrintLnBold( "cooldown over. " + goals_required + " goals reached");
	self notify ("zhc_end_of_cooldown");
}

zhc_waittill_any(msgs){
	//self endon("death");
	defined_string = undefined;
	for(i = 0; i < msgs.size; i++){
		if ( IsDefined( msgs[i] ) ){
			if(!IsDefined( defined_string ))
				defined_string = msgs[i];
			else
				self endon( msgs[i] );
		}
	}
	if(IsDefined( defined_string ))
	self waittill(defined_string);
}

wait_goal_cooldown(wait_time){
	self endon("zhc_end_of_cooldown");
	if(wait_time > 0)
		wait(wait_time);
	//IPrintLnBold( "zhc_wait_goal_reached" );
	self notify("zhc_wait_goal_reached");
}

kill_goal_cooldown(total_kill_goal){
	self endon("zhc_end_of_cooldown");
	while(total_kill_goal > level.total_zombies_killed){
		level waittill("zom_kill");
	}
	//IPrintLnBold( "zhc_kill_goal_reached" );
	self notify( "zhc_kill_goal_reached" );
}

round_wait_cooldown(round_goal, round_goals_on_round_end){
	self endon("zhc_end_of_cooldown");

	if(!IsDefined( round_goals_on_round_end ))
		round_goals_on_round_end = false;

	if(round_goals_on_round_end && round_goal > level.round_number)
		level waittill( "end_of_round" );

	while(round_goal - int(round_goals_on_round_end) > level.round_number){
	//while(round_goal > level.round_number){
		if(round_goals_on_round_end)
			level waittill( "end_of_round" );
		else
			level waittill("between_round_over");

	}
	if(round_goals_on_round_end)
		IPrintLnBold( "round "+ round_goal + " zch_round_goal_reached" );
	self notify ("zch_round_goal_reached");
}

dog_round_wait_cooldown(dog_rounds_to_wait, round_goals_on_round_end){ //if rore then it wil wait for the end of the dog round.
	self endon("zhc_end_of_cooldown");
	if(!IsDefined( round_goals_on_round_end ))
		round_goals_on_round_end = false;

	for(i = 0; i < dog_rounds_to_wait; i++){
		if(round_goals_on_round_end){
			level waittill( "end_of_round" );
		}
		while(!flag("dog_round")){
			if(round_goals_on_round_end)
				level waittill( "end_of_round" );
			else
				level waittill("between_round_over");
		}
	}
	//IPrintLnBold( "zhc_dog_round_goal_reached" );
	self notify ("zhc_dog_round_goal_reached");
}

normalize_cost(cost){ //added for mod , this function is designed for weapon costs. might move later.

	contestant_vals = [];
	if(cost <= 400)
	contestant_vals[contestant_vals.size] = 50;
	if(cost <= 800)
	contestant_vals[contestant_vals.size] = 100;s
	if(cost % 1000 < 299 && cost <= 2500)
	contestant_vals[contestant_vals.size] = 200;
	if(cost <= 2000)
	contestant_vals[contestant_vals.size] = 250;
	if(cost <= 2000)
	contestant_vals[contestant_vals.size] = 400;
	if(cost <= 5000)
	contestant_vals[contestant_vals.size] = 500;
	if(cost <= 12000)
	contestant_vals[contestant_vals.size] = 1000;
	if(cost <= 15000)
	contestant_vals[contestant_vals.size] = 2500;
	if(cost <= 50000)
	contestant_vals[contestant_vals.size] = 4000;
	if(cost <= 80000)
	contestant_vals[contestant_vals.size] = 5000;
	contestant_vals[contestant_vals.size] = 10000;

	val = contestant_vals[0];
	closest_val = val;
	closest_val_dist = min(cost%val,val-cost%val);
	for( i = 0; i < contestant_vals.size; i++ ){
		contestant_val = contestant_vals[i];
		contestant_val_dist = min(cost%contestant_val,val-cost%contestant_val);
		if(contestant_val_dist < closest_val_dist){
			closest_val = contestant_val;
			closest_val_dist = contestant_val_dist;
		}
	}
	val = closest_val;

	if(cost % val != 0){
		cost = cost + val;
		cost -= cost % val;
	}
	cost = int(cost);
	return cost;
}
