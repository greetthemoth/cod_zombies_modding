#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
interpolate(value, minimum, maximum){
   return (value - minimum) / (maximum - minimum);
}
pow(n, power){
	if(power == 0)
		return 1;
	for(i = 1; i < power; i++){
		n*=n;
	}
	return n;
}
define_or(s,or){
	if(IsDefined( s ))
		return s;
	return or;
}
undefine_if_same_as(a, b){
	if(a == b){
		return undefined;
	}
	return a;
}

zhcp(msg, id){
	if(level.ZHC_TESTING_LEVEL < 0)
		return;

	if(IsArray(msg)){
		msg = array_to_string(msg);
	}
	if(IsArray( id ) && !IsString( id )){
		for( i = 0; i < id.size; i++ ){
			if(!isDefined(id[i]) || maps\ZHC_zombiemode_zhc::can_send_msg_level(id[i])){
				IPrintLn( msg );
				return;
			}
		}
	}else if(!isDefined(id) || maps\ZHC_zombiemode_zhc::can_send_msg_level(id))
		IPrintLn( msg );
}
zhcpb(msg, id){
	if(level.ZHC_TESTING_LEVEL < 0)
		return;
	if(IsArray(msg)){
		msg = array_to_string(msg);
	}
	if(IsArray( id ) && !IsString( id )){
		for( i = 0; i < id.size; i++ ){
			if(!isDefined(id[i]) || maps\ZHC_zombiemode_zhc::can_send_msg_level(id[i])){
				IPrintLnBold( msg );
				return;
			}
		}
	}else if(!isDefined(id) || maps\ZHC_zombiemode_zhc::can_send_msg_level(id))
		IPrintLnBold( msg );
}

player_is_touching(trigger, player){
	if(!isDefined(player)){
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];
			if(player IsTouching(trigger))
				return true;
		}
		return false;
	}

	return player IsTouching(trigger);
}


debug_current_player_volume(){
	players = get_players();
	zkeys = GetArrayKeys( level.zones );
	
	for( p = 0; p < players.size; p++ )
	{
		//iprintln("player "+i +"/"+players.size+ " is valid:" + (is_player_valid( players[i])) );
		if( is_player_valid( players[p]) ) 
		{
			for(z = 0; z < zkeys.size; z++ ){
				zone_name = zkeys[z];
				for (i = 0; i < level.zones[zone_name].volumes.size; i++)
				{
					if (players[p] IsTouching(level.zones[zone_name].volumes[i]) )
					{
						IPrintLn("p"+p +": "+zone_name+ " volume "+i);	//testo
					}
				}
			}
		}
	}
}

get_first_shared_value_in_arrays( array1, array2 )
{
	if( !IsDefined( array1 ) || !IsDefined( array2 ) )
	{
		return undefined;
	}

	for( i = 0; i < array1.size; i++ )
	{
		for( j = 0; j < array2.size; j++ )
		{
			if( array1[ i ] == array2[ j ] )
			{
				return array1[ i ];
			}
		}
	}

	return undefined;
}
get_shared_values_in_arrays( array1, array2 )
{
	shared = [];

	if( !IsDefined( array1 ) || !IsDefined( array2 ) )
	{
		return shared;
	}

	for( i = 0; i < array1.size; i++ )
	{
		for( j = 0; j < array2.size; j++ )
		{
			if( array1[ i ] == array2[ j ] )
			{
				// Prevent duplicates in result
				if( !is_in_array( shared, array1[ i ] ) )
				{
					shared[ shared.size ] = array1[ i ];
				}

				break;
			}
		}
	}

	return shared;
}

array_to_string(array, delimiter)
{
	if(!IsDefined( delimiter ))
		delimiter = ", ";
	if(!isDefined(array) || array.size <= 0)
	{
		return "";
	}

	str = "" + array[0];

	for(i = 1; i < array.size; i++)
	{
		str += delimiter + array[i];
	}

	return str;
}