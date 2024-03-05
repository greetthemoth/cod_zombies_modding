#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;

init(){
	level.ZHC_round_spawning_speed_mult = undefined;
	level.ZHC_score_to_drop_powerup_mult = undefined;
	level.ZHC_round_zombie_limit_mult = undefined;
	level.zhc_zombie_health_mult = undefined;

	level.ZHC_zombie_move_speed_spike = undefined;
	level.ZHC_zombie_move_speed_spike_chance = undefined;
	level.ZHC_zombie_move_speed_spike_queue = undefined;

	level.ZHC_dogs_spawned_this_mixed_round = undefined;
	level.ZHC_dogs_to_spawn_this_round = undefined;

	level.zombies_to_ignore_refund = 0;

	level.ZHC_ROOMFLOW_doors_flow_difficulty_to_close_adj = undefined;
	
	level.ZHC_ROOMFLOW = true;
	level.ZHC_ROOMFLOW_FIRST_ROOM_HARDER = false;//testo
	level.ZHC_ROUND_FLOW = 1; //0 = default| 1 = alternate| 2 = "harder"

	if(ZHC_ROUND_FLOW_check())
		level.mixed_rounds_enabled = false;	//so it resets when game restarts

	//difficulty = 1;
	//column = int(difficulty) + 1;

	/*		//doesnt work. use mp/zombiemode.csv to change variables.
	if(level.ZHC_ROUND_FLOW == 1)
		set_zombie_var( "zombie_health_increase", 			75,	false,	column );
	else if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_increase", 			150,	false,	column );

	if(level.ZHC_ROUND_FLOW == 1)
		set_zombie_var( "zombie_health_increase_multiplier",0.075, 	true,	column );	//	after round 10 multiply the zombies' starting health by this amount
	else if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_increase_multiplier",0.1, 	true,	column );	//	after round 10 multiply the zombies' starting health by this amount

	if(level.ZHC_ROUND_FLOW == 2)
		set_zombie_var( "zombie_health_start", 				300,	false,	column );	//	starting health of a zombie at round 1
	*/
	
	thread rooms_init();
}
debug_room_zones(roomId){
	s_1 = "room"+roomId+" zones are ";
	for(i = 0; i < level.ZHC_room_info[roomId]["zones"].size; i++){
		s_1 += level.ZHC_room_info[roomId]["zones"][i] +" ";
	}
	IPrintLnBold( s_1 );
}
rooms_init(){
	level waittill( "zone_info_updated" );
	level.ZHC_room_info = [];
	if(level.ZHC_ROOMFLOW){
		level.ZHC_round_zombie_limit_mult = 1;
		level.ZHC_round_spawning_speed_mult = 1;
	}
	keys = GetArrayKeys( level.zones );
	for(i = 0; i < keys.size;i++){
		roomId = maps\_zombiemode_blockers::Get_Zone_Room_ID(keys[i]);
		if(!isDefined(level.ZHC_room_info[roomId])){
			level.ZHC_room_info[roomId] = [];
			level.ZHC_room_info[roomId]["name"] = maps\_zombiemode_blockers::map_get_room_name(roomId);
			level.ZHC_room_info[roomId]["doors"] = maps\_zombiemode_blockers::map_get_doors_accesible_in_room(roomId);
			level.ZHC_room_info[roomId]["occupied"] = false;
			level.ZHC_room_info[roomId]["chests"] = [];
			level.ZHC_room_info[roomId]["enemy_count"] = 0;
			//level.ZHC_room_info[roomId]["wall_buys"] = 
			//level.ZHC_room_info[roomId]["spawners"] = 
			if(level.ZHC_ROOMFLOW){
				level.ZHC_room_info[roomId]["zones"] = [];
				level.ZHC_room_info[roomId]["zones"][0] = keys[i];
				level thread room_think(roomId);
			}
		}else if(level.ZHC_ROOMFLOW){
			level.ZHC_room_info[roomId]["zones"][level.ZHC_room_info[roomId]["zones"].size] = keys[i];
		}
	}
	level thread maps\_zombiemode_blockers::map_wait_to_update_rooms();
	if(level.ZHC_ROOMFLOW)
		level thread manage_room_activity();

}
first_room_harder(){
	//first room is hard.

	level.zombie_total = 24;
	thread first_room_harder__wait_till_first_room_inactive_to_reduce_zombie_total();
	start_round_zombie_limit_mult = 2;
	start_round_spawning_speed_mult = 0.5;
	level notify("zhc_update_flow_difficulty_roomId_"+0, 10);
	level.ZHC_round_zombie_limit_mult *= start_round_zombie_limit_mult; //applies its effect on the global mult;
	level.ZHC_round_spawning_speed_mult *= start_round_spawning_speed_mult;
	level waittill( "end_of_round" );
	level notify("zhc_update_flow_difficulty_roomId_"+0, -11);
	level.ZHC_round_zombie_limit_mult /= start_round_spawning_speed_mult; //undoes its effect on the global mult;
	level.ZHC_round_spawning_speed_mult /= start_round_spawning_speed_mult;
}
first_room_harder__wait_till_first_room_inactive_to_reduce_zombie_total(){
	level endon( "end_of_round" );	//only happens in the first round.
	while(level.ZHC_room_info[0]["active"] == true){
		wait_network_frame( );
	}
	level.zombies_to_ignore_refund = level.ZHC_room_info[0]["enemy_count"];
	level.zombie_total = int(min(level.zombie_total, 6));
}

room_think(roomId){
	level endon ("room_stop_"+roomId);
	level.ZHC_room_info[roomId]["flow_difficulty"] = 0;
	level.ZHC_room_info[roomId]["active"] = false;
	level.ZHC_room_info[roomId]["last_round_active"] = 0;

	level.ZHC_room_info[roomId]["room_zombie_limit_mult"] = 1;
	level.ZHC_room_info[roomId]["room_spawning_speed_mult"] = 1;
	difficulty_change = false;
	while(1){
		difficulty = level.ZHC_room_info[roomId]["flow_difficulty"];
		data = update_room_difficulty(difficulty, roomId, false);//difficulty_change && level.ZHC_room_info[roomId]["active"]);
		active = level.ZHC_room_info[roomId]["active"];
		if(active){
			level.ZHC_round_zombie_limit_mult /= level.ZHC_room_info[roomId]["room_zombie_limit_mult"]; //undoes its effect on the global mult;
			level.ZHC_round_spawning_speed_mult /= level.ZHC_room_info[roomId]["room_spawning_speed_mult"];
		}
		level.ZHC_room_info[roomId]["room_zombie_limit_mult"] = data["room_zombie_limit_mult"];
		level.ZHC_room_info[roomId]["room_spawning_speed_mult"] = data["room_spawning_speed_mult"];
		if(active){
			level.ZHC_round_zombie_limit_mult *= level.ZHC_room_info[roomId]["room_zombie_limit_mult"]; //applies its effect on the global mult;
			level.ZHC_round_spawning_speed_mult *= level.ZHC_room_info[roomId]["room_spawning_speed_mult"];
			IPrintLn(level.ZHC_room_info[roomId]["name"] + "  zombie_limit_mult:"+level.ZHC_round_zombie_limit_mult +"  spawning_speed_mult:" +level.ZHC_round_spawning_speed_mult);
		}

		level.ZHC_room_info[roomId]["zombie_health"] = int(level.zombie_health * data["room_zombie_health_mult"]);
		//if(active) IPrintLn(level.ZHC_room_info[roomId]["name"] + " zombie_health:"+level.ZHC_room_info[roomId]["zombie_health"]);

		level.ZHC_room_info[roomId]["zombie_move_speed"] = data["zombie_move_speed"];
		//if(active) IPrintLn(level.ZHC_room_info[roomId]["name"] + " zombie_move_speed:"+level.ZHC_room_info[roomId]["zombie_move_speed"]);

		level.ZHC_room_info[roomId]["zombie_move_speed_spike"] = data["zombie_move_speed_spike"];
		level.ZHC_room_info[roomId]["zombie_move_speed_spike_chance"] = data["zombie_move_speed_spike_chance"];

		level.ZHC_room_info[roomId]["room_dog_spawn_mult"] = data["room_dog_spawn_mult"];

		level thread room_wait_to_increase_difficulty(roomId, difficulty);
		level waittill("zhc_update_flow_difficulty_roomId_"+roomId, difficulty_adj);
		
		if(IsDefined( difficulty_adj )){
			prev_dif = level.ZHC_room_info[roomId]["flow_difficulty"];
			new_dif = max(0,prev_dif+difficulty_adj);
			level.ZHC_room_info[roomId]["flow_difficulty"] = new_dif;
			difficulty_change = prev_dif != new_dif;
			//if(difficulty_change) IPrintLn(level.ZHC_room_info[roomId]["name"] + " flow_difficulty:"+ level.ZHC_room_info[roomId]["flow_difficulty"] +"  active:" + level.ZHC_room_info[roomId]["active"] );
		}
	}
}
room_wait_to_increase_difficulty(roomId, difficulty){
	level endon ("room_stop_"+roomId);
	level endon ("zhc_update_flow_difficulty_roomId_"+roomId);
	if(level.zombie_total == 0){
		level waittill( "start_of_round" );
		wait_network_frame( );
		//waits for level.zombie_total to be set to the new round
	}
	kill_goal = level.total_zombies_killed + 24;//(18 * (1 + difficulty) ) ;
	//if(roomId == 0)iprintln("level.total_zombies_killed: "+level.total_zombies_killed+"->" +  kill_goal+"  active:" + level.ZHC_room_info[roomId]["active"]);
	while(!level.ZHC_room_info[roomId]["active"] || level.total_zombies_killed < kill_goal){
		level waittill( "zom_kill" );
		//wait_network_frame( );
		//if(level.ZHC_room_info[roomId]["active"])\
		//if(roomId == 0)
		//IPrintLn( level.total_zombies_killed +"/"+ kill_goal +"  active:" + level.ZHC_room_info[roomId]["active"]);
	}
	//if(roomId == 0)iprintln("kill_goal_reached"+"  active:" + level.ZHC_room_info[roomId]["active"]);

	roomIds = GetArrayKeys( level.ZHC_room_info );
	//roomsToIncreaseDifficultyIds = [];
	roomsToDecreaseDifficultyIds = [];
	for(i = 0; i <  roomIds.size; i++)
	{
		if(roomIds[i] == roomId)
			continue;
		if(level.ZHC_room_info[roomIds[i]]["active"]){
		//	roomsToIncreaseDifficultyIds[roomsToIncreaseDifficultyIds.size] = roomIds[i];
		}
		else
			roomsToDecreaseDifficultyIds[roomsToDecreaseDifficultyIds.size] = roomIds[i];
	}
	//for(i = 0; i <  roomsToIncreaseDifficultyIds.size; i++){
	//	level notify("zhc_update_flow_difficulty_roomId_"+roomsToIncreaseDifficultyIds[i], 1);
	//}
	for(i = 0; i <  roomsToDecreaseDifficultyIds.size; i++){
		level notify("zhc_update_flow_difficulty_roomId_"+roomsToDecreaseDifficultyIds[i], -1/roomsToDecreaseDifficultyIds.size);
	}

	level notify("zhc_update_flow_difficulty_roomId_"+roomId, 0.5);
}
manage_room_activity(){
	while(1){
		updateRoomActivity();
		level waittill( "zone_info_updated" );
	}
}
updateRoomActivity(){
	roomIds = GetArrayKeys( level.ZHC_room_info );
	for(i = 0; i <  roomIds.size; i++){
		active = updateRoomIsActive(roomIds[i]);
		updateRoomIsOccupied(roomIds[i]);
		if(active)
			activate_room(roomIds[i]);
		else
			deactivate_room(roomIds[i]);
	}
}
updateRoomIsActive(roomId){
	active = roomIsActive(roomId);
	level.ZHC_room_info[roomId]["active"] = active;
	return active;
}
roomIsActive(roomId){
	for(i = 0; i < level.ZHC_room_info[roomId]["zones"].size; i++){
		if(level.zones[level.ZHC_room_info[roomId]["zones"][i]].is_active)
			return true;
	}
	return false;
}
updateRoomIsOccupied(roomId){
	occupied = roomIsOccupied(roomId);
	level.ZHC_room_info[roomId]["occupied"] = occupied;
	return occupied;
}
roomIsOccupied(roomId){
	for(i = 0; i < level.ZHC_room_info[roomId]["zones"].size; i++){
		if(level.zones[level.ZHC_room_info[roomId]["zones"][i]].is_occupied)
			return true;
	}
	return false;
}

activate_room(roomId){
	if(!level.ZHC_ROOMFLOW)
		return;

	if( level.ZHC_room_info[roomId]["last_round_active"] < level.round_number){
		level.ZHC_room_info[roomId]["last_round_active"] = level.round_number;
	}

	active = level.ZHC_room_info[roomId]["active"];
	if(active)
		return;
	level.ZHC_room_info[roomId]["active"] = true;
	level.ZHC_round_zombie_limit_mult *= level.ZHC_room_info[roomId]["room_zombie_limit_mult"];
	level.ZHC_round_spawning_speed_mult *= level.ZHC_room_info[roomId]["room_spawning_speed_mult"];
}
deactivate_room(roomId){
	if(!level.ZHC_ROOMFLOW)
		return;
	active = level.ZHC_room_info[roomId]["active"];
	if(!active)
		return;
	level.ZHC_room_info[roomId]["active"] = false;
	level.ZHC_round_zombie_limit_mult /= level.ZHC_room_info[roomId]["room_zombie_limit_mult"];
	level.ZHC_round_spawning_speed_mult /= level.ZHC_room_info[roomId]["room_spawning_speed_mult"];
}
additional_round_logic(){
	if(ZHC_ROUND_FLOW_check()){

		if(!level.ZHC_ROOMFLOW){
			data = update_round_flow_difficulty();
			
			level.zombie_total = data["zombie_total"];
			level.ZHC_score_to_drop_powerup_mult = data["round_zombie_total_mult"];
			//level.ZHC_round_zombie_total_mult = data["round_zombie_total_mult"];

			
				level.ZHC_round_zombie_limit_mult = data["round_zombie_limit_mult"];
				level.ZHC_round_spawning_speed_mult = data["round_spawning_speed_mult"];

				level.zombie_health = data["zombie_health"];
				
				level.zombie_move_speed = data["zombie_move_speed"];
				level.ZHC_zombie_move_speed_spike = data["zombie_move_speed_spike"];
				level.ZHC_zombie_move_speed_spike_chance = data["zombie_move_speed_spike_chance"];

			level.ZHC_dogs_to_spawn_this_round = data["dogs_to_spawn_this_round"];
			level.mixed_rounds_enabled = data["mixed_rounds_enabled"];
		}else{


			data = update_round_difficulty();
			
			//level.zombie_total = data["zombie_total"];
			//level.ZHC_score_to_drop_powerup_mult = data["round_zombie_total_mult"];
			//level.ZHC_round_zombie_total_mult = data["round_zombie_total_mult"];

			
			/*
				level.ZHC_round_spawning_speed_mult = data["round_spawning_speed_mult"];

				level.zombie_health = data["zombie_health"];
				
				level.zombie_move_speed = data["zombie_move_speed"];
				level.ZHC_zombie_move_speed_spike = data["zombie_move_speed_spike"];
				level.ZHC_zombie_move_speed_spike_chance = data["zombie_move_speed_spike_chance"];
			*/

			level.ZHC_dogs_to_spawn_this_round = data["dogs_to_spawn_this_round"];
			level.mixed_rounds_enabled = data["mixed_rounds_enabled"];



			if(level.round_number > 1){	//skip init round.
				roomIds = GetArrayKeys( level.ZHC_room_info );
				roomsToIncreaseDifficultyIds = [];
				roomsToDecreaseDifficultyIds = [];

				for(i = 0; i <  roomIds.size; i++)
				{
					level.ZHC_room_info[roomIds[i]]["enemy_count"] = 0;	//reset just in case.
					if(level.ZHC_room_info[roomIds[i]]["active"])
						roomsToIncreaseDifficultyIds[roomsToIncreaseDifficultyIds.size] = roomIds[i];
					else
						roomsToDecreaseDifficultyIds[roomsToDecreaseDifficultyIds.size] = roomIds[i];
				}
				for(i = 0; i <  roomsToIncreaseDifficultyIds.size; i++){
					level notify("zhc_update_flow_difficulty_roomId_"+roomsToIncreaseDifficultyIds[i], 1);
				}
				for(i = 0; i <  roomsToDecreaseDifficultyIds.size; i++){
					level notify("zhc_update_flow_difficulty_roomId_"+roomsToDecreaseDifficultyIds[i], -1/roomsToDecreaseDifficultyIds.size);
				}
			}else if(level.ZHC_ROOMFLOW_FIRST_ROOM_HARDER){
				thread first_room_harder();	
			}
		}

	}
	level.zombies_to_ignore_refund = 0;
	level.ZHC_dogs_spawned_this_mixed_round = 0;
}

/////////////////////////////ROUND FLOW STUFF //////////////////////
ZHC_get_dog_max_add(){
	if(ZHC_ROUND_FLOW_check()){
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
	if(ZHC_ROUND_FLOW_check()){
		enemy_count /= max(1,num_player_valid);
		difficulty_mult = (((100 - min(level.round_number,100) )/100)*0.7) + 0.3;
		return min(12,enemy_count *enemy_count)*difficulty_mult;
	}
	return 1;
}
ZHC_spawn_dog_override(enemy_count, roomId){				//note: dogs are only able to spawn in other zones that are not occupied. 
	if(ZHC_ROUND_FLOW_check() ){
		if(level.ZHC_dogs_to_spawn_this_round > level.ZHC_dogs_spawned_this_mixed_round){

			if(level.ZHC_ROOMFLOW)
				left_to_spawn = level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_mixed_round;
			else
				left_to_spawn = int(max(0,(level.ZHC_dogs_to_spawn_this_round * level.ZHC_room_info[roomId]["dog_spawn_mult"]) - level.ZHC_dogs_spawned_this_mixed_round));

			//dogs_spawned_percent = level.ZHC_dogs_spawned_this_mixed_round/level.ZHC_dogs_to_spawn_this_round;	//0-1 as dogs are spawned
			//cur_round_percent = (level.zombie_total_start - (level.zombie_total + enemy_count) )/level.zombie_total_start;	//0-1 as round continues
			//interprolated_round_progression = interpolate(cur_round_percent, 0.1, 0.9); //can be negative or greater than one. 1 - 0 when round_percent is between 1.0 and 0.9.
			//percent_pass = interprolated_round_progression > dogs_spawned_percent;

			spawn_dog_percent = (level.ZHC_dogs_spawned_this_mixed_round + 1)/(level.ZHC_dogs_to_spawn_this_round+1);	// if 0 dogs spawned and 1 dog to spawn its 1/2. so it will spawn the dog at 1/5 the round is done. 
			cur_round_percent = (level.zombie_total_start - (level.zombie_total + enemy_count + 24) )/level.zombie_total_start;	//1-0 as round continues	//adding 24 makes it so the last dog spawns when there are 24 zombies left..
			percent_pass = cur_round_percent > spawn_dog_percent;

			if( percent_pass  || randomInt( int((level.zombie_total_start/left_to_spawn) * 1.5) ) == 1 ){
				to_spawn = int( min( left_to_spawn, max( 1, randomInt(level.dog_round_count-1) ) ) );
				s = "spawning " + to_spawn + " dog";
				if (to_spawn != 1)
					s+= "s...";
				else
					s+= "....";
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
	if(ZHC_ROUND_FLOW_check()){
		if(!IsDefined( level.ZHC_round_spawning_speed_mult ))
			return 1;
		return level.ZHC_round_spawning_speed_mult
			* ((1*(enemyCount/cur_enemy_limit))+0.5)	//turns current spawn percentage into a value between 0.5 - 1.5
			* (1.2 - int(level.zombie_total <= level.zombie_total_start/2)*0.4);	// if half of round has spawned change speed form 1.2 - 0.8
	}
	return 1;
}
get_zombie_limit_mult(){
	if(ZHC_ROUND_FLOW_check()){
		if(!IsDefined( level.ZHC_round_zombie_limit_mult ))
			return 1;
		return level.ZHC_round_zombie_limit_mult;
	}
	return 1;
}
get_score_to_drop_powerup_mult(){
	if(ZHC_ROUND_FLOW_check()){
		if(!IsDefined( level.ZHC_score_to_drop_powerup_mult) )
			return 1;
		return level.ZHC_score_to_drop_powerup_mult;
	}
	return 1;
}


//level notify( "zhc_stop_debug_zombie_health" );
//level thread debug_zombie_health();
debug_zombie_health(){
	level endon( "zhc_stop_debug_zombie_health" );
	IPrintLnBold( "zhp set to: "+ level.zombie_health +" by rf");
	last_zomb_health_debug = level.zombie_health - 1;
	while(level.zombie_health != last_zomb_health_debug){
		if(last_zomb_health_debug != level.zombie_health){
			IPrintLnBold( "zhp set to: "+ level.zombie_health );
			last_zomb_health_debug = level.zombie_health;
		}
		wait_network_frame();
	}
	
}

ZHC_ROUND_FLOW_check(){
	return level.ZHC_ROUND_FLOW==1;
}

update_round_flow_difficulty(){

	data = [];
	DEBUG_FLOW = false;

	fr = level.round_number - (level.dog_round_count-1); //flow round number - excludes dog rounds 

	FLOW_ROUND_LENGTH = 4;
	flow_difficulty = ((fr-1) % FLOW_ROUND_LENGTH );				//fluctuates from 0 -> FLOW_ROUND_LENGTH-1 based on stage in FLOW_ROUND_LENGTH
	flow_difficulty_percent = max(0,min(1,flow_difficulty/(FLOW_ROUND_LENGTH-1)));	//fluctuates from 0 -> 1 based on stage in FLOW_ROUND_LENGTH
	inverse_flow_difficulty_percent = max(0,min(1,((FLOW_ROUND_LENGTH-flow_difficulty)/FLOW_ROUND_LENGTH))) ; 
																		//fructuates from 1 -> 0 based on stage in FLOW_ROUND_LENGTH.
	flows_completed = int((fr-1) / FLOW_ROUND_LENGTH);

	if(DEBUG_FLOW)
		IPrintLnBold( "flow_difficulty: " + flow_difficulty );
			//		(   (((1                 -1) - 10) , 0)) /10; == 0
			//		(   (((10                -1) - 10) , 0)) /10; == 0.9
	dampener = abs(min(((fr-1) - 10) , 0)) /10; //fluctuates from 1 - 0 from (r1 to r11)
	damp25 =  abs(min(((fr-1) - 25) , 0)) /25; 	//fluctuates from 1 - 0 from (r1 to r25)
	mult_go_to_health_instead = 0.3 * damp25 * min(flow_difficulty_percent,0.75); //
	//IPrintLn( mult_go_to_health_instead );//0 at round 1
	//IPrintLnBold( "flow_diffic:" + flow_difficulty + " damp10:"+ int(dampener*100)/100 + " damp25:" + int(damp25*100)/100 + " mgtH:" + int(mult_go_to_health_instead*100)/100 );

	//zombie total
	diminished_dampner = ((dampener * 0.4)+(1 - 0.4));
	round_zombie_total_mult = (flow_difficulty_percent * 0.5 *  diminished_dampner) +1;
	zombie_total = int(level.zombie_total * round_zombie_total_mult);
	data["zombie_total"] = zombie_total;
	data["round_zombie_total_mult"] = round_zombie_total_mult;
	
	//level.zombie_total = level.round_number; //testo
	//level.zombie_total = 1;//testo

	if(DEBUG_FLOW)
		IPrintLn( "ZHC_round_zombie_total: "+zombie_total);
	//level.ZHC_score_to_drop_powerup_mult = ZHC_round_zombie_total_mult;


	//zombie limit
	diminished_dampner = ((dampener * 0.5)+(1 - 0.5));
	round_zombie_limit_mult = (flow_difficulty * 0.5 * diminished_dampner)+1;
	data["round_zombie_limit_mult"] = round_zombie_limit_mult;
	if(DEBUG_FLOW)
		IPrintLn( "ZHC_round_zombie_limit_mult: "+ round_zombie_limit_mult);


		//spawning speed
	diminished_IFD = (0.5 * flow_difficulty_percent * damp25) + 1;	//fluctuares between 1 and 1.5. effect deminishes until round 25.
	//diminished_IFD = (0.3 * inverse_flow_difficulty_percent * dampner) + (1 - 0.3 * dampner);	// == 1 when dampner is 0. 
																								// == (ifdp * 0.3)+0.7 when dampener is 1. 
																									//(ifdp * 0.3)+0.7 fluctuates between 1 - 0.5 as the FLOW_ROUND_LENGTH progresses
	round_spawning_speed_mult = diminished_IFD * (1+mult_go_to_health_instead);
	data["round_spawning_speed_mult"] = round_spawning_speed_mult;
	if(DEBUG_FLOW)
		IPrintLn( "ZHC_round_spawning_speed_mult: "+round_spawning_speed_mult);

	
	FLOW2_ROUND_LENGTH = FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH;
	flow2_difficulty = ((fr-1)%FLOW2_ROUND_LENGTH)/FLOW_ROUND_LENGTH; //0-(FLOW_ROUND_LENGTH-1) based on as fr goes from 1 - 16. this repeats every 16 rounds. 16 = (FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)
	flows2_completed = int((fr-1)/FLOW2_ROUND_LENGTH);		//the number of time 16 rounds were reached


	//zombie health
	animSpeed = 
		1 +
		//min((fr-1)*0.25,1) +
		(flow_difficulty) +
		(flows_completed*0.05) + 
		(flow2_difficulty)  						//from 0 - 2 based on FLOW2_ROUND_LENGTH difficulty.
		;

	DEBUG_SPEED_FUNC = false;
	if(DEBUG_FLOW && DEBUG_SPEED_FUNC){
		IPrintLn( "1 +" );
		//IPrintLn( "min((fr-1)*0.25,1) =" + min((fr-1)*0.25,1) +"+" );
		IPrintLn( "(flow_difficulty) =         "+ (flow_difficulty)+ "+" );
		IPrintLn( "(flows_completed*0.05) =    "+(flows_completed*0.05)+"+" );
		IPrintLn( "(flow2_difficulty * 0.55) = " + (flow2_difficulty * 0.55) +"+" );
		//IPrintLn( "flows2_completed*(FLOW_ROUND_LENGTH*0.75) = "+flows2_completed*(FLOW_ROUND_LENGTH*0.75)+"+" );
	}
	if(DEBUG_FLOW)
		IPrintLn("animSpeed = " + animSpeed );

	//animSpeed *= (1-mult_go_to_health_instead);
	//IPrintLn( "pre_zombie_health: "+level.zombie_health);

	// undo the health gain on the zombies.

	//if(level.round_number > 1 && flow_difficulty == 0){					//permanatly adds more health every new FLOW_ROUND_LENGTH
	//	level.zombie_health = int(level.zombie_health * ((FLOW_ROUND_LENGTH*0.1) + 1));
		//level.zombie_health += FLOW_ROUND_LENGTH * 40;
		//animSpeed  =  max(animSpeed - (FLOW_ROUND_LENGTH-1.5), flows_completed * 1.75) ;
	//}

	//make weaker FLOW_ROUND_LENGTH rounds have proportinally stronger zombies. expirimental


	//if(isDefined(level.zhc_zombie_health_mult))
	//	zombie_health = int((1/level.zhc_zombie_health_mult)*level.zombie_health); // undo previous mult;
	//else
	//	zombie_health = level.zombie_health;

	zhc_zombie_health_mult = 1;
	zhc_zombie_health_mult *=  pow(((FLOW_ROUND_LENGTH * 0.1) + 1), flows_completed);
	//level.zhc_zombie_health_mult *= min(fr-1,9) * 0.1;
	//IPrintLn( "zh_mult: "+ level.zhc_zombie_health_mult +"  f_compl:"+flows_completed);
	zhc_zombie_health_mult *=  1 + ((flow_difficulty_percent == 1) * 0.16 * flow_difficulty);
	zhc_zombie_health_mult *= (  inverse_flow_difficulty_percent  *3* min((flows_completed*0.333),3) )  +1; 
	zhc_zombie_health_mult *= 1 + mult_go_to_health_instead;
	
	zombie_health = int(zhc_zombie_health_mult * level.zombie_health);
	data["zombie_health_mult"] = zhc_zombie_health_mult;
	data["zombie_health"] = zombie_health;
	if(DEBUG_FLOW)
		IPrintLn( "post_zombie_health: "+ zombie_health);

	//zombie movement speed
	
	zombie_move_speed = int(animSpeed * level.zombie_vars["zombie_move_speed_multiplier"]); //0-40 = walk, 41-70 = run, 71+ = sprint
	data["zombie_move_speed"] = zombie_move_speed;

	zombie_move_speed_spike_chance = int( 10 + (flow2_difficulty * FLOW_ROUND_LENGTH) + min(flows_completed*1.5,15) );
	zombie_move_speed_spike = 10 +
		int(zombie_move_speed * (
			1 +
			(flow_difficulty*0.5/FLOW_ROUND_LENGTH) //[0 - 1]
			+
			(flow2_difficulty*0.35/FLOW_ROUND_LENGTH)//[0 - 1]
			+ 
			flows_completed * 0.1
		));
	data["zombie_move_speed_spike"] = zombie_move_speed_spike;
	data["zombie_move_speed_spike_chance"] = zombie_move_speed_spike_chance;



	if(DEBUG_FLOW)
		IPrintLnBold( "zombie_move_speed: "+zombie_move_speed +"   spike "+ zombie_move_speed_spike +"    chance "+ zombie_move_speed_spike_chance+"%");
	


	dog_left_to_spawn_from_previous_round = 0;
	if(isDefined(level.ZHC_dogs_spawned_this_mixed_round) && IsDefined( level.ZHC_dogs_to_spawn_this_round )){
		dog_left_to_spawn_from_previous_round = int(max(0,level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_mixed_round));
	}
	
	dogs_to_spawn_this_round = 
	int(	
		(flows2_completed*2) + //ads a small but base amount of dogs per rounds.
			(inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) *  
			min(zombie_total/36, ( int(flows_completed > 0) * level.dog_round_count )*1.5) *
			max(1+(flows2_completed * 0.25), 2)
	   ) 
	+ dog_left_to_spawn_from_previous_round;																	//dogs not spawnwed from previous rounds are added to this round.

	mixed_rounds_enabled = int(dogs_to_spawn_this_round > 0) && level.dog_round_count-1 > 0;	//can only spawns dogs after dog round. 

	data["dogs_to_spawn_this_round"] = dogs_to_spawn_this_round;
	data["mixed_rounds_enabled"] = mixed_rounds_enabled;

	if(DEBUG_FLOW)
		IPrintLnBold("dog_round_count: "+level.dog_round_count + "  ZHC_dogs_to_spawn_this_round: "+ dogs_to_spawn_this_round + "  mixed_rounds_enabled: " +mixed_rounds_enabled );
	
	/*IPrintLnBold( 
		"dogs_to_be_spawned = " + (fr/(FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)) + " + " + (inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) + " * " + (level.zombie_total/36 + (level.dog_round_count-1)*1.5)
		+ " = " +(	
			(fr/(FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)) + //ads a small but base amount of dogs per rounds.
			(inverse_flow_difficulty_percent * inverse_flow_difficulty_percent) *  
			(level.zombie_total/36 + (level.dog_round_count-1)*1.5)
	   ) + " to int-> " + level.ZHC_dogs_to_spawn_this_round
	 );*/
	 return data;
}

update_round_difficulty(){

	DEBUG_FLOW = false;
		//zombie total
	{
		round_zombie_total_mult = 1;
		round_zombie_total = int(level.zombie_total * round_zombie_total_mult);
		data["zombie_total"] = round_zombie_total;
		data["round_zombie_total_mult"] = round_zombie_total_mult;
		if(DEBUG_FLOW)
			IPrintLn( "round_zombie_total: "+round_zombie_total);
	}

		//zombie limit
	{
		round_zombie_limit_mult = 1;
		data["round_zombie_limit_mult"] = round_zombie_limit_mult;
		if(DEBUG_FLOW)
			IPrintLn( "round_zombie_limit_mult: "+ round_zombie_limit_mult);
	}


		//zombie spawning speed
	{
		round_spawning_speed_mult = 1;
		data["round_spawning_speed_mult"] = round_spawning_speed_mult;
		if(DEBUG_FLOW)
			IPrintLn( "round_spawning_speed_mult: "+round_spawning_speed_mult);
	}

		//zombie movement speed
	{
		animSpeed = 1 + 																				//base amount
					min(max(0,level.round_number-10)*0.125, 2) + 									//slight increase every round till round 25.
					( 	( int(max(0,level.round_number-6))%int(4-1)/4) * 				//0 - 1 peaks every 4 rounds. first 2 round grace period.
						min(2.5,max(0.75,level.round_number * 0.1))			//flow mult. increase every round. peaks at +22 movespeed per flow.
					)																				//flow mult peaks every 4 rounds, with 2 round grace period.
					;
		zombie_move_speed = int(animSpeed * level.zombie_vars["zombie_move_speed_multiplier"]); //x8 //0-40 = walk, 41-70 = run, 71+ = sprint
		data["zombie_move_speed"] = zombie_move_speed;

		zombie_move_speed_spike_chance = 10 + min(max(0,level.round_number-10), 15);
		zombie_move_speed_spike = 20 + zombie_move_speed ;
		data["zombie_move_speed_spike"] = zombie_move_speed_spike;
		data["zombie_move_speed_spike_chance"] = zombie_move_speed_spike_chance;
		if(DEBUG_FLOW)
			IPrintLn( "zomb_speed: "+zombie_move_speed +"   spk: "+ zombie_move_speed_spike +"   "+ zombie_move_speed_spike_chance+"%");
	}

		//zombie health
	{
		round_zombie_health_mult = 1;
		data["round_zombie_health_mult"] = round_zombie_health_mult;
		if(DEBUG_FLOW)
			IPrintLn( "round_zombie_health_mult: "+ round_zombie_health_mult);
	}

		//dog spawns
	{
		dog_left_to_spawn_from_previous_round = 0;
		if(isDefined(level.ZHC_dogs_spawned_this_mixed_round) && IsDefined( level.ZHC_dogs_to_spawn_this_round )){
			dog_left_to_spawn_from_previous_round = int(max(0,level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_mixed_round));
		}
		
		dogs_to_spawn_this_round = 
		int(	
			//(level.round_number/10) + //ads a small but base amount of dogs per rounds.
				min(level.zombie_total/36, (level.dog_round_count-1) *0.75 ) +
				(int(level.dog_round_count-1 > 0) * max(0,8 - (level.next_dog_round - level.round_number)) * 0.25 )	//more dogs if near dog round. round before dog round adds 3.5 dogs. only adds if dog round has happened.
		   ) 
		+ dog_left_to_spawn_from_previous_round;																	//dogs not spawnwed from previous rounds are added to this round.

		mixed_rounds_enabled = int(dogs_to_spawn_this_round > 0) && level.dog_round_count-1 > 0;	//can only spawns dogs after dog round. 

		data["dogs_to_spawn_this_round"] = dogs_to_spawn_this_round;
		data["mixed_rounds_enabled"] = mixed_rounds_enabled;
		DEBUG_DOG = true;
		if(DEBUG_FLOW || DEBUG_DOG)
			IPrintLnBold("dog_round_count: "+level.dog_round_count + "  ZHC_dogs_to_spawn_this_round: "+ dogs_to_spawn_this_round + "  mixed_rounds_enabled: " +mixed_rounds_enabled );
	}
	return data;

}

update_room_difficulty( difficulty, roomId, DEBUG_FLOW){
	data = [];
	if(!IsDefined( DEBUG_FLOW ))
		DEBUG_FLOW = false;

	fr = level.round_number - (level.dog_round_count-1); //flow round number - excludes dog rounds 

	SPEED_FLOW_ROUND_LENGTH = 5;
	speed_flow_percent_completion = ( ((fr+roomId)-1 ) % SPEED_FLOW_ROUND_LENGTH ) / (SPEED_FLOW_ROUND_LENGTH-1);
	speed_flow_percent = abs(speed_flow_percent_completion - 0.5)*2;	//flow peaks in the ends, dips in the middle and goes back t 1. 0 = 1; 0.5 = 0. 1 = 1
	

	speed_flows_completed = int((fr-1)/SPEED_FLOW_ROUND_LENGTH);

	if(speed_flow_percent > 0.5)
		speed_flow_percent += abs(1 - speed_flow_percent)/2;	//shortens distance to 1 by half 
	else
		speed_flow_percent += abs(speed_flow_percent)/2;	//shortens its distance to 1 by itself

	if(speed_flows_completed%4 == 0)						//experimental
		speed_flow_percent = speed_flow_percent_completion;
	else if(speed_flows_completed%4 == 2)
		speed_flow_percent = 1 - speed_flow_percent_completion;

	speed_flows_completed_in_room_float = (difficulty-1)/SPEED_FLOW_ROUND_LENGTH;		//missnomer but whatecver
	speed_flows_completed_in_room= int(speed_flows_completed_in_room_float);				//missnomer but whatever






	damp5 = abs(min(((fr-1) - 5) , 0)) /5; //fluctuates from 1 - 0 from (r1 to r6)
	damp10 = abs(min(((fr-1) - 10) , 0)) /10; //fluctuates from 1 - 0 from (r1 to r11)
	damp15 =  abs(min(((fr-1) - 15) , 0)) /15; 	//fluctuates from 1 - 0 from (r1 to r16)
	damp20 =  abs(min(((fr-1) - 20) , 0)) /20; 	//fluctuates from 1 - 0 from (r1 to r21)
	damp25 =  abs(min(((fr-1) - 25) , 0)) /25; 	//fluctuates from 1 - 0 from (r1 to r26)

	//deminishes the slow ness on early rounds 		
	speed_flow_percent_diminished = speed_flow_percent + (
															(1-speed_flow_percent) * //dampner applied in reverse. maintains number closer to 1.
															min(damp10+0.25,1)	// +0.25 makes it so speed mult stays at 1 for first couple rounds.
														 );


	if(DEBUG_FLOW)
		IPrintLnBold( "room_difficulty: " + difficulty + "  speed_flow_percent: "+speed_flow_percent_diminished );

		//zombie total
	{
		room_zombie_total_mult_speed_flow_percent_influence = 0.3; //set to 0 -> 1. how much influence does the speed flow have on spawning speed.
		//vvv fluctuates between 0.85 - 0.15  or +- 0.3/2) based on the room flow.
		room_zombie_total_mult_speed_flow_mult =  (1 - room_zombie_total_mult_speed_flow_percent_influence) + (speed_flow_percent_diminished*room_zombie_total_mult_speed_flow_percent_influence) + (room_zombie_total_mult_speed_flow_percent_influence/2) ;
		
		diminished_dampner = ((damp10 * 0.4)+(1 - 0.4));	//will only dampen down 1 -> 0.6. 0.6 will always remain after 10 rounds.
		room_zombie_total_mult = (difficulty * 0.12 *  diminished_dampner * room_zombie_total_mult_speed_flow_mult) + 1;
		data["room_zombie_total_mult"] = room_zombie_total_mult;
		if(DEBUG_FLOW)
			IPrintLn( "room_zombie_total_mult: "+room_zombie_total_mult);
	}

		//zombie limit
	{
		diminished_dampner = ((damp10 * 0.7)+(1 - 0.7)); //will only dampen down 1 -> 0.3. 0.3 will always remain after 10 rounds.
		room_zombie_limit_mult = (difficulty * 0.23 * diminished_dampner)+0.3;
		data["room_zombie_limit_mult"] = room_zombie_limit_mult;
		if(DEBUG_FLOW)
			IPrintLn( "room_zombie_limit_mult: "+ room_zombie_limit_mult);
	}


		//zombie spawning speed
	{
		diminished_IFD = (0.5 * (1 - speed_flow_percent_diminished) * damp10) + 1;	//fluctuares between 1 and 1.5. effect deminishes until round 10.
		//diminished_IFD = (0.3 * inverse_flo_wdifficulty_percent * dampner) + (1 - 0.3 * dampner);	// == 1 when dampner is 0. 
																									// == (ifdp * 0.3)+0.7 when dampener is 1. 
																										//(ifdp * 0.3)+0.7 fluctuates between 1 - 0.5 as the FLOW_ROUND_LENGTH progresses

		room_spawning_speed_mult_speed_flow_percent_influence = 0.45; //set to 0 -> 1. how much influence does the speed flow have on spawning speed.
		room_spawning_speed_mult_speed_flow_mult =  (1 - room_spawning_speed_mult_speed_flow_percent_influence) + (speed_flow_percent_diminished*room_spawning_speed_mult_speed_flow_percent_influence) + (room_spawning_speed_mult_speed_flow_percent_influence/2) ;
		
		room_spawning_speed_mult = diminished_IFD * room_spawning_speed_mult_speed_flow_mult;
		data["room_spawning_speed_mult"] = room_spawning_speed_mult;
		if(DEBUG_FLOW)
			IPrintLn( "room_spawning_speed_mult: "+room_spawning_speed_mult);
	}

	/*
	FLOW2_ROUND_LENGTH = FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH;
	flow2_difficulty = ((fr-1)%FLOW2_ROUND_LENGTH)/FLOW_ROUND_LENGTH; //0-(FLOW_ROUND_LENGTH-1) based on as fr goes from 1 - 16. this repeats every 16 rounds. 16 = (FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)
	flows2_completed = int((fr-1)/FLOW2_ROUND_LENGTH);		//the number of time 16 rounds were reached
	
	SPEED_FLOW2_ROUND_LENGTH = SPEED_FLOW_ROUND_LENGTH*SPEED_FLOW_ROUND_LENGTH;
	flow2_difficulty = ((fr-1)%SPEED_FLOW2_ROUND_LENGTH)/SPEED_FLOW_ROUND_LENGTH; //0-(FLOW_ROUND_LENGTH-1) based on as fr goes from 1 - 16. this repeats every 16 rounds. 16 = (FLOW_ROUND_LENGTH*FLOW_ROUND_LENGTH)
	flows2_completed = int((fr-1)/SPEED_FLOW2_ROUND_LENGTH);		//the number of time 16 rounds were reached
	*/
	

		//zombie move speed
	{
		animSpeed = 
			1 +
			min((fr * 0.15), 1 + (speed_flow_percent_diminished * 2 ) ) +
			((1 - damp15) * difficulty * speed_flow_percent_diminished) + 
			(difficulty * speed_flow_percent_diminished)
			;

		DEBUG_SPEED_FUNC = false;
		if(DEBUG_FLOW && DEBUG_SPEED_FUNC){
			IPrintLn( "    1+" );
			IPrintLn( "    "+min((fr * 0.15), 1 + (speed_flow_percent_diminished * 2) ) + "+" );
			IPrintLn( "    "+((1 - damp15) * difficulty * speed_flow_percent_diminished)+"+" );
			IPrintLn( "    "+(difficulty * speed_flow_percent_diminished) );
			IPrintLn( "    = "+animSpeed );		
		}

		zombie_move_speed = int(animSpeed * level.zombie_vars["zombie_move_speed_multiplier"]); //0-40 = walk, 41-70 = run, 71+ = sprint
		data["zombie_move_speed"] = zombie_move_speed;
		//if(DEBUG_FLOW)
		//	IPrintLn("zombie_move_speed = " + zombie_move_speed );

			//zombie move speed spike
		{
			zombie_move_speed_spike_chance = int( 7.5 + 
				(speed_flow_percent_completion * SPEED_FLOW_ROUND_LENGTH * 2.5) + 
				min(speed_flows_completed * SPEED_FLOW_ROUND_LENGTH * 0.15,7.5) + 
				min(speed_flows_completed_in_room_float * SPEED_FLOW_ROUND_LENGTH * 0.3,12.5) 
			);

			zombie_move_speed_spike = 10 +
				int(zombie_move_speed * ( 
					1 + ( min(speed_flows_completed_in_room_float * SPEED_FLOW_ROUND_LENGTH, 7.5) * 0.07 )
				));
			data["zombie_move_speed_spike"] = zombie_move_speed_spike;
			data["zombie_move_speed_spike_chance"] = zombie_move_speed_spike_chance;

			if(DEBUG_FLOW)
			IPrintLn( "zomb_speed: "+zombie_move_speed +"   spk: "+ zombie_move_speed_spike +"   "+ zombie_move_speed_spike_chance+"%");
		}
	}


	
		//zombie health
	{
		room_zombie_health_mult = 1;
		//room_zombie_health_mult *=  pow(((FLOW_ROUND_LENGTH * 0.1) + 1), flows_completed);	
		//room_zombie_health_mult *= min(fr-1,9) * 0.1;
		//IPrintLn( "zh_mult: "+ room_zombie_health_mult +"  f_compl:"+flows_completed);
		//room_zombie_health_mult *=  1 + ((difficulty_percent == 1) * 0.16 * difficulty);
		//room_zombie_health_mult *= (  inverse_difficulty_percent  *3* min((flows_completed*0.333),3) )  +1; 
		//room_zombie_health_mult *= 1 + mult_go_to_health_instead;
		room_zombie_health_mult = 1 + ((1 - speed_flow_percent_diminished) * (difficulty + 1) );
		data["room_zombie_health_mult"] = room_zombie_health_mult;
		if(DEBUG_FLOW)
			IPrintLn( "room_zombie_health_mult: "+ room_zombie_health_mult);
	}
		//dog_spawn_mult
	{
		data["room_dog_spawn_mult"] = (1 - speed_flow_percent);
	}

	return data;
	
}
