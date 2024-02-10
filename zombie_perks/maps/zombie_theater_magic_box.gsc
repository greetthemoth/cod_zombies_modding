#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

//************************************************************************************
//
//	Changes lights of Map for location
//
//************************************************************************************

magic_box_init()
{
	// Array must match array in zombie_theater.csc
	// Start at 'start_chest' then order clockwise - finishing in the middle.
	
	// DCS: added to fix non-attacking dogs in alley, placed here because smallest theater specific script file.
	level.dog_melee_range = 120;	
	
	level._BOX_INDICATOR_NO_LIGHTS = -1;
	level._BOX_INDICATOR_FLASH_LIGHTS_MOVING = 99;
	level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE = 98;

	level.ZHC_INDICATOR_MARK_ALL_TEDDYS = true;
	level.ZHC_INDICATOR_MARK_ALL_ACTIVE_CHESTS = true;
	level.ZHC_INDICATOR_MARK_MOVING_FLASH = false;
	
	level._box_locations = array(	"start_chest",
																"foyer_chest",
																"crematorium_chest",
																"alleyway_chest",
																"control_chest",
																"stage_chest",
																"dressing_chest",
																"dining_chest",
																"theater_chest");
																
	
	level thread magic_box_update();					
	level thread watch_fire_sale();
}

get_location_from_chest_index(chest_index)
{
	chest_loc = level.chests[ chest_index ].script_noteworthy;
	
	for(i = 0; i < level._box_locations.size; i ++)
	{
		if(level._box_locations[i] == chest_loc)
		{
			return i;
		}
	}
	
	AssertMsg("Unknown chest location - " + chest_loc);
}

box_indicator_scouting(){
	chests = level.chests;
	//box_indicator_off();
	for(i = 0; i < chests.size; i++){
		if(is_true(chests[i].chest_origin.ZHC_has_teddy)){
			num = get_location_from_chest_index(i) + 200;
			setclientsysstate( "box_indicator", num);
		}else if(is_true(chests[i].ZHC_ALL_CHESTS_chest_active)){
			num = get_location_from_chest_index(i) + 200 + level._box_locations.size;
			//chests[i].chest_origin.ZHC_checked_for_teddy = true;			//dog round auto checks all non teddy rounds as teddy.
			setclientsysstate( "box_indicator", num);
		}else{
			num = 0-(get_location_from_chest_index(i) + level._box_locations.size + 200);
			setclientsysstate( "box_indicator", num);
		}
	}
}

box_indicator_off(){

	setclientsysstate( "box_indicator", -1);
}

box_indicator_flashing(){

	setclientsysstate( "box_indicator", level._BOX_INDICATOR_FLASH_LIGHTS_MOVING);
}

main_box_inidicator(){
	if(level.ZHC_ALL_CHESTS){
		if(level.ZHC_INDICATOR_MARK_ALL_ACTIVE_CHESTS){
			chests = level.chests;
			for(i = 0; i < chests.size; i++){
				if(is_true(chests[i].ZHC_ALL_CHESTS_chest_active)){
					num = get_location_from_chest_index(i) + 200;
					if(is_true(chests[i].chest_origin.ZHC_checked_for_teddy))
						num += level._box_locations.size;
					setclientsysstate( "box_indicator", num);
				}else{
					num = -1*(get_location_from_chest_index(i) + level._box_locations.size + 200);
					setclientsysstate( "box_indicator", num);
				}
			}
		}else
			box_indicator_off();
	}
	else
		setclientsysstate( "box_indicator", get_location_from_chest_index(level.chest_index));
}

magic_box_update()
{
	// Let the level startup
	wait(2);

	flag_wait( "power_on" );

	// Setup
	box_mode = "Box Available";
	wait_network_frame();
	power = true;
	
	// Tell client 
	
	main_box_inidicator();
	
	while( 1 )
	{	
		update_power = power != level.power_on;
		power = level.power_on;
		general_update = is_true(level.ZHC_update_box_indicator);
		level.ZHC_update_box_indicator = false;

		switch( box_mode )
		{
			// Waiting for the Box to Move
			case "Box Available":

				if(level.ZHC_INDICATOR_MARK_MOVING_FLASH && flag("moving_chest_now") ){
					if(level.power_on)
						box_indicator_flashing();	// flash everything.
					else
						box_indicator_off();

					box_mode = "Box is Moving";

				}else if(level.ZHC_INDICATOR_MARK_ALL_TEDDYS && flag("dog_round")){
					if(level.power_on)
						box_indicator_scouting();
					else
						box_indicator_off();
					
					box_mode = "Box is Scouting";

				}else if(update_power || general_update){
					if(level.power_on)
						main_box_inidicator();
					else
						box_indicator_off();
				}

				break;


			case "Box is Moving":

				
				
				// Waiting for the box to finish its move
				while( flag("moving_chest_now") )
				{
					update_power = power != level.power_on;
					power = level.power_on;
					if(update_power){
						if(level.power_on)
							box_indicator_flashing();	// flash everything.
						else
							box_indicator_off();
					}
					wait(0.1);
				}


				if(level.ZHC_INDICATOR_MARK_ALL_TEDDYS && flag("dog_round")){
					if(level.power_on)
						box_indicator_scouting();
					else
						box_indicator_off();

					box_mode = "Box is Scouting";

				}else{
					if(level.power_on)
						main_box_inidicator();
					else
						box_indicator_off();

					box_mode = "Box Available";

				}

				break;

			case "Box is Scouting":

				if(level.ZHC_INDICATOR_MARK_MOVING_FLASH &&  flag("moving_chest_now") )
				{
					 
					if(level.power_on)
						box_indicator_flashing();	// flash everything.
					else
						box_indicator_off();
					
					box_mode = "Box is Moving";

				}else if(!flag("dog_round")){

					if(level.power_on)
						main_box_inidicator();
					else
						box_indicator_off();

					box_mode = "Box Available";

				}else if(update_power || general_update){
					if(level.power_on)
						box_indicator_scouting();
					else
						box_indicator_off();
				}

				break;
		}

		wait( 0.5 );
	}
}



watch_fire_sale()
{
	while ( 1 )
	{
		level waittill( "powerup fire sale" );
		if(!level.power_on)	
			continue;																//added for mod
		setclientsysstate( "box_indicator", level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE );	// flash everything. 

		while ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0)
		{
			wait( 0.1 );
		}
		if(!level.power_on)	
			continue;	
		main_box_inidicator();
	}
}


//ESM - added for green light/red light functionality for magic box
turnLightGreen(name, playfx)
{
	//IPrintLnBold( "turned light green" );
	zapper_lights = getentarray( name, "script_noteworthy" );
	
	for(i=0;i<zapper_lights.size;i++)
	{
		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}
		
		if ( isDefined( playfx ) && playfx )
		{
			zapper_lights[i] setmodel("zombie_zapper_cagelight_green");	
			zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", ( zapper_lights[i].origin[0], zapper_lights[i].origin[1], zapper_lights[i].origin[2] - 10 ) );
			zapper_lights[i].fx setmodel("tag_origin");
			zapper_lights[i].fx.angles = zapper_lights[i].angles;
			playfxontag(level._effect["boxlight_light_ready"],zapper_lights[i].fx,"tag_origin");
		}
		else
			zapper_lights[i] setmodel("zombie_zapper_cagelight");	
	}
}

turnLightRed(name, playfx)
{	
	//IPrintLnBold( "turned light red" );
	zapper_lights = getentarray( name, "script_noteworthy" );

	for(i=0;i<zapper_lights.size;i++)
	{
		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}
		
		if ( isDefined( playfx ) && playfx )
		{
			zapper_lights[i] setmodel("zombie_zapper_cagelight_red");	
			zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", ( zapper_lights[i].origin[0], zapper_lights[i].origin[1], zapper_lights[i].origin[2] - 10 ) );
			zapper_lights[i].fx setmodel("tag_origin");
			zapper_lights[i].fx.angles = zapper_lights[i].angles;
			playfxontag(level._effect["boxlight_light_notready"],zapper_lights[i].fx,"tag_origin");
		}
		else
			zapper_lights[i] setmodel("zombie_zapper_cagelight");
	}
}
turnLightOff(name, playfx)
{	
	//IPrintLnBold( "turned light off" );
	zapper_lights = getentarray( name, "script_noteworthy" );

	for(i=0;i<zapper_lights.size;i++)
	{
		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		//if ( isDefined( playfx ) && playfx )
		//{
		//	zapper_lights[i] setmodel("zombie_zapper_cagelight");	
			//zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", ( zapper_lights[i].origin[0], zapper_lights[i].origin[1], zapper_lights[i].origin[2] - 10 ) );
			//zapper_lights[i].fx setmodel("tag_origin");
			//zapper_lights[i].fx.angles = zapper_lights[i].angles;
			//playfxontag(level._effect["boxlight_light_notready"],zapper_lights[i].fx,"tag_origin");
		//}
		//else
			zapper_lights[i] setmodel("zombie_zapper_cagelight");
	}
}