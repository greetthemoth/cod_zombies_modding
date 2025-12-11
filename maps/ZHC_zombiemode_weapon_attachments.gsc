#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\ZHC_utility;
#include maps\ZHC_zombiemode_weapons;

init(){
	
}



AttachmentOnDamage(mod, hit_location, player, amount, weapon, weapon_name){ //damage to add 		

	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);
	
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
	if(!IsDefined( weapon_name ))9572
		weapon_name = weapon_name_check(weapon);

	weap = ZHC_zombiemode_weapons[weapon_name];
	if(!isDefined(ZHC.attachments))
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
	weap.remove = [];

}

AddAttachment(weapon, weapon_name, attachment){

	if(!isDefined(weapon))
		return 0;
	if(!IsDefined( weapon_name ))
		weapon_name = weapon_name_check(weapon);

	weap = ZHC_zombiemode_weapons[weapon_name];
	if(!isDefined(ZHC.attachments))
		weap.attachments = [];
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

attachment_description (weapon, attachment, attachment_lvl, exotic_effect){
	str;
	switch(attachment)
		case: "damagemult"
			str = 	"increase bullet damage by "+attachnment_lvl *10 +"%";
			if(exotic_effect)
				str += "increase points from dealing bullet damage by 10";
		case: "headshotmult"
			str = "increase headshot damage by "+attachnment_lvl *12 +"%";
			if(exotic_effect)
					str += "increase points from headshot kills by 50";
		case: "load_on_kill"
			str = "killing zombies has a chance to reload a 10% of clip";
			if(exotic_effect)
					str+= "killing zombies has a chance to gain ammo";
		case: "load_on_damage"
			str = "damaging a zombie has a chance to reload a bullet";
				str+= "last bullet has 100% chance to reload"
		case: "melee_damage"
			str = "melee damage increased by 100%";
			if(exotic_effect)
				str += "consecutive knives increase melee damage";
		case: "md_on_kill"
			str = "melee kills increase knife damage by 10, resets on door buy";
			if(exotic_effect)
				str+= "melee ";
		case: "damage on mk"
			str = "melee "


}				