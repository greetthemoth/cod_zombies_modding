#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;
//Kino Der Toten theater specific fuctions


init(){
	level.map_get_room_info = ::map_get_room_info;
	level.Get_Other_Zone = ::Get_Other_Zone ;
	level.room_id_can_be_stopped = ::room_id_can_be_stopped ;
	//level.map_wait_to_update_rooms = ::map_wait_to_update_rooms ;
	level.map_get_zone_room_id = ::map_get_zone_room_id ;
	level.map_get_doors_accesible_in_room = ::map_get_doors_accesible_in_room ;
	level.map_get_room_name = ::map_get_room_name ;
	//level.Get_Zone_Room_ID_Special = ::Get_Zone_Room_ID_Special ;
	//level.player_is_in_dead_zone = ::player_is_in_dead_zone ;
	level.can_close_door = ::can_close_door ;
	level.set_sister_door = ::set_sister_door ;

	level.zhc_additional_round_logic = ::first_room_harder;
	thread map_wait_to_update_rooms ();

}

first_room_harder(){
	//first room is hard.
	if(level.ZHC_ROOMFLOW && level.ZHC_ROOMFLOW_FIRST_ROOM_HARDER &&level.round_number == 1){
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
}
first_room_harder__wait_till_first_room_inactive_to_reduce_zombie_total(){
	level endon( "end_of_round" );	//only happens in the first round.
	while(level.ZHC_room_info[0]["active"] == true){
		wait_network_frame( );
	}
	level.zombies_to_ignore_refund = level.ZHC_room_info[0]["enemy_count"];
	level.zombie_total = int(min(level.zombie_total, 6));
}

map_get_room_info(roomId){
	if(roomId == 100 && flag("curtains_done"))
		return level.ZHC_room_info[4];
	else
		return level.ZHC_room_info[roomId];
}

Get_Other_Zone(opened_from, door){

	a = undefined;
	b = undefined;
	i = door get_door_id();

	if(i == 2){
		a = "foyer2_zone";
		b = "vip_zone";
	} else if(i == 4 || i == 3){
		a = "vip_zone";
		b = "dining_zone";
	} else if(i == 7){
		a = "dining_zone";
		b = "dressing_zone";
	} else if(i == 5){
		a = "dressing_zone";
		b = "stage_zone";
	} else if(i == 1 || i == 0){
		a = "stage_zone";
		b = "west_balcony_zone";
	} else if(i == 8){
		a = "west_balcony_zone";
		b = "alleyway_zone";
	} else if(i == 10){
		a = "alleyway_zone";
		b = "crematorium_zone";
	} else if(i == 11){
		a = "crematorium_zone";
		b = "foyer2_zone";
	}else if(i == 6 || i == 9){
		a = "theater_zone";
		b = "foyer2_zone";
	}

	if(opened_from == a)
		return b;
	else if(opened_from == b)
		return a;
	else{
		zhcpb( "OPENED FROM WEIRD ZONE. neither was" + opened_from ,444);
		return a;
	}
}

room_id_can_be_stopped(room_id){
	switch(room_id){
		case 100:
			return true;
		default:
			return false;
	}
}

map_wait_to_update_rooms(){
	flag_wait("all_players_connected");
	flag_wait( "curtains_done" );//common_scripts\utility.gsc:

	maps\ZHC_zombiemode_roundflow::Merge_RoomsId(100,4,4);
	
}


map_get_zone_room_id(zone_name){
	switch( zone_name){
		case "foyer_zone":
		case "foyer2_zone":
			return 0;
		case "vip_zone":
			return 1;
		case "dining_zone":
			return 2;
		case "dressing_zone":
			return 3;
		case "stage_zone":
			return 4;
		case "theater_zone":
			if(flag("curtains_done"))
				return 4;
			else
				return 100;
		case "west_balcony_zone":
			return 5;
		case "alleyway_zone":
			return 6;
		case "crematorium_zone":
			return 7;
		default:
			zhcpb( "ZONE NAME" + zone_name +" DOESNT APPLY TO A ZONE" ,444);
			return 100;
	}
}

map_get_doors_accesible_in_room(room_id){
	doors = [];
	switch(room_id) 
	{
		case 0: //foyer
			doors[doors.size] = 2;
			doors[doors.size] = 11;
			doors[doors.size] = 6;
			doors[doors.size] = 9;
			break;
	    case 1: // vip_zone
	        doors[doors.size] = 2;
	        doors[doors.size] = 3;
	        doors[doors.size] = 4;
	        break;
	    case 2: // dining_zone
	        doors[doors.size] = 3;
	        doors[doors.size] = 4;
	        doors[doors.size] = 7;
	        break;
	    case 3: // dressing_zone
	        doors[doors.size] = 7;
	        doors[doors.size] = 5;
	        break;
	    case 4: // stage_zone
	        doors[doors.size] = 5;
	        doors[doors.size] = 1;
	        doors[doors.size] = 0;
	        if(flag("curtains_done")){
	           	doors[doors.size] = 6;
	    		doors[doors.size] = 9;
	    	}
	        break;
	    case 5: // west_balcony_zone
	        doors[doors.size] = 1;
	        doors[doors.size] = 0;
	        doors[doors.size] = 8;
	        break;
	    case 6: // alleyway_zone
	        doors[doors.size] = 8;
	        doors[doors.size] = 10;
	        break;
	    case 7: // crematorium_zone
	        doors[doors.size] = 10;
	        doors[doors.size] = 11;
	        break;
	    case 100:
	    	doors[doors.size] = 6;
	    	doors[doors.size] = 9;
	    	if(flag("curtains_done")){
	    	 	doors[doors.size] = 0;
				doors[doors.size] = 1;
				doors[doors.size] = 5;
	        }
	        break;
	}
	return doors;
}

map_get_room_name(room_id){
	switch(room_id){
		case 0:
			return "foyer room";
		case 1:
			return "vip room";
		case 2:
		return "dining room";
		case 3:
		return "dressing room";
		case 4:
		if(flag("curtains_done"))
			return "stage & theater room";
		return "stage room";
		case 5:
		return "west balcony room";
		case 6:
		return "alleyway room";
		case 7:
		return "crematorium room";
		case 100:
		return "theater room";
		default:
		zhcpb( "ROOM ID "+ room_id + "NOT DESIGNATED TO ROOM"  ,444);
		return 100;
	}
}

Get_Zone_Room_ID_Special(zone_name, door_id, power_on){
	if(!power_on)
		return Get_Zone_Room_ID(zone_name);


	right = true;
	left = false;
	switch (door_id){
		case 2:
		case 4:
		case 3:
		case 7:
		case 5:
			break;
		default:
			right = false;
			left = true;
	}


	if(zone_name == "foyer_zone" || zone_name == "foyer2_zone")
			return 0;
	//-----
	else if(zone_name == "vip_zone"){
			if(left)
				return undefined;
			return 1;
		}
	else if(zone_name == "dining_zone"){
			if(left)
				return undefined;
			return 2;
		}
	else if(zone_name == "dressing_zone"){
			if(left)
				return undefined;
			return 3;
		}
	//-----
	else if(zone_name == "stage_zone"){
			if(left)
				return 2;
			return 4;
		}
	else if(zone_name == "theater_zone"){
			if(left)
				return 1;
			return 5;
		}
	//-----
	else if(zone_name == "west_balcony_zone"){
			if(right)
				return undefined;
			return 3;
		}
	else if(zone_name == "alleyway_zone"){
			if(right)
				return undefined;
			return 4;
		}
	else if(zone_name == "crematorium_zone"){
			if(right)
				return undefined;
			return 5;
		}
	return 100;
}

player_is_in_dead_zone(player, door_id){	//run after "zone_info_updated"
	/*if(!IsDefined( player )){
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];
			 if(
				(player.current_zone == "dining_zone" && player IsTouching( level.zones["dining_zone"].volumes[2] )) ||
				(player.current_zone == "stage_zone"  && player IsTouching( level.zones["stage_zone"].volumes[0] ))
				)
			 	return true;
		}
		return false;
	}*/
	//IPrintLn( player.origin[0], player.origin[1], player.origin[2] );
	if(!isDefined(player.current_zone))
		return false;
	o = (!IsDefined( door_id ) || door_id == 4 || door_id == 3 ) && player.current_zone == "dining_zone";
	if(o)
		return player IsTouching( level.zones["dining_zone"].volumes[2] );
	o = (!IsDefined( door_id ) || door_id == 1 || door_id == 0 ) && player.current_zone == "stage_zone";
	if(o)
		return player IsTouching( level.zones["stage_zone"].volumes[0] );
	o = (!IsDefined( door_id ) || door_id == 6 || door_id == 9 ) && player.current_zone == "theater_zone";
	if(o)
		//return player IsTouching( level.zones["theater_zone"].volumes[1] ); doesnt really work the way i want it to.
		return player IsTouching( level.zones["theater_zone"].volumes[1] && player.origin[1] < -185 );

	return false;
}

can_close_door(){	//run after "zone_info_updated"
	door_id = self get_door_id();
	if(door_id == 4 || door_id == 3){
		o = zone_is_occupied_rn("dining_zone");
		//if(o && a_player_is_close_to_door_id(3,380)){ //replace for a trigger check fucntion
		if(o && player_is_touching(level.zones["dining_zone"].volumes[2]))
			return false;
		else 
			return !a_player_is_close_to_door_id(3, 230) && !a_player_is_close_to_door_id(4, 230);
	} else if(door_id == 1 || door_id == 0){
		o = zone_is_occupied_rn("stage_zone");
		//if(o && a_player_is_close_to_door_id(1,360))
		if(o && player_is_touching(level.zones["stage_zone"].volumes[0]))
			return false;
		else 
			return !a_player_is_close_to_door_id(1, 280) && !a_player_is_close_to_door_id(0, 280);
	}else if(door_id == 6 || door_id == 9){
		o = zone_is_occupied_rn("theater_zone");
		//if(o && a_player_is_close_to_door_id(1,360))
		if(o){
			players = get_players();
			for(i = 0; i < players.size; i++){
				player = players[i];
				//zhcp(int( player.origin[0]) +","+ int(player.origin[1]) +","+ int(player.origin[2]) ,444);
				if(player.current_zone == "theater_zone" && player.origin[1] < -185)
				//if(o && player_is_touching(level.zones["theater_zone"].volumes[1]))
					return false;
			}
		}
		//else 
			return !a_player_is_close_to_door_id(6, 230) && !a_player_is_close_to_door_id(9, 230);
	}else{
		return !self a_player_is_close_to_door(100);
	}
}
set_sister_door(){
	zombie_doors = GetEntArray( "zombie_door", "targetname" ); 
	switch(self get_door_id())
	{
		case 3:
			self.sister_door = zombie_doors[4];
			break;
		case 4:
			self.sister_door = zombie_doors[3];
			break;
		case 1:
			self.sister_door = zombie_doors[0];
			break;
		case 0:
			self.sister_door = zombie_doors[1];
			break;
		case 6:
			self.sister_door = zombie_doors[9];
			break;
		case 9:
			self.sister_door = zombie_doors[6];
			break;
		default:
			self.sister_door = self;
			break;
	}
}

