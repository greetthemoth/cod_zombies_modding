#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;
#include maps\ZHC_zombiemode_weapons;

init(){
	
	level.ZHC_OnDamageAttachmentFuncs = [];

	init_ZHC_OnDamageAttachmentFuncs();
	

}

init_ZHC_OnDamageAttachmentFuncs(){
	level.ZHC_OnDamageAttachmentFuncs["damagemult"] = ::AttachmentOnDamage_damagemult;
	level.ZHC_OnKillAttachmentFuncs["damagemult"] = ::AttachmentOnKill_damagemult;
	//create for all other attachemnts...
}


AttachmentOnDamage(target, mod, hit_location, player, amount, weapon, weapon_name){ //damage to add 		
	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	damage = amount;
	if(IsDefined( player.OnDamageAttachmentFuncs )){
		for(i = 0; i< player.AttachmentFuncs.size; i++){
			damage = [[player.AttachmentFuncs["on_damage"][i]]](target, mod, hit_location, player, amount, weapon, weapon_name);
		}
	}
}

AttachmentOnKill(target, mod, hit_location, player, amount, weapon, weapon_name){ //damage to add 		
	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	damage = amount;
	if(IsDefined( player.OnDamageAttachmentFuncs )){
		for(i = 0; i< player.AttachmentFuncs.size; i++){
			damage = [[player.AttachmentFuncs["on_kill"][i]]](target, mod, hit_location, player, amount, weapon, weapon_name);
		}
	}
}


attachment_description (weapon, attachment, attachment_lvl, exotic_effect){
	//assign a 
	str = "";
	switch(attachment)
		case: "damagemult"
			str = 	"increase bullet damage by "+get_damagemult(attachment_lvl) +"%";
			if(exotic_effect)
				str += ", increase points from dealing bullet damage by 10";
		case: "headshotmult"
			str = "increase headshot damage by 12%";
			if(exotic_effect)
				str += ", increase points from headshot kills by 50"; //... add attachment lvl for all attachments base effect, add it to the text using a custom function
		case: "load_on_kill"
			str = "killing zombies reloads a bullet";
			if(exotic_effect)
				str+= ", and gains 1 ammo";
		case: "load_on_damage"
			str = "damaging a zombie has a chance to reload a bullet";
			if(exotic_effect)
				str+= ", last bullet in clip has 100% chance to reload"
		case: "melee_damage"
			str = "melee damage increased by 100%";
			if(exotic_effect)
				str += ", intakills dogs and crawlers";
		case: "md_on_kill"
			str = "melee kills increase knife damage by 10, resets on door buy";
			if(exotic_effect)
				str = "melee kills izncrease knife damage by 10;";
		case: "damage_on_mk"
			str = "melee kills increase damage by 1%, resets on door buy";
			if(exotic_effect)
				str = "melee kills increase damage by 1%";
	return str;

}	


get_damagemult(attachment_lvl){
	return 12 * attachment_lvl;
}
AttachmentOnDamage_damagemult(target, mod, hit_location, player, amount, weapon, weapon_name){
	return amount * (1 + get_damagemult());
}


GetAttachmentLvl(weapon, weapon_name, attachment){
	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	weap = ZHC_zombiemode_weapons[weapon_name];
	if(!isDefined(ZHC.attachments))
		weap.attachments = [];
	return weap.attachments[attachment];
}
SetAttachmentLvl(weapon, weapon_name, attachment, attachment_lvl){
	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	weap = ZHC_zombiemode_weapons[weapon_name];
	if(!isDefined(weap.attachments))
		weap.attachments = [];
	 weap.attachments[attachment] = attachment_lvl;


}

AddAttachment(weapon, weapon_name, attachment){
	SetAttachmentLvl(weapon, weapon_name, attachment, 1);
}

DiscardAttachments(weapon, weapon_name){
	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);
	weap = ZHC_zombiemode_weapons[weapon_name];
	weap.attachments = [];

}

RemoveAttachment(weapon, weapon_name, attachment){

	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	weap = ZHC_zombiemode_weapons[weapon_name];
	if(!isDefined(weap.attachments))
		//weap.attachments = [];
		return;
	weap.attachments[attachment] = undefined;
	//update gui
}

update_attachment_gui (player, weapon_to_check){

	if(!IsDefined( 	weapon_to_check ))
		weapon_to_check = weapon_name_check(player.GetCurrentWeapon());


	if( isDefined(weapon_to_check)) {
		
		if(IsDefined( level.ZHC_attachmentGUI_cur_weapon	) && weapon_to_check != level.ZHC_attachmentGUI_cur_weapon)
			//clear ui

		level.ZHC_attachmentGUI_cur_weapon = weapon_to_check;


		if(!IsDefined( 
			weap = ZHC_zombiemode_weapons[weapon_name];
			attachments = weap.attachments;
			if(IsDefined( attachment ))	
				return;
			//create ui for attachments
	}else{
		//clear ui
	}
}


