#include clientscripts\_utility;


main_start()
{
}


main_end()
{
}

client_systems_message_handler(clientnum, state, oldState)
{
	tokens = StrTok(state, ":");

	name = tokens[0];
	message = tokens[1];

	if(isdefined(level.client_systems) && isdefined(level.client_systems[name]))
		level thread [[level.client_systems[name]]](clientnum, message);
}
