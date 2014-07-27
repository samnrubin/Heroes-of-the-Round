#define CLIENT_ONLY

const SColor M_COLOR = SColor(0, 51, 116, 51);
int location = 0;
bool tutorialShow = true;
u32 lastMessageTime = 0;
		
string[] chats = {"Don't forget to access the help menus with P",
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
				 "Interested in writing quotes for the traders? Message me on the forums"
				 };

int lastPick = 0;


void onRender(CRules@ this){
	string tutorialpage;
	if(tutorialShow){
		switch(location){
			case 1:
				tutorialpage = "GUI/Advanced_Tutorial";
				break;
			case 2:
				tutorialpage = "GUI/Paladin_Guide";
				break;
			case 3:
				tutorialpage = "GUI/Ranger_Guide";
				break;
			case 4:
				tutorialpage = "GUI/Sergeant_Guide";
				break;
			default:
				tutorialpage = "GUI/Basic_Tutorial";
				break;
		}
		GUI::DrawIcon(tutorialpage, Vec2f(getScreenWidth()/2 - 640/2, getScreenHeight()/2 - 686/2), 0.5f);
	}


}

void onTick(CRules@ this){
	if (getControls().isKeyJustPressed(KEY_KEY_P)){
		if(tutorialShow){
			tutorialShow = false;
		}
		else{
			tutorialShow = true;
			location = 0;
		}
	}

	if (getControls().isKeyJustPressed(KEY_KEY_L))
		location = 1;
	if (getControls().isKeyJustPressed(KEY_KEY_U))
		location = 2;
	if (getControls().isKeyJustPressed(KEY_KEY_I))
		location = 3;
	if (getControls().isKeyJustPressed(KEY_KEY_O))
		location = 4;

	if(lastMessageTime == 0){
		lastMessageTime = getGameTime();
		client_AddToChat("Welcome to HOTR: Heroes of the Round!", M_COLOR);
		client_AddToChat("A MOBA mod designed and developed by Nand", M_COLOR);
	}

	if(getGameTime() - lastMessageTime > 180 * getTicksASecond()){
		u8 newpick = XORRandom(chats.length);
		while(chats[newpick] == chats[lastPick]){
			newpick = XORRandom(chats.length);
		}
		client_AddToChat(chats[newpick], M_COLOR);
		lastMessageTime = getGameTime();
		lastPick = newpick;
	}
}
