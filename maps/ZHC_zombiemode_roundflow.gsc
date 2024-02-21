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

	level.ZHC_dogs_spawned_this_round = undefined;
	level.ZHC_dogs_to_spawn_this_round = undefined;

	

	level.ZHC_ROUND_FLOW = 1; //0 = default| 1 = alternate| 2 = "harder"

	if(ZHC_ROUND_FLOW_check())
		level.mixed_rounds_enabled = false;	//so it resets when game restarts

	difficulty = 1;
	column = int(difficulty) + 1;

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

	roomflow_init();
}


roomflow_init(){
	level.ZHC_room_info = [];
	keys = GetArrayKeys( level.zones );
	for(i = 0; i < keys.size;i++){
		roomId = maps\_zombiemode_blockers::Get_Zone_Room_ID(keys[i]);
		if(!isDefined(level.ZHC_room_info[roomId])){
			level.ZHC_room_info[roomId] = [];
			level thread manage_roomflow(roomId);
		}
	}
}
manage_roomflow(roomId){
	if(!isDefined(level.ZHC_room_info[roomId]))
		level.ZHC_room_info[roomId] = [];

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
ZHC_spawn_dog_override(enemy_count){				//note: dogs are only able to spawn in other zones that are not occupied. 
	if(ZHC_ROUND_FLOW_check() ){
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

additional_round_logic(){
	if(ZHC_ROUND_FLOW_check()){
		data = update_round_flow_difficulty();
		
		level.zombie_total = data[0];
		level.ZHC_score_to_drop_powerup_mult = data[1];
		level.ZHC_round_zombie_total_mult = data[1];

		level.ZHC_round_zombie_limit_mult = data[2];
		level.ZHC_round_spawning_speed_mult = data[3];

		level.zombie_health = data[4];
		level.zombie_move_speed = data[5];
		level.ZHC_zombie_move_speed_spike = data[6];
		level.ZHC_zombie_move_speed_spike_chance = data[7];

		level.ZHC_dogs_to_spawn_this_round = data[20];
		level.mixed_rounds_enabled = data[21];
		level.ZHC_dogs_spawned_this_round = 0;

	}
}

ZHC_ROUND_FLOW_check(){
	return level.ZHC_ROUND_FLOW==1;
}

update_round_flow_difficulty(flow_difficulty){

	data[] = 0;
	DEBUG_FLOW = false;

	fr = level.round_number - (level.dog_round_count-1); //flow round number - excludes dog rounds 

	FLOW_ROUND_LENGTH = 4;
	if(!isDefined(flow_difficulty))
		flow_difficulty = ((fr-1) % FLOW_ROUND_LENGTH );				//fluctuates from 0 -> FLOW_ROUND_LENGTH-1 based on stage in FLOW_ROUND_LENGTH
	flow_difficulty_percent = flow_difficulty/(FLOW_ROUND_LENGTH-1);	//fluctuates from 0 -> 1 based on stage in FLOW_ROUND_LENGTH
	inverse_flow_difficulty_percent = ((FLOW_ROUND_LENGTH-flow_difficulty)/FLOW_ROUND_LENGTH); 
																		//fructuates from 1 -> 0 based on stage in FLOW_ROUND_LENGTH.
	flows_completed = int((fr-1) / FLOW_ROUND_LENGTH);

	if(DEBUG_FLOW)
		IPrintLnBold( "flow_difficulty: " + flow_difficulty );
			//		(   (((1                 -1) - 10) , 0)) /10; == 0
			//		(   (((10                -1) - 10) , 0)) /10; == 0.9
	dampener = abs(min(((level.round_number-1) - 10) , 0)) /10; //fluctuates from 1 - 0 from (r1 to r11)
	damp25 =  abs(min(((level.round_number-1) - 25) , 0)) /25; 	//fluctuates from 1 - 0 from (r1 to r25)
	mult_go_to_health_instead = 0.3 * damp25 * flow_difficulty_percent; //

	//IPrintLnBold( "flow_diffic:" + flow_difficulty + " damp10:"+ int(dampener*100)/100 + " damp25:" + int(damp25*100)/100 + " mgtH:" + int(mult_go_to_health_instead*100)/100 );

	//zombie total
	diminished_dampner = ((dampener * 0.4)+(1 - 0.4));



	round_zombie_total_mult = (flow_difficulty_percent * 0.5 *  diminished_dampner) +1;
	zombie_total = int(level.zombie_total * ZHC_round_zombie_total_mult);
	data[0] = zombie_total;
	data[1] = round_zombie_total_mult;
	
	//level.zombie_total = level.round_number; //testo
	//level.zombie_total = 1;//testo

	if(DEBUG_FLOW)
		IPrintLn( "ZHC_round_zombie_total: "+zombie_total);
	//level.ZHC_score_to_drop_powerup_mult = ZHC_round_zombie_total_mult;


	//zombie limit
	diminished_dampner = ((dampener * 0.5)+(1 - 0.5));
	round_zombie_limit_mult = (flow_difficulty * 0.5 * diminished_dampner)+1;
	data[2] = round_zombie_limit_mult;
	if(DEBUG_FLOW)
		IPrintLn( "ZHC_round_zombie_limit_mult: "+level.ZHC_round_zombie_limit_mult);


		//spawning speed
	diminished_IFD = (0.5 * flow_difficulty_percent * damp25) + 1;	//fluctuares between 1 and 1.5. effect deminishes until round 25.
	//diminished_IFD = (0.3 * inverse_flow_difficulty_percent * dampner) + (1 - 0.3 * dampner);	// == 1 when dampner is 0. 
																								// == (ifdp * 0.3)+0.7 when dampener is 1. 
																									//(ifdp * 0.3)+0.7 fluctuates between 1 - 0.5 as the FLOW_ROUND_LENGTH progresses
	round_spawning_speed_mult = diminished_IFD * (1+mult_go_to_health_instead);
	data[3] = round_spawning_speed_mult;
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


	if(isDefined(level.zhc_zombie_health_mult))
		zombie_health = int((1/level.zhc_zombie_health_mult)*level.zombie_health); // undo previous mult;
	else
		zombie_health = level.zombie_health;
	level.zhc_zombie_health_mult = 1;
	level.zhc_zombie_health_mult *=  pow(((FLOW_ROUND_LENGTH * 0.1) + 1), flows_completed);
	//level.zhc_zombie_health_mult *= min(fr-1,9) * 0.1;
	level.zhc_zombie_health_mult *= (  inverse_flow_difficulty_percent  *3* min((flows_completed*0.333),3) )  +1; 
	level.zhc_zombie_health_mult *= 1 + mult_go_to_health_instead;
	zombie_health = int(level.zhc_zombie_health_mult * zombie_health);
	data[4] = zombie_health;
	if(DEBUG_FLOW)
		IPrintLn( "post_zombie_health: "+ zombie_health);

	//zombie movement speed
	
	zombie_move_speed = int(animSpeed * level.zombie_vars["zombie_move_speed_multiplier"]); //0-40 = walk, 41-70 = run, 71+ = sprint
	data[5] = zombie_move_speed;

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
	zombie_move_speed_spike = data[6];
	zombie_move_speed_spike_chance = data[7];



	if(DEBUG_FLOW)
		IPrintLnBold( "zombie_move_speed: "+zombie_move_speed +"   spike "+ ZHC_zombie_move_speed_spike +"    chance "+ZHC_zombie_move_speed_spike_chance+"%");
	


	dog_left_to_spawn_from_previous_round = 0;
	if(isDefined(level.ZHC_dogs_spawned_this_round) && IsDefined( level.ZHC_dogs_to_spawn_this_round )){
		dog_left_to_spawn_from_previous_round = int(max(0,level.ZHC_dogs_to_spawn_this_round - level.ZHC_dogs_spawned_this_round));
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

	data[20] = dogs_to_spawn_this_round;
	data[21] = mixed_rounds_enabled;

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

}
