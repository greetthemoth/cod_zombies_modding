#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;
//Kino Der Toten theater specific fuctions


init(){
	//for curtain reset
	PrecacheModel( "zombie_theater_curtain" );

	level.map_get_room_info = ::map_get_room_info;
	level.Get_Other_Zone = ::Get_Other_Zone ;
	level.room_id_can_be_stopped = ::room_id_can_be_stopped ;
	//level.map_wait_to_update_rooms = ::map_wait_to_update_rooms ;
	level.map_get_zone_room_id = ::map_get_zone_room_id ;
	level.map_get_doors_accesible_in_room = ::map_get_doors_accesible_in_room ;
	level.map_get_room_name = ::map_get_room_name ;
	//level.Get_Zone_Room_ID_Special = ::Get_Zone_Room_ID_Special ;
	level.player_is_in_dead_zone = ::player_is_in_dead_zone ;
	level.can_close_door = ::can_close_door ;
	level.set_sister_door = ::set_sister_door ;

	level.zhc_additional_round_logic = ::first_room_harder;
	level.map_init_set_additional_room_info = ::init_set_additonal_room_info;
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
	i = door  maps\_zombiemode_blockers::get_door_id();

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

init_set_additonal_room_info(room_id){
	switch( room_id ){
		case 1: //vip room
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 0.75;
		case 3: //dressing room
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 0.5;
		case 5: //west balcony room
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 0.5;	
		case 6: //alley way room
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 0.65;	
		case 7: //crematorium
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 0.65;
		default:
			level.ZHC_room_info[room_id]["spawner_score_mult"] = 1;
	}
	
}

Get_Zone_Room_ID_Special(zone_name, door_id, power_on){
	if(!power_on)
		return map_get_zone_room_id(zone_name);


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
	door_id = self maps\_zombiemode_blockers::get_door_id();
	if(door_id == 4 || door_id == 3){
		o = maps\_zombiemode_blockers::zone_is_occupied_rn("dining_zone");
		//if(o && a_player_is_close_to_door_id(3,380)){ //replace for a trigger check fucntion
		if(o && player_is_touching(level.zones["dining_zone"].volumes[2]))
			return false;
		else 
			return !maps\_zombiemode_blockers::a_player_is_close_to_door_id(3, 230) && !maps\_zombiemode_blockers::a_player_is_close_to_door_id(4, 230);
	} else if(door_id == 1 || door_id == 0){
		o = maps\_zombiemode_blockers::zone_is_occupied_rn("stage_zone");
		//if(o && a_player_is_close_to_door_id(1,360))
		if(o && player_is_touching(level.zones["stage_zone"].volumes[0]))
			return false;
		else 
			return !maps\_zombiemode_blockers::a_player_is_close_to_door_id(1, 280) && !maps\_zombiemode_blockers::a_player_is_close_to_door_id(0, 280);
	}else if(door_id == 6 || door_id == 9){
		o = maps\_zombiemode_blockers::zone_is_occupied_rn("theater_zone");
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
			return !maps\_zombiemode_blockers::a_player_is_close_to_door_id(6, 230) && !maps\_zombiemode_blockers::a_player_is_close_to_door_id(9, 230);
	}else{
		return !self maps\_zombiemode_blockers::a_player_is_close_to_door(100);
	}
}
set_sister_door(){
	zombie_doors = GetEntArray( "zombie_door", "targetname" ); 
	switch(self maps\_zombiemode_blockers::get_door_id())
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












get_lightning_teleport_destinations(attempt){

	//dest_room_origins = []; // set the origins we want
	/*{ //testo temp
		doors = GetEntArray( "zombie_door", "targetname" );
		for( i =0; i < doors.size; i++	 ){
			if(!doors[i]._door_open)
				continue;
			all_trigs = getentarray( doors[i].target, "target" ); 
			for( t = 0; t < all_trigs.size; t++ )
			{
				dest_room_origins[dest_room_origins.size] = all_trigs[t].origin;
			}
		}
	}*/
	////////dest_room_origins = array_add( dest_room_origins, ZHC_zombiemode_zhc::get_random_active_dog_spawn_pos() );
	switch(attempt){
		case 0:
		return maps\ZHC_zombiemode_zhc::get_inactive_dog_spawn_positions();
		case 1:
		return maps\ZHC_zombiemode_zhc::get_active_dog_spawn_positions();
	}
}

get_lighnting_spots(){
	//return maps\ZHC_zombiemode_zhc::get_random_active_dog_spawn_pos();
	return maps\ZHC_zombiemode_zhc::get_dog_spawn_positions_in_room(4);
}

can_spawn_lightning_check(){
	return maps\ZHC_zombiemode_roundflow::Get_Room_Info(4, "occupied");
}

get_lightning_delay(){
	dif = maps\ZHC_zombiemode_roundflow::Get_Room_Info(4, "flow_difficulty") + 1;
	if(dif <= 0){
		return undefined;
	}
	return 10/dif;
}

ZHC_manage_lightning(){
	level.ZHC_theater_spawning_lightning = false;
	//level waittill("zone_info_updated");
	wait_network_frame();	//wait till room info is set
	while(1){
		if(level.power_on){
			thread start_spawning_lightning(get_lightning_delay());
			zhcpb("electricity waiting to turn off power, or update", 300);
			level waittill_any( "electricity_off", "zhc_update_flow_difficulty_roomId_4","zhc_stop_spawning_lightning"  );
			if(level.ZHC_theater_spawning_lightning){
				level.ZHC_theater_spawning_lightning = false;
				level notify( "zhc_stop_spawning_lightning" );
			}
			wait_network_frame();
		}else{
			zhcpb("electricity waiting to turn on power", 300);
			level waittill( "electricity_on");
			wait_network_frame();
		}
	}
}
	
start_spawning_lightning(delay){
	if(!IsDefined( delay )){
		zhcpb("delay invalid. not spawning now", 300);
		return;
	}else{
		zhcpb("delay "+delay, 300);
	}
	level.ZHC_theater_spawning_lightning = true;
	level endon( "zhc_stop_spawning_lightning" );
	

	pad = getent( "trigger_teleport_pad_0", "targetname" );
	pad thread stop_electric_sound();

	dps = get_lighnting_spots();
	while(true){
		if(!can_spawn_lightning_check()){
			//zhcpb("failed check", 300);
			wait(0.5);
			continue;
		}
		dp = dps[RandomInt( dps.size - 1 )];
		if(isDefined(dp)){
			// add 3rd person fx
			maps\zombie_theater_teleporter::teleport_pad_start_exploder( 0 );
			//zhcpb("dp defined spawning lightning...", 300);

			//pad thread maps\zombie_theater_teleporter::teleport_2d_audio();
			pad thread electric_sound();

			pad thread zhc_teleport_fps_effect(false);
			pad thread zhc_teleport_players(true);

			thread spawn_lightning_teleport(dp);
			wait(delay);
		}
		else{
			zhcpb("dp not defined", 300);
			wait(0.5);
		}
	}
}

electric_sound(){
	self notify("zhc_reset_audio_timer");
	self endon("zhc_reset_audio_timer");
	if(!is_true(self._zhc_playing_electric_sound)){
		self._zhc_playing_electric_sound = true;
		self playsound( "zmb_elec_start" );
	    self playloopsound( "zmb_elec_loop" );
	}
	wait(1.8);
	self stoploopsound();
	self._zhc_playing_electric_sound = false;
}

stop_electric_sound(){
	level waittill( "zhc_stop_spawning_lightning" );
	self stoploopsound();
}

spawn_lightning_teleport(origin){
	thread maps\_zombiemode::dog_despawn_sound_effect(origin);
	playfx(level._effect["lightning_dog_spawn"], origin);
	//wait(0.5);

	effect_trigger  = Spawn( "trigger_radius", origin, 0, 200, 12 );
	effect_trigger thread zhc_teleport_fps_effect(true);
	
	
	trigger  = Spawn( "trigger_radius", origin, 0, 150, 12 );

	//AUDIO
	//trigger thread maps\zombie_theater_teleporter::teleport_2d_audio();

	trigger thread zhc_teleport_players();
	wait(1.75); //wait for audio stuff to end.
	trigger delete();

	//playsoundatposition( "evt_beam_fx_2d", (0,0,0) );
    //playsoundatposition( "evt_pad_cooldown_2d", (0,0,0) );
}

zhc_teleport_fps_effect(do_delete){
	
	//fps fx
	self thread  maps\zombie_theater_teleporter::teleport_pad_player_fx(undefined );

	wait(1.5);
	// end fps fx
	self notify( "fx_done" );
	if(do_delete)
		self delete();
}

zhc_teleport_players(pad_effect_if_teleport)
{
	// wait a bit
	wait( 1.5 );

	// Activate the TP zombie kill effect
	thread teleport_nuke( undefined, self.origin, 150);	// Max range 300

	attempt_num = 0;
	dest_room_origins = get_lightning_teleport_destinations(attempt_num);

	if(dest_room_origins.size == 0){
		attempt_num++;
		dest_room_origins = array_combine( dest_room_origins , get_lightning_teleport_destinations(attempt_num));
		if(dest_room_origins.size == 0)
			return;
	}
	

	players = get_players( );
	players_teleporting = [];
	for ( i = 0; i < players.size; i++ )
	{	
		if ( isdefined( players[i] ) )
		{	
			if(isDefined(players[i].teleport_origin)){
				zhcpb("already teleporting", 300);
				continue;
			}
			if ( self maps\zombie_theater_teleporter::player_is_near_pad( players[i]) == false){
				//zhcpb("not touching teleporter", 300);
				continue;
			}
			players_teleporting [players_teleporting.size] = players[i];
		}
	}
	
	if( dest_room_origins.size < players_teleporting.size){
		if(attempt_num == 0){
			attempt_num++;
			dest_room_origins = array_combine( dest_room_origins , get_lightning_teleport_destinations(attempt_num));
			if(dest_room_origins.size < players_teleporting.size)
				return;
		}else
			return;
	}

	if(players_teleporting.size == 0)
		return;

	if(is_true(pad_effect_if_teleport)) //this will cause the teleport effect on the pad.
		// add 3rd person beam fx - threading this now so it plays the return fx
		thread maps\zombie_theater_teleporter::teleport_pad_end_exploder(0);
	

	player_radius = 16;
	slot = undefined;
	start = undefined;

	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);
	
	
	dest_room = [];
	dest_room =  maps\zombie_theater_teleporter::get_array_spots("teleport_room_", dest_room);
	maps\zombie_theater_teleporter::initialize_occupied_flag(dest_room); // the original ver of fuction not our modified vrsion
	maps\zombie_theater_teleporter::check_for_occupied_spots(dest_room, players, player_radius); // the original ver of fuction not our modified vrsion

	
	// send players to a black room to flash images for a few seconds
	for ( i = 0; i < players_teleporting.size; i++ )
	{	
			
		// find a free space at the projection room
		slot = i;
		start = 0;
		while ( dest_room[slot].occupied && start < dest_room.size ) //4
		{
			start++;
			slot++;
			if ( slot >= dest_room.size ) //4
			{
				slot = 0;
			}
		}
		

		dest_room[slot].occupied = true;
		players_teleporting[i].inteleportation = true;	//shouldn't matter if we set this to true multiple times
		
		// DCS: commenting out for integration of code function.
		//players_teleporting[i] settransported( 0 );		// turn off the fps fx in case it was still playing
		
		players_teleporting[i] disableOffhandWeapons();
		players_teleporting[i] disableweapons();
		
		if( players_teleporting[i] getstance() == "prone" )
		{
			desired_origin = dest_room[slot].origin + prone_offset;
		}
		else if( players_teleporting[i] getstance() == "crouch" )
		{
			desired_origin = dest_room[slot].origin + crouch_offset;
		}
		else
		{
			desired_origin = dest_room[slot].origin + stand_offset;
		}			
		
		players_teleporting[i].pre_teleport_angles  = players_teleporting[i].angles;
		players_teleporting[i].teleport_origin = spawn( "script_origin", players[i].origin );
		players_teleporting[i].teleport_origin.angles = players_teleporting[i].angles;
		players_teleporting[i] linkto( players_teleporting[i].teleport_origin );
		players_teleporting[i].teleport_origin.origin = desired_origin;
		
		players_teleporting[i] FreezeControls( true );
		wait_network_frame();
		setClientSysState( "levelNotify", "black_box_start", players_teleporting[i] );			
		players_teleporting[i].teleport_origin.angles = dest_room[slot].angles;
	}


	// everybody left the pad before they actually teleported
	if (!IsDefined(players_teleporting) || (IsDefined(players_teleporting) && players_teleporting.size < 1))
		return;
		
	wait(2);
	
	players_teleporting = array_removeUndefined(players_teleporting);

	//dest_room_origins = []; // set the origins we want
	//dest_room_angles = []; // set the angles we want
	
	
	dest_room_dice = [];
	for(i = 0; i < dest_room_origins.size; i++){
		dest_room_dice[dest_room_dice.size] = i;
	}
	dest_room_dice = array_randomize( dest_room_dice );
	//dest_room_origins = array_randomize( dest_room_origins );

	dest_room_occupied = initialize_occupied_flag(dest_room_origins);
	dest_room_occupied = check_for_occupied_spots(dest_room_occupied,dest_room_origins, players, player_radius);


	 

	for ( i = 0; i < players_teleporting.size; i++ )
	{	
		if(!isDefined(players_teleporting[i]))
		{
			continue;
		}
		slot = 0;
		start = 0;
		while ( dest_room_occupied[dest_room_dice[slot]] && start < dest_room_origins.size )
		{
			start++;
			slot++;
			if ( slot >= dest_room_origins.size )
			{
				slot = 0;
			}
		}
		
		
		
		dest_room_occupied[dest_room_dice[slot]] = true;
		setClientSysState( "levelNotify", "black_box_end", players_teleporting[i] );
			
		// remove script orgin we used in teleporting to black room
		assert( IsDefined( players_teleporting[i].teleport_origin ) );
		players_teleporting[i].teleport_origin delete();
		players_teleporting[i].teleport_origin = undefined;

		players_teleporting[i] setorigin( dest_room_origins[dest_room_dice[slot]] );
		players_teleporting[i] setplayerangles (players_teleporting[i].pre_teleport_angles);
		players_teleporting[i].pre_teleport_angles = undefined;
		//if(IsDefined( Object ))
		//players_teleporting[i] setplayerangles( define_or(dest_room_angles[dest_room_dice[slot]] , old_player_angles[i] ));
		
		//if (loc != "eerooms")
		{
			players_teleporting[i] enableweapons();
			players_teleporting[i] enableoffhandweapons();
			players_teleporting[i] FreezeControls( false );	
		}
		/*else // in special rooms can now move. 
		{
			players_teleporting[i] FreezeControls( false );
		}*/
			
		setClientSysState("levelNotify", "t2bfx", players_teleporting[i]);
		players_teleporting[i] maps\zombie_theater_teleporter::teleport_aftereffects();
			
		//thread extra_cam_startup();
		players_teleporting[i].inteleportation = false;	
		teleport_nuke( 8, dest_room_origins[dest_room_dice[slot]], 20); //max 8 zombies
	}

	////level.eeroomsinuse = undefined;
}
initialize_occupied_flag(dests)
{
	dest_is_occupied = [];
	for ( i = 0; i < dests.size; i++ )
	{
		dest_is_occupied[i] = false;					
	}
	return dest_is_occupied;
}
check_for_occupied_spots(dest_is_occupied, dests, players, player_radius)
{	
	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( players[i] ) )
		{
			for ( j = 0; j < dests.size; j++ )
			{
				if ( !dest_is_occupied[j] )
				{
					dist = Distance2D( dests[j], players[i].origin );
					if ( dist < player_radius )
					{
						dest_is_occupied[j] = true;
					}
				}
			}
		}
	}
	return dest_is_occupied;
}
//	Kill anything near the teleport
teleport_nuke( max_zombies, origin, range )
{
	zombies = getaispeciesarray("axis");

	zombies = get_array_of_closest( origin, zombies, undefined, max_zombies, range );

	for (i = 0; i < zombies.size; i++)
	{
		wait (randomfloatrange(0.2, 0.3));
		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}
		
// 		if( is_magic_bullet_shield_enabled( zombies[i] ) )
// 		{
// 			continue;
// 		}

		if(zombies[i].animname == "zombie_dog")	//my version doesnt kill dogs
			continue;

		if( isDefined( zombies[i].animname ) && 
			( zombies[i].animname != "boss_zombie" && zombies[i].animname != "ape_zombie" ) &&
			zombies[i].health < 5000)
		{
			zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
		}

		zombies[i] dodamage( zombies[i].health + 100, zombies[i].origin );
		playsoundatposition( "nuked", zombies[i].origin );
	}
}