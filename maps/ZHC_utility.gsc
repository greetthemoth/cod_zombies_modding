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
zhcp(msg, id){
	if(level.ZHC_TESTING_LEVEL < 0)
		return;
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