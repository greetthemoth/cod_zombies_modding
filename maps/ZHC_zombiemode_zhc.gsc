#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;

get_testing_level(){
	return 0.5;
	//level <0: no debugs
	//level 0.5: extra points
	//level 6 : power on
	//level 7 : common powerups
	//level 8 : only firesales
}
can_send_msg_level(msg_id){
	switch(msg_id){
		case 4: //down forgiveness
		//case 1000: //difficulty testing
		case 1001: //difficulty testing
		case 1002: //zombie limit testing
		case 1005: //dog spawning
		case 555: //perk teleportation testing
		//case 5555: //QR perk teleportation testing
		case 50: //mystery box
		case 100: //wall weapon stuff
		case 200: //powerup stuff
		case 300: //teleporter lightning stuff
		//case 999://round zombie total viewer
		//case 666://zombie damage 
		//case 222://perk loss
		//case 777: //ZHC_weapon system
		case 444: //blockers
		case "m14_zm":
			return true;

		default:
			return false;
	}
}
set_perk_levels_info(){
	level.PERK_LEVELS = true;
	if(level.PERK_LEVELS){
		level.PERK_LEVEL_LIMIT = 99;
		level.ZHC_EXCESS_PERK_LEVEL_LIMIT_PER_PLAYER = 0; //limit number of perks the player can have above level 1.
		level.ZHC_PERK_LEVELS_BUYABLE = true;
		level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER = true;
		level.ZHC_VENDING_PERK_LEVEL_MULTIPLAYER_SYSTEMATIZED = false; //testo  	Makes it so all player must have cur perk level in order to buy next perk level.
	
		if(level.PERK_LEVEL_LIMIT < 10 && level.ZHC_TESTING_LEVEL >= 3)
			level.PERK_LEVEL_LIMIT = 10;
	}
}

init_many_vars(){

	level.special_chest_wait_mode = undefined;
	level.special_chest_waiters = undefined;

	level.dog_round_count = undefined;
	level.total_dogs_killed = 0;

	level.ZHC_quickrevive_cost_forgiveness = undefined;

	level.zhc_last_door_cooldown_round_goal_set = undefined;

	level.haunt_level = undefined;

	level.ZHC_doors_expired_this_round = undefined;
	level.zhc_last_door_cooldown_kill_goal_set = undefined;
}
init(){

	init_many_vars();
	level.DOG_LIGHTNING_TURN_ON_PERK = true;
	level.DOG_ROUND_LAST_DOG_TURN_ON_PERK = false;

	level.ZHC_ZOMBIES_CAN_DROP_POWERUPS = false;



	//maps\ZHC_zombiemode_weapons::init();	//runs in zombiemode_weapons::init()
	maps\ZHC_zombiemode_roundflow::init_roundflow();


	//maps\_zombiemode::register_player_damage_callback(::player_damaged_func);
	//maps\_zombiemode_spawner::register_zombie_damage_callback(::zombie_damage); //Bucha perk, knifed zombies turn into crawlers.

	thread blocker_perk_block_init();
	thread dog_round_counter();
	thread testing_ground();		//testo


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
	}else{
		for ( i = 0; i < players.size; i++ ){
			players[i] maps\_zombiemode_score::add_to_player_score(1500 - 500);
		}
	}
	if(level.ZHC_TESTING_LEVEL >= 0.5){
		if(false){
			while(true){
				spawned = false;

				if(false){	//spawn on player
					zhc_try_spawn_powerup_fall_down("nuke", get_random_player_pos()); 
					spawned = zhc_try_spawn_powerup_dig_up("insta_kill", get_random_player_pos());
				}

				if(true){ //spawn nuke drop down at random dog spawn
					spawned = zhc_try_spawn_powerup_fall_down("nuke",get_random_active_dog_spawn_pos());
				}

				if(spawned)
					wait(10);
				else
					wait(0.5);
			}
		}
		if(false){
			maps\zombie_theater_teleporter::teleporter_init();
			while(true){
				dp = get_random_active_dog_spawn_pos();
				if(isDefined(dp)){
					maps\ZHC_zombie_theater::spawn_lightning_teleport(dp);
					wait(2);
				}
				else
					wait(0.5);
			}
		}
		
	}
	

	/*wait( 1 );
	mac = level.ZHC_perk_machines["specialty_quickrevive"][0];
	mac thread maps\_zombiemode_perks::ZHC_move_perk_machine(mac.origin + (-600,0,0), (0,45,0));
	*/


	/*while(1){
		wait(1);
		maps\_zombiemode_blockers::Get_Players_Current_Zone_Bruteforce( players[0] );
	}*/

	//if(level.ZHC_TESTING_LEVEL > 0)
	//thread drop_powerups_on_players(); 	//testo
	//thread haunt_all_players();
}

get_random_active_dog_spawn_pos(){
	if(!IsDefined( level.enemy_dog_locations )){
		zhcp("no dog locations");
		return;
	}
	if(level.enemy_dog_locations.size == 0 ){
		zhcp("no dog locations");
		return;
	}
	return level.enemy_dog_locations[randomint(level.enemy_dog_locations.size-1)].origin;
}
get_active_dog_spawn_positions(){ //player is close enough to spawn from
	if(!IsDefined( level.enemy_dog_locations )){
		zhcp("no dog locations");
		return;
	}
	if(level.enemy_dog_locations.size == 0 ){
		zhcp("no dog locations");
		return;
	}
	pos = [];
	for( i = 0 ; i<level.enemy_dog_locations.size; i++ ){
		pos[pos.size] = level.enemy_dog_locations[i].origin;
	}
	return array_randomize(level.enemy_dog_locations)[0].origin;
}

get_inactive_dog_spawn_positions(){ //players are too far to spawn from
	pos = [];
	roomKeys = GetArrayKeys(  level.ZHC_room_info);
	for(z = 0; z < roomKeys.size; z++){
		zones =  maps\ZHC_zombiemode_roundflow::Get_Room_Info(roomKeys[z], "zones");
		for(i = 0; i < zones.size; i++){
			zone = level.zones[zones[i]];
			if(zone.is_active)
				continue;
			for(x=0; x<zone.dog_locations.size; x++)
			{
				pos[pos.size] = zone.dog_locations[x].origin;
			}
		}
	}
	return pos;	
}

get_enabled_dog_spawn_positions(){ //spawners have EVER been activated
	pos = [];
	roomKeys = GetArrayKeys(  level.ZHC_room_info);
	for(z = 0; z < roomKeys.size; z++){
		zones =  maps\ZHC_zombiemode_roundflow::Get_Room_Info(roomKeys[z], "zones");
		for(i = 0; i < zones.size; i++){
			zone = level.zones[zones[i]];
			if(!zone.is_enabled)
				continue;
			for(x=0; x<zone.dog_locations.size; x++)
			{
				pos[pos.size] = zone.dog_locations[x].origin;
			}
		}
	}
	return pos;	
}


get_disabled_dog_spawn_positions(){ //spawners have NEVER been activated
	pos = [];
	roomKeys = GetArrayKeys(  level.ZHC_room_info);
	for(z = 0; z < roomKeys.size; z++){
		zones =  maps\ZHC_zombiemode_roundflow::Get_Room_Info(roomKeys[z], "zones");
		for(i = 0; i < zones.size; i++){
			zone = level.zones[zones[i]];
			if(zone.is_enabled)
				continue;
			for(x=0; x<zone.dog_locations.size; x++)
			{
				pos[pos.size] = zone.dog_locations[x].origin;
			}
		}
	}
	return pos;	
}


get_random_dog_spawn_pos_in_room(roomId){
	pos = get_dog_spawn_positions_in_room(roomId);
	return pos[randomint(pos.size-1)];
}
get_dog_spawn_positions_in_room(roomId){
	pos = [];
	zones =  maps\ZHC_zombiemode_roundflow::Get_Room_Info(roomId, "zones");
	for(i = 0; i < zones.size; i++){
		zone = level.zones[zones[i]];
		for(x=0; x<zone.dog_locations.size; x++)
		{
			pos[pos.size] = zone.dog_locations[x].origin;
		}
	}
	return pos;
}
get_random_dog_spawn_pos(){
	pos = get_dog_spawn_positions();
	return pos[randomint(pos.size-1)];
}
get_dog_spawn_positions(){
	pos = [];
	roomKeys = GetArrayKeys(  level.ZHC_room_info);
	for(z = 0; z < roomKeys.size; z++){
		zones =  maps\ZHC_zombiemode_roundflow::Get_Room_Info(roomKeys[z], "zones");
		for(i = 0; i < zones.size; i++){
			zone = level.zones[zones[i]];
			for(x=0; x<zone.dog_locations.size; x++)
			{
				pos[pos.size] = zone.dog_locations[x].origin;
			}
		}
	}
	return pos;	
}
get_random_player_pos(){
	players= get_players();
	if(players.size > 0)
		return array_randomize( players )[0].origin;
}

blocker_perk_block_init(){
	flag_wait( "all_players_connected" );//common_scripts\utility.gsc:
	players = get_players();

	JUG_MOVE_SYSTEM = true;
	if(JUG_MOVE_SYSTEM){
		level.jug_move_score = 0;
	}

	for ( i = 0; i < players.size; i++ ){
		players[i] thread manage_perk_history();
	}
	for( i = 0; i < level.exterior_goals.size; i++ )
	{
		level.exterior_goals[i] thread blocker_wait_to_perk_block();
	}
}
can_move_perk_to_repaired_barrier(perk){
	return!(perk == "specialty_quickrevive" || perk == "specialty_armorvest");
}
can_move_perk_to_random_barrier(perk){
	return perk == "specialty_armorvest";
}
manage_perk_history(){
	self.perk_history = [];
	while(1){	//now managed on give_perk()
		self waittill( "perk_bought", perk);
		self.perk_history = array_remove(self.perk_history, perk);
		self.perk_history[self.perk_history.size] = perk;
		if(IsDefined( level.jug_move_score ) && can_move_perk_to_random_barrier(perk)){
			score_to_add = 1;
			if(level.PERK_LEVELS)
				score_to_add = self maps\_zombiemode_perks::GetPerkLevel(perk) * 4;
			level.jug_move_score += score_to_add;
			if(score_to_add > get_players().size){
				level.jug_move_score = 0;
				level thread move_perk_to_random_barricade(perk);
			}
		}
		//IPrintLn( "perk_history_length:"+perk.size + "  defined_perk:"+isDefined(perk));
	}
}
move_perk_to_random_barricade(perk){
	if(!level.power_on && maps\ZHC_zombiemode_zhc::get_testing_level() <= 1){		
		return;
	}
	if(!IsDefined( perk )){
		zhcpb( "perk undefined"  ,555);
		return;;
	}
	mac = level.ZHC_perk_machines[perk][0];
	mac thread maps\_zombiemode_perks::ZHC_move_perk_machine((0,0,-1000), mac.angles, true);
	mac endon( "perk_machine_start_move" );

	goal = undefined;
	//set goal....
	{
		while(1){
			goal = level.exterior_goals[RandomInt( level.exterior_goals.size )];
			while(!isDefined(goal.ZHC_spawners_that_lead_to_this)){
				zhcp( "waiting to set spawner "+perk+"..." ,555 );
				wait(3); // adds some randomness to when it arrives
			}
			//if(true)
			//	break; //testo no further checks
			is_enabled = false;
			for( i = 0; i < goal.ZHC_spawners_that_lead_to_this.size; i ++){
				if(goal.ZHC_spawners_that_lead_to_this[i].is_enabled)		//prevents using position thats already been occupied
				{
					is_enabled = true;
					break;
				}
			}
			if(!is_enabled){
				zhcp( "waiting to be enabled "+perk+"..." ,555 );
				continue;
			}
			active_spawns = 0;
			for(i = 0; i < level.enemy_spawns.size; i++){
				if(level.enemy_spawns[i].script_noteworthy != "quad_zombie_spawner")//maps\_utility.gsc:
					active_spawns++;
			}
			if(active_spawns <= 1){
				zhcp( "too few spawns "+perk+"..."  ,555);
				continue;
			}else{
				break;
			}
		}
		/*
		unassigned_goals = [];
		active_goals= [];
		inactive_goals= [];
		for( i = 0; i < level.exterior_goals.size; i++ )
		{
			goal = level.exterior_goals[i];
			if(!IsDefined(goal.ZHC_spawners_that_lead_to_this))
				array_add( unassigned_goals, goal );
			else{
				if(goal.ZHC_spawners_that_lead_to_this.is_active){
					array_add( active_goals, goal );
				}else{
					array_add( inactive_goals, goal );
				}
			}
		}
		
		active_spawns = 0;
		for(i = 0; i < level.enemy_spawns.size; i++){
			if(!level.enemy_spawns[i].script_noteworthy == "quad_zombie_spawner" && is_in_array(goal.ZHC_spawners_that_lead_to_this,level.enemy_spawns[i]))//maps\_utility.gsc:
				active_spawns++;
		}	
		if(active_spawns <= 1){
			active_goals = [];
		}

		available_goals = array_combine( active_goals , inactive_goals );
		total_goals = available_goals.size + unassigned_goals.size;

		if(total_goals == 0){
			IPrintLnBold( "no goals" );
			return;
		}
	
		chosen_goal = RandomInt(total_goals); if(chosen_goal <
		available_goals.size){ goal = available_goals[chosen_goal]; }else{ goal =
		unassigned_goals[chosen_goal - available_goals.size]; }*/
	}
	zhcpb( "teleporting "+perk ,555);

	for( i = 0; i < goal.ZHC_spawners_that_lead_to_this.size; i ++){
		goal.ZHC_spawners_that_lead_to_this[i].is_enabled = false;
	}

	
	enemies = GetAISpeciesArray( "axis", "all" ); 
	for( i = 0; i < enemies.size; i++ )
	{
		if ( is_true( enemies[i].ignore_enemy_count ) || ! isDefined( enemies[i].animname )  || ! IsDefined( enemies[i].first_node ))
			continue;

		if(enemies[i].first_node == goal){
			thread maps\_zombiemode_ai_dogs::dog_explode_fx (enemies[i].origin);
			enemies[i] hide();
			enemies[i] DoDamage(enemies[i].health + 100, enemies[i].origin);
			//level.zombie_total ++;
		}
	}

	
	mac thread maps\_zombiemode_perks::ZHC_move_perk_machine(groundpos(goal.origin + (AnglesToForward( goal.angles ) * 15)), goal.angles + (0,90,0), true);

	//mac thread return_perk_mac(); //uses "a door closed"

	mac waittill("perk_machine_start_move" );

	for( i = 0; i < goal.ZHC_spawners_that_lead_to_this.size; i ++){
		goal.ZHC_spawners_that_lead_to_this[i].is_enabled = true;
	}
}
blocker_wait_to_perk_block(){
	while(1){
		//IPrintLnBold( "waiting to repair" );
		self waittill( "no valid boards", player);


		if(!level.power_on && maps\ZHC_zombiemode_zhc::get_testing_level() <= 1){
			zhcpb( "power off" ,555);	
			continue;
		}
		if(!IsDefined( player )){
			zhcpb( "player undefined" ,555);
			continue;
		}
		if(!is_player_valid( player )){
			zhcpb( "player invalid" ,555);
			continue;
		}

		if(!isDefined(self.ZHC_spawners_that_lead_to_this)){
			zhcpb( "spawner list undefined" ,555);
			continue;
		}
		{//check is not already disabled by anouther perk
			isDisabled = false;
			for( i = 0; i < self.ZHC_spawners_that_lead_to_this.size; i ++){
				if(!self.ZHC_spawners_that_lead_to_this[i].is_enabled){		//prevents using position thats already been occupied		
					isDisabled = true;
					break;
				}
			}
			if(isDisabled){
				zhcpb( "spawner is already disabled" ,555);
				continue;
			}
		}
		spawns = level.enemy_spawns.size ;
		for(i = 0; i < level.enemy_spawns.size; i++){
			if(level.enemy_spawns[i].script_noteworthy == "quad_zombie_spawner")
				spawns--;
		}
		if(spawns <= 1){
			zhcpb( "not enough spawns" ,555);
			continue;;
		}
		if(!isDefined(player.perk_history)){
			zhcpb( "player perk_history undefined",555);
			continue;
		}
		perk = undefined;
		mac = undefined;
		limitQRandJug = true;
		for( i = player.perk_history.size-1; i >= 0; i-- ){
			cperk = player.perk_history[i];
			if(limitQRandJug && !can_move_perk_to_repaired_barrier(cperk)){
				zhcp( "perk:" +cperk + " skipped" ,555);
				continue;
			}
			cmac = level.ZHC_perk_machines[cperk][0];
			if(cmac.origin != cmac.original_origin){
				zhcp( "perk:" +cperk + " in use" ,555);
				continue;
			}
			else{
				perk = cperk;
				mac = cmac;
				break;
			}
		}
		if(!IsDefined( perk )){
			zhcpb( "perk undefined" ,555);
			continue;
		}else{
			zhcpb( "perk:" +perk +" moved",555);
		}
		
		if(isDefined(self.ZHC_spawners_that_lead_to_this)){
			for( i = 0; i < self.ZHC_spawners_that_lead_to_this.size; i ++){
				self.ZHC_spawners_that_lead_to_this[i].is_enabled = false;
			}
		}else{
			zhcpb( "spawner list undefined",555 );
		}

		enemies = GetAISpeciesArray( "axis", "all" ); 
		for( i = 0; i < enemies.size; i++ )
		{
			if ( is_true( enemies[i].ignore_enemy_count ) || ! isDefined( enemies[i].animname )  || ! IsDefined( enemies[i].first_node ))
				continue;

			if(enemies[i].first_node == self){
				thread maps\_zombiemode_ai_dogs::dog_explode_fx (enemies[i].origin);
				enemies[i] hide();
				enemies[i] DoDamage(enemies[i].health + 100, enemies[i].origin);
				//level.zombie_total ++;
			}
		}

		mac thread maps\_zombiemode_perks::ZHC_move_perk_machine(groundpos(self.origin + (AnglesToForward( self.angles ) * 15)), self.angles + (0,90,0), true);

		

		mac thread return_perk_mac();

		waittill_any_ents( level,"a_door_closed", mac,"perk_machine_start_move" );

		if(isDefined(self.ZHC_spawners_that_lead_to_this)){
			for( i = 0; i < self.ZHC_spawners_that_lead_to_this.size; i ++){
				self.ZHC_spawners_that_lead_to_this[i].is_enabled = true;
			}
		}else{
			zhcpb( "spawner list undefined" ,555);
		}	
	}	
}

return_perk_mac(){
	level waittill("a_door_closed");
	wait_network_frame();
	self thread maps\_zombiemode_perks::ZHC_move_perk_machine(self.original_origin, self.original_angle, true);
}

//called from maps\_zombiemode.gsc line 5122.
kill( inflictor, attacker, damage, mod, weapon, vdir, sHitLoc, psOffsetTime ){	//damage is negative based on damage.
	//IPrintLn( damage + " damage to inflictor with " + self.health + " hp."); 
	if(IsPlayer( attacker ) && IsDefined( attacker ) && IsAlive( attacker )){
		oneShot1Kill = attacker give1ShotKillBonusPoints(self, mod, damage, sHitLoc);
		attacker addToCollateralPointBonus(mod, weapon, oneShot1Kill);

		//testo
		/*if(define_or(level.ZHC_POWERUP_KILL_NOTIFEES,0) < 2 && !is_true(self.no_powerups)){
			if(define_or(level.ZHC_POWERUP_KILL_NOTIFEES,0) == 1){
				zhc_try_spawn_powerup_dig_up("insta_kill", self.origin);
			}else{
				zhc_try_spawn_powerup_fall_down("nuke", self.origin);
			}
		}*/

		if(define_or(level.ZHC_POWERUP_KILL_NOTIFEES,0) > 0){
			level notify("zhc_zombie_killed_at_pos", self.origin, attacker.origin, (sHitLoc != "head" && sHitLoc != "helmet") );
		}

		if(level.ZHC_WEAPONS_KILL_NOTIFY){
			if(!IsDefined( level.ZHC_weapon_total_kills[weapon] ))
				level.ZHC_weapon_total_kills[weapon] = 0;
			level.ZHC_weapon_total_kills[weapon]++;
			level notify( "zhc_"+weapon +"_kill" );
			if(level.ZHC_WEAPONS_KILL_NOTIFY_PLAYER)
				attacker notify( "zhc_"+weapon +"_kill" );
		}
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

zombie_damage( mod, hit_location, hit_origin, player, amount, weapon ){
	additional_amount = self maps\ZHC_zombiemode_weapons::GetDamageOverride(mod, hit_location, player, amount, weapon);   //zhc_ damage bonus
	new_amount = additional_amount + amount;
	zhcp( "D:"+ amount+ "AD: " + additional_amount +" hp:"+ self.health +"|"+self.maxhealth ,666); 		//health and maxhealth values always clamped to 100 for some reason?
	if(
		self maps\_zombiemode_perks::bucha_func(player,mod,new_amount,player GetCurrentWeapon(),hit_location,false)
		)
		return 0;

	if(level.DOUBLETAP_PHDFLOPPER_INCREASE_DAMAGE){
		additional_amount+= self maps\_zombiemode_perks::double_tap_2_func(mod, hit_location, player, new_amount);
		additional_amount += self maps\_zombiemode_perks::phd_flopper_2_func(mod, hit_location, player, new_amount);
	}
	
	return additional_amount + amount;

	if(additional_amount > 0){
		if(additional_amount > self.health){
			player maps\_zombiemode_score::player_add_points( "death", mod, hit_location, self.isdog );
			self kill( self, player, new_amount, mod, weapon, undefined, hit_location, undefined );	//get collateral points and stuff
			//self DoDamage( additional_amount, player.origin );
			//return false;
		}
		////funcs below deal additional damage.
		self DoDamage( additional_amount, player.origin );
	}
	return false;
}


dog_round_counter(){

	GAIN_PERK_SLOTS_AFTER_DOG_ROUND = true;

	GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS = -1;
	dog_rounds_till_cost_forgiveness = -1;
	//if(!level.QUICKREVIVE_LIMIT_LIVES && level.QUICKREVIVE_SOLO_COST_SOLO_ON && get_players().size == 1){
		GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS = 1;
		dog_rounds_till_cost_forgiveness = 1;
	//}
	if(level.PERK_LEVELS){
		level.INCREASE_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND = level.PERK_LEVEL_LIMIT < 99;
		level.INCREASE_EXCESS_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND = level.ZHC_EXCESS_PERK_LEVEL_LIMIT_PER_PLAYER >= 0;
	}

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

		/*if(IsDefined( level.ZHC_ROOMFLOW_doors_flow_difficulty_to_close_adj ))
			level.ZHC_ROOMFLOW_difficulty_to_close_door = 
				4 +
				clamp(level.dog_round_count/2, 0, 1) + 	//after 2 dog rounds add 1.
				clamp((level.dog_round_count-2)/3, 0, 1) + //after 3 more dog rounds add 1
				clamp((level.dog_round_count-5)/4, 0, 1) + //after 4 more dog rounds add 1
				clamp((level.dog_round_count-9)/5, 0, 1);	//after 5 more dog rounds add 1
		*/

		/*if(IsDefined( level.ZHC_quickrevive_cost_forgiveness ))
			IPrintLnBold( "QR forgiveness "+level.ZHC_quickrevive_cost_forgiveness );
		else
			IPrintLnBold( "QR forgiveness not defined");*/

		if(	!level.QUICKREVIVE_LIMIT_LIVES &&
			GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS > 0){
			dog_rounds_till_cost_forgiveness--;
			if(dog_rounds_till_cost_forgiveness <= 0){
				if(!IsDefined( level.ZHC_quickrevive_cost_forgiveness ))
					level.ZHC_quickrevive_cost_forgiveness = 0;

				starting_forgiveness = level.ZHC_quickrevive_cost_forgiveness;

				level.ZHC_quickrevive_cost_forgiveness = min(level.solo_lives_given, level.ZHC_quickrevive_cost_forgiveness+1);	//reduces the price increase of quickrevive by one level.
				new_price_level = max(0,level.solo_lives_given - level.ZHC_quickrevive_cost_forgiveness); //0 = 500, 1 = 1500, ect
				if(new_price_level < get_players()[0] maps\_zombiemode_perks::GetPerkLevel("specialty_quickrevive") &&
				 level.ZHC_quickrevive_cost_forgiveness > starting_forgiveness )	//probably not needed but just to be sure
					level.ZHC_quickrevive_cost_forgiveness-=1;

				//IPrintLnBold( "QR forgiveness "+level.ZHC_quickrevive_cost_forgiveness );

				//GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS++; //forgivness become rarer as rounds progress.	//moved
				//dog_rounds_till_cost_forgiveness = GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS;

				if(starting_forgiveness != level.ZHC_quickrevive_cost_forgiveness){							//ig player benefit from forgivenes
					level.zombie_perks["specialty_quickrevive"] notify ("update_perk_hintstrings");
					GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS++; //forgivness become rarer as rounds progress. //only happens after the player benefits from forgivenes
					dog_rounds_till_cost_forgiveness = GAIN_QUICKREVIVE_COST_FORGIVENESS_AFTER_X_DOG_ROUNDS;
					zhcpb( "Down Forgiveness. Quickrevive has been made cheaper." ,4);
				}else{
					dog_rounds_till_cost_forgiveness = 1;	//if the player didnt benefit from forgiveness, forgive the next round
				}
			}
		}
		if(level.PERK_LEVELS && level.INCREASE_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND && level.PERK_LEVEL_LIMIT < 99)
			level.PERK_LEVEL_LIMIT++;
		if(level.PERK_LEVELS && level.INCREASE_EXCESS_PERK_LEVEL_LIMIT_AFTER_DOG_ROUND && level.ZHC_EXCESS_PERK_LEVEL_LIMIT_PER_PLAYER < 99)
			level.ZHC_EXCESS_PERK_LEVEL_LIMIT_PER_PLAYER++;

	}
}


haunt_all_players(){
	flag_wait( "all_players_connected" );
	maps\_zombiemode_blockers::haunt_all_players(20);
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

gain_perk_slot_all_players(){
	//IPrintLn( "gained a perk slot" );
	players = get_players();
	for ( i = 0; i < players.size; i++ ){
		players[i] maps\_zombiemode_perks::give_perk_slot();
	}
}







turn_on_nearest_perk(origin, max_distance, wait_time, wait_time_prev){

	if(level.power_on)	// might eventually add to check if perk if off instead. currently no variable exists to see if perk if off.
		return false;

	perk_trigger = GetClosest( origin, GetEntArray( "zombie_vending", "targetname" ) );
	perk = perk_trigger.script_noteworthy;

	if(isDefined(max_distance) && DistanceSquared(  perk_trigger.origin, origin ) > max_distance*max_distance)
		return false;

	if(IsDefined( wait_time_prev ))
		wait(wait_time_prev);

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

pathfinding_kill(){ //called by _zombiemode_spawner slef is the zombie entity
	//if(level.zombie_total > 0) 	//you can kill the last horde via doors but that wont work if zombies are still spawning.
							    //we add this condition to avoid complication with the 
							   	//zombie_spawning while loop [while(level.zombie_total > 0)]
							   	//adds some knowledge-cap, altho its a bit unclear and may unknowingly promote counter productive strategies.
	if(level.zombies_to_ignore_refund > 0){
		level.zombies_to_ignore_refund--;
	}else{
		level.zombie_total = int(min(level.zombie_total_start,level.zombie_total+1));
		level.total_zombies_killed --;
	}
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

//ZHC_powerup stuff
zhc_try_spawn_powerup_fall_down(powerup_name, drop_spot){
	zhcpb(powerup_name + "fall down", 200);
	//starting_depth = 15;
	//max_depth_builduip = 10;
	if(!IsDefined( drop_spot ))
		return false;

	center_pos = drop_spot + (0,0,40);
	ground_pos = groundpos( center_pos );
	{
		
		spawn_point =  ground_pos + (0,0, 330);
		if(DistanceSquared( groundpos(spawn_point), ground_pos ) > 5 )
		{
			zhcpb(powerup_name + "fall down didnt spawn, ceiling too low", 200);
			return false;
		}
		powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", spawn_point );
	}

	level notify("powerup_dropped", powerup);

	if (! IsDefined(powerup) )	{
		zhcpb(powerup_name + "fall down didnt spawn", 200);
		return false;
	}
	powerup maps\_zombiemode_powerups::powerup_setup( powerup_name );
	powerup thread powerup_fall_down ( drop_spot, ground_pos + (0,0,25));
	return true;
}
powerup_timeout_after_inactive(){
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	while(1){
		powerup_timedout_no_flash();
		self waittill ("powerup_reset_inactive");
	}
}
powerup_timedout_no_flash(){
	self endon("stop_powerup_reseting_inactive");
	self endon ("powerup_reset_inactive");
	//self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	wait(26.5);
	zhcp("powerup deleted from inactivity", 200);
	self notify( "powerup_timedout" );
	level.ZHC_POWERUP_KILL_NOTIFEES--;
	if ( isdefined( self.worldgundw ) )
	{
		self.worldgundw delete();
	}
	self delete();
	
	
}
powerup_fall_down( drop_spot, center_pos){
	
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );

	self thread powerup_timeout_after_inactive();
	self thread maps\_zombiemode_powerups::powerup_wobble();

	if(!isDefined(level.ZHC_POWERUP_KILL_NOTIFEES))
		level.ZHC_POWERUP_KILL_NOTIFEES = 0;
	level.ZHC_POWERUP_KILL_NOTIFEES++;
	
	if(false){ //testo
		max_dist = 200;
		kill_goal = 24 * max_dist;
		cur_kills = 0;
		while (cur_kills < kill_goal){
			level waittill("zhc_zombie_killed_at_pos", origin);

			//wait(1);//testo
			//origin = ground_pos;//testo

			dist  = Distance2D( center_pos, origin );
			if(dist < max_dist){
				self notify ("powerup_reset_inactive");
				progress = (max_dist - dist);
				cur_kills = min(kill_goal,progress + cur_kills);
				zhcpb("fall down %"+ ((cur_kills/kill_goal) * 100), 200);
				//targetZ = (ground_pos[2] - starting_depth) + (max_depth_builduip * (cur_kills/kill_goal));
				//powerup MoveZ( targetZ  , abs(targetZ - powerup.origin[2])/100);
			}
		}
	}else{
		wait(5);
	}
	level.ZHC_POWERUP_KILL_NOTIFEES--;
	self notify("stop_powerup_reseting_inactive");
	self notify("powerup_end_wobble");
	

	zhcpb("fall down ready...", 200);

	self thread maps\_zombiemode_powerups::powerup_timeout(10);

	

	//rise_time = abs(targetZ - powerup.origin[2])/100
	self thread wait_to_rotate_down(10-1.5-2);
	self wait_to_drop_powerup(10-1.5, center_pos);
	
	wait(0.3);
	self thread maps\_zombiemode_powerups::powerup_grab();
}

wait_to_rotate_down(wait_time){
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self endon("zhc_stop_wait_to_drop");
	wait(wait_time);
	self RotateTo( (90,90,90) , 2.5, 0.5, 1 );
	return;
}

wait_to_drop_powerup(wait_time, center_pos){
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self endon("zhc_stop_wait_to_drop");
	self thread wait_to_dive_under(center_pos);
	wait(wait_time);
	self MoveTo( center_pos , 1.5 , 0.6, 0);
	wait(1);
	self notify("zhc_stop_dive_wait");
}
wait_to_dive_under(center_pos){
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self endon("zhc_stop_dive_wait");
	players = get_players();
	while(1){
		for( i = 0; i < players.size; i++ ){
			is_diving = define_or(players[i].divetoprone,0) == 1;
			if(is_diving)
				zhcp("player is diving");

			if(
			//player maps\_laststand::player_is_in_laststand() || 
			is_diving 
			&& Distance2D( center_pos, players[i].origin) < 50
			)
			{
				self thread move_powerup_to_player(players[i]);
				self notify("zhc_stop_wait_to_drop");
				return;
			}
		}
		wait_network_frame( );
		wait_network_frame( );
	}
}

move_powerup_to_player(player){
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self RotateTo( (90,90,90) , 0.35, 0, 0 );
	while(1){
		target_pos = groundpos(player.origin + (0,0,40));
		direction =  self.origin - target_pos;
		self MoveTo( self.origin + (direction * 0.1 * 5), 0.1, 0, 0);
		self waittill("movedone");
	}
}


zhc_try_spawn_powerup_dig_up(powerup_name, drop_spot){
	zhcpb(powerup_name + " dig up", 200);
	//starting_depth = 15;
	//max_depth_builduip = 10;
	if(!IsDefined( drop_spot ))
		return false;
	

	center_pos = drop_spot + (0,0,40);
	//ground_pos = groundpos( center_pos );

	powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model",groundpos( center_pos ) - (0,0, 15) );

	level notify("powerup_dropped", powerup);

	if (! IsDefined(powerup) )	{
		zhcpb(powerup_name + "dig up didnt spawn", 200);
		return false;
	}
	powerup maps\_zombiemode_powerups::powerup_setup( powerup_name );
	powerup powerup_dig_up(drop_spot, center_pos);
	return true;
}

powerup_dig_up(drop_spot, center_pos){
	
	self endon ("powerup_timedout");
	self endon( "powerup_grabbed" );
	self endon( "death" );

	
	self thread powerup_timeout_after_inactive();
	self thread maps\_zombiemode_powerups::powerup_wobble();

	if(!isDefined(level.ZHC_POWERUP_KILL_NOTIFEES))
		level.ZHC_POWERUP_KILL_NOTIFEES = 0;
	level.ZHC_POWERUP_KILL_NOTIFEES++;
	
	if(false){ //testo
		max_dist = 200;
		kill_goal = 5 * max_dist;
		cur_kills = 0;

		while (cur_kills < kill_goal){
			level waittill("zhc_zombie_killed_at_pos", origin, player_origin, headshot);

			//wait(1);//testo
			//origin = ground_pos;//testo

			dist  = Distance( center_pos, origin);
			progress = max(0, max_dist - dist);

			player_dist = Distance( player_origin, origin);
			player_progress = max(0, max_dist - max(dist, max_dist/4)); //wont give more than quarter the progress
			if(headshot)
				player_progress *= 2;

			progress = max(player_progress, progress);
			if(progress > 0){
				self notify ("powerup_reset_inactive");
				cur_kills = min(kill_goal,progress + cur_kills);
				zhcpb("dig up %"+ ((cur_kills/kill_goal) * 100), 200);
			}
		}
	}
	zhcpb("dig up ready...", 200);
	self notify("stop_powerup_reseting_inactive");
	self thread maps\_zombiemode_powerups::powerup_timeout(26.5);
	//rise_time = abs(targetZ - powerup.origin[2])/100
	self MoveTo( center_pos  , 1.5 , 0.5, 0.5);
	level.ZHC_POWERUP_KILL_NOTIFEES--;
	wait(0.3);
	self thread maps\_zombiemode_powerups::powerup_grab();
}










//ZHC COOLDOWN WAITS stuff vvv

//self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown_func2(2, 0, 16, 1, 0); //waits for 16 kills and for next round
ZHC_basic_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end, additional_dog_kills_wanted ){
	if(level.ZHC_TESTING_LEVEL > 9){
		if(isDefined(wait_time))
			wait_time = min(5, wait_time);
		if(isDefined(additional_kills_wanted))
			additional_kills_wanted = min(1, additional_kills_wanted);
		if(isDefined(additional_dog_kills_wanted))
			additional_dog_kills_wanted = min(1, additional_dog_kills_wanted);
		if(
			   (isDefined(additional_rounds_to_wait) && additional_rounds_to_wait > 0)
			|| (isDefined(dog_rounds_to_wait) && dog_rounds_to_wait > 0)
		  ){
			additional_kills_wanted = 1;
			additional_rounds_to_wait = undefined;
			dog_rounds_to_wait = undefined;
		}
	}
	if(!isDefined(goals_required))
		goals_required = 1;
	//IPrintLnBold("gr:"+ dstr(goals_required) +" wt:" + dstr(wait_time)+" addkill:" +dstr(additional_kills_wanted)+" addrnd:"+dstr(additional_rounds_to_wait)+" dogrnd:"+dstr(dog_rounds_to_wait) + " adddkills" + dstr(additional_dog_kills_wanted));
	self thread ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end, additional_dog_kills_wanted);
	self waittill( "zhc_end_of_cooldown" );
}

dstr(string){
	if(IsDefined( string ))
		return string;
	else
		return "--";
}

//self maps\ZHC_zombiemode_zhc::ZHC_basic_goal_cooldown(2, 0, 0, 0, 1); //waits for next dog ground
ZHC_basic_goal_cooldown(goals_required_min_1, wait_time, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end, dog_kill_goal){
	if(level.ZHC_TESTING_LEVEL > 9){
		if(isDefined(wait_time))
			wait_time = min(5, wait_time);
		if(isDefined(kill_goal))
			kill_goal = min(level.total_zombies_killed + 1, kill_goal);
		if(isDefined(dog_kill_goal)){
			dog_kill_goal = min(level.total_dogs_killed + 1, dog_kill_goal);
		}
		if(
			   (isDefined(round_goal) && round_goal > level.round_number)
			|| (isDefined(dog_rounds_to_wait) && dog_rounds_to_wait > 0)
		 ){
			kill_goal = level.total_zombies_killed + 1;
			round_goal = 0;
			dog_rounds_to_wait = 0;
		}
	}
	//IPrintLnBold("gr"+ goals_required_min_1 +" wt" + wait_time+" addkill" +kill_goal+" addrnd"+round_goal+" dogrnd"+dog_rounds_to_wait );
	self thread ZHC_fire_threads_goal_cooldown(max(1,goals_required_min_1), wait_time, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end, dog_kill_goal);
	self waittill( "zhc_end_of_cooldown" );
}

//thread maps\ZHC_zombiemode_zhc::ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait);
ZHC_fire_threads_goal_cooldown_func2(goals_required, wait_time, additional_kills_wanted, additional_rounds_to_wait, dog_rounds_to_wait, round_goals_on_round_end, additional_dog_kills_wanted){
//additional kills wanted
	zhc_cooldown_kill_goal = undefined;
	if(isDefined(additional_kills_wanted)){
		zhc_cooldown_kill_goal = level.total_zombies_killed + additional_kills_wanted;
		//IPrintLn("zhc_cooldown_kill_goal: "+ zhc_cooldown_kill_goal );
	}
//additional dog kills wanted
	zhc_cooldown_dog_kill_goal = undefined;
	if(isDefined(additional_dog_kills_wanted)){
		zhc_cooldown_dog_kill_goal = level.total_dogs_killed + additional_dog_kills_wanted;
		//IPrintLn("zhc_cooldown_kill_goal: "+ zhc_cooldown_kill_goal );
	}
//addtional_rounds_to_wait
	zhc_cooldown_round_goal = undefined;
	if(isDefined(additional_rounds_to_wait))
		zhc_cooldown_round_goal = level.round_number + additional_rounds_to_wait;

	self ZHC_fire_threads_goal_cooldown(goals_required, wait_time, zhc_cooldown_kill_goal, zhc_cooldown_round_goal, dog_rounds_to_wait, round_goals_on_round_end,zhc_cooldown_dog_kill_goal);
}

//maps\ZHC_zombiemode_zhc::ZHC_fire_threads_goal_cooldown(goals_required, wait_goal, kill_goal, round_goal, dog_round_goal);
ZHC_fire_threads_goal_cooldown(goals_required, wait_goal, kill_goal, round_goal, dog_rounds_to_wait, round_goals_on_round_end, dog_kill_goal){
	/*WAIT_GOAL_SYSTEM = IsDefined( wait_goal ) && wait_goal > 0;
	KILL_GOAL_SYSTEM = isDefined(kill_goal) && kill_goal > level.total_zombies_killed;
	ROUND_WAIT_SYSTEM = isDefined(round_goal) && round_goal > level.round_number;
	DOG_ROUND_WAIT_SYSTEM = IsDefined( dog_rounds_to_wait ) && dog_rounds_to_wait > 0;
	
	IPrintLnBold( "goals found: " +  (WAIT_GOAL_SYSTEM + KILL_GOAL_SYSTEM + ROUND_WAIT_SYSTEM + DOG_ROUND_WAIT_SYSTEM) + ". goals_required:" + goals_required);*/
	if(!isDefined(level.zhc_cooldown_id)){
		level.zhc_cooldown_id = 0;
	}
	level.zhc_cooldown_id++;
	goal_strings = [];


	if(IsDefined( wait_goal )){
		goal_strings[goal_strings.size] = "zhc_wait_goal_reached_"+level.zhc_cooldown_id;
	}

	if(isDefined(kill_goal)){
		goal_strings[goal_strings.size] = "zhc_kill_goal_reached_"+level.zhc_cooldown_id;
	}

	if(isDefined(round_goal)){
		goal_strings[goal_strings.size] = "zch_round_goal_reached_"+level.zhc_cooldown_id;
	}

	if(IsDefined( dog_rounds_to_wait ) ){
		goal_strings[goal_strings.size] = "zhc_dog_round_goal_reached_"+level.zhc_cooldown_id;
	}

	if(IsDefined( dog_kill_goal ) ){
		goal_strings[goal_strings.size] = "zhc_dog_kill_goal_reached_"+level.zhc_cooldown_id;
	}

	if(isDefined(goals_required )){
		//IPrintLnBold( "goals found: " +  (goal_strings.size) + ". goals_required:" + goals_required);
		goals_required = min(goal_strings.size, goals_required);
		self thread ZHC_wait_for_goals(goals_required, goal_strings); 
	}



	if(IsDefined( wait_goal )){
		self thread wait_goal_cooldown(wait_goal ,level.zhc_cooldown_id);
	}

	if(isDefined(kill_goal)){
		self thread kill_goal_cooldown(kill_goal ,level.zhc_cooldown_id);
	}

	if(isDefined(round_goal)){
		self thread round_wait_cooldown(round_goal, round_goals_on_round_end ,level.zhc_cooldown_id);
	}

	if(IsDefined( dog_rounds_to_wait ) ){
		self thread dog_round_wait_cooldown(dog_rounds_to_wait, round_goals_on_round_end ,level.zhc_cooldown_id);
	}

	if(IsDefined( dog_kill_goal ) ){
		self thread dog_kill_goal_cooldown(dog_kill_goal ,level.zhc_cooldown_id);
	}

}
ZHC_wait_for_goals(goals_required, goal_strings,zhc_cooldown_id){
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

wait_goal_cooldown(wait_time, zhc_cooldown_id){
	self endon("zhc_end_of_cooldown");
	if(wait_time > 0)
		wait(wait_time);
	//IPrintLnBold( "zhc_wait_goal_reached" );
	self notify("zhc_wait_goal_reached_"+zhc_cooldown_id);
}

kill_goal_cooldown(total_kill_goal,zhc_cooldown_id){
	self endon("zhc_end_of_cooldown");
	while(total_kill_goal > level.total_zombies_killed){
		level waittill("zom_kill");
	}
	//IPrintLnBold( "zhc_kill_goal_reached" );
	self notify( "zhc_kill_goal_reached_"+zhc_cooldown_id );
}

round_wait_cooldown(round_goal, round_goals_on_round_end,zhc_cooldown_id){
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
	//if(round_goals_on_round_end)
	//	IPrintLnBold( "round "+ round_goal + " zch_round_goal_reached" );
	self notify ("zch_round_goal_reached_"+zhc_cooldown_id);
}

dog_round_wait_cooldown(dog_rounds_to_wait, round_goals_on_round_end,zhc_cooldown_id){ //if rore then it wil wait for the end of the dog round.
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
	self notify ("zhc_dog_round_goal_reached_"+zhc_cooldown_id);
}

dog_kill_goal_cooldown(total_kill_goal,zhc_cooldown_id){
	self endon("zhc_end_of_cooldown");
	while(total_kill_goal > level.total_dogs_killed){
		//IPrintLnBold( total_kill_goal +"  "+level.total_dogs_killed );
		level waittill("dog_killed");
	}
	//IPrintLnBold( "zhc_dog_kill_goal_reached" );
	self notify( "zhc_dog_kill_goal_reached_"+zhc_cooldown_id );
}

//^^^ ZHC_COOLDOWN Stuff













zombie_door_cost_mult(){
	return 2;
}
normalize_cost(cost){ //added for mod , this function is designed for weapon costs. might move later.

	contestant_vals = [];
	if(cost <= 400)
	contestant_vals[contestant_vals.size] = 50;
	if(cost <= 800)
	contestant_vals[contestant_vals.size] = 100;
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
		contestant_val_dist = min(cost%contestant_val,contestant_val-cost%contestant_val);
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
	//IPrintLn( weapon +"  "+mod +"  "+special);
	if(weapon == "none")
		return;
	explosive_damage = mod == "MOD_GRENADE_SPLASH" || mod == "MOD_PROJECTILE_SPLASH";
	if(!special && !WeaponIsSemiAuto( weapon ) && !explosive_damage )
		return;
	if(isDefined(self.curCollateralKills) && (weapon == self.curCollateralWeapon && mod == self.curCollateralMod)){			//add to current collateral
		self.curCollateralKills ++;
		//if(!isDefined(self.curCollateralMostPointsForKill) || self.curCollateralMostPointsForKill < pointsRewardedForKill)
		//self.curCollateralMostPointsForKill = pointsRewardedForKill;
		//self.curCollateralTotalPoints += pointsRewardedForKill - 10;
	}
	else if(!IsDefined( self.curCollateralWeapon ))					//start new collateral
	{
		self resetCollateralValues(mod, weapon, special);
		self thread giveCollateralKillBonus(true);
		
	}
	else{															//end current collateral and start a new one. (only happens if 2 collaterals in the same frame happen.
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
			reward = 20;	//+20
			peak = 6;


			for( n = 3; n <= self.curCollateralKills //&& n < 8
				; n++){
				i = n % ((peak*2)-1);
				if(i <= peak)
					reward += i * 10;	//+30,+40,+50,+60
				else
					reward += min(peak - (i - peak),2) * 10;	//+50,+40,+30,+20... 
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

		zhcpb("x"+self.curCollateralKills+ " kills +"+reward );
		//IPrintLnBold("curScore"+self.score+  "+"+  reward );

		//self maps\_zombiemode_score::player_add_points( "collateral", reward);
		self maps\_zombiemode_score::player_add_points( "reviver", reward);
	}
	self.curCollateralWeapon = undefined;
	self.curCollateralMod = undefined;
	self.curCollateralKills = undefined;
	//self.curCollateralMostPointsForKill = 0;
	//self.curCollateralTotalPoints = 0;

}
