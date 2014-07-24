#define CLIENT_ONLY

const SColor M_COLOR = SColor(0, 51, 116, 51);
		
string[] chats = {"Don't forget to access the help menus with P and Z.",
				 "#Sadboyyyyyzzzzz",
				 "If you're attacked while casting a teleport spell the spell will fail.",
				 "The maximum amount of knights that can be commanded with a scroll of command is 20",
				 ">2014 >playing as an archer",
				 "Mook knights sure are dumb, but AI code sure is tedious",
				 "Rangers can fire a 5 arrow legolas shot",
				 "Coming soon: XP system",
				 "Coming soon: Underground dungeon with creeps and bosses",
				 "Coming soon: Armor/Weapon system",
				 "Think you can take on STORM in a clan war? Message Nand or Fiend",
				 "Props to Aphelion's RP for showing just how much this game can be modified",
				 "Coming soon: Upgradeable units",
				 //"Can you do sprite art? Shoot me a message on the forums",
				 "Don't forget to post in the forum thread if you like the mod!",
				 "Suggestions? Post them in the HOTR Kag2d.com forum thread",
				 "HOTR stands for Heroes of the Round",
				 "HOTR stands for Heroes of the Round",
				 "Found a bug? Please message me asap on the forums",
				 "Frozen with a red circle? IT'S MY FAULT, help me fix the bug by sending me(Nand) your latest console log",
				 "This mod was created and designed by Nand",
				 "This mod was created and designed by Nand",
				 "This mod was created and designed by Nand",
				 "Thanks to startselect3 for helping me test and annoying the shit out of me while doing it",
				 "Interested in writing quotes for the traders? Message me on the forums"
				 };


void onRender(CRules@ this){
	bool tutorial = !this.get_bool("tutorialnoshow");
	bool tutorial2 = this.get_bool("tutorial2show");
	if(tutorial)
		GUI::DrawIcon("GUI/HOTRTutorial.png", Vec2f(getScreenWidth()/2 - 425, getScreenHeight()/2 - 657/2), 0.5f);
	if(tutorial2)
		GUI::DrawIcon("GUI/HOTRTutorial2.png", Vec2f(getScreenWidth()/2 - 640/2, getScreenHeight()/2 - 686/2), 0.5f);

}

void onTick(CRules@ this){
	bool tutorial = !this.get_bool("tutorialnoshow");
	bool tutorial2 = this.get_bool("tutorial2show");
	if (getControls().isKeyJustPressed(KEY_KEY_Z)){
		if(tutorial){
			this.set_bool("tutorialnoshow", true);
			this.set_bool("tutorial2show", false);
		}
		else{
			this.set_bool("tutorialnoshow", false);
			this.set_bool("tutorial2show", false);
		}
	}
	if (getControls().isKeyJustPressed(KEY_KEY_P)){
		if(tutorial2){
			this.set_bool("tutorial2show", false);
			this.set_bool("tutorialnoshow", true);
		}
		else{
			this.set_bool("tutorial2show", true);
			this.set_bool("tutorialnoshow", true);
		}
	}

	if(!this.exists("lastmessagetime")){
		this.set_u32("lastmessagetime", getGameTime());
		client_AddToChat("Welcome to HOTR: Heroes of the Round!", M_COLOR);
		client_AddToChat("A MOBA mod designed and developed by Nand", M_COLOR);
	}

	if(getGameTime() - this.get_u32("lastmessagetime") > 180 * getTicksASecond()){
		u8 lastpick = XORRandom(chats.length);
		while(lastpick == this.get_u8("lastpick")){
			lastpick = XORRandom(chats.length);
		}
		client_AddToChat(chats[lastpick], M_COLOR);
		this.set_u32("lastmessagetime", getGameTime());
		this.set_u8("lastpick", lastpick);
	}
}
