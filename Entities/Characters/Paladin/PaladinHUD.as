//paladin HUD


const string iconsFilename = "Entities/Characters/Knight/KnightIcons.png";
const string abilityIconsFilename = "Entities/Characters/Paladin/PaladinAbilityIcons.png";
const int slotsSize = 10;

#include "ActorHUDStartPos.as";
#include "PaladinCommon.as";
void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}
	   
void ManageCursors( CBlob@ this )
{
	if (getHUD().hasButtons()) {
		getHUD().SetDefaultCursor();
	}
	else
	{		 	
		if (this.isAttached() && this.isAttachedToPoint("GUNNER")) {
			getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32,32));
			getHUD().SetCursorOffset( Vec2f(-32, -32) );
		}
		else {
			getHUD().SetCursorImage("Entities/Characters/Knight/KnightCursor.png", Vec2f(32,32));
		}
	}
}

void DrawAbilities(CSprite@ this){
	PaladinInfo@ paladin;
	if( !this.getBlob().get("knightInfo", @paladin) ){
		return;
	}

	Vec2f dim = Vec2f(562, 64);
	Vec2f ul(HUD_X - dim.x/2.0f, HUD_Y - dim.y + 14 );
	ul+= Vec2f(48+16+304, -32.0f);
    GUI::DrawIcon(abilityIconsFilename, 0, Vec2f(16,16), ul, 1.0f);

	s16 forceCountdown = (KnightVars::force_ability_time - (getGameTime() - paladin.forceAbilityTimer)) / getTicksASecond() + 1;
	string forceAbility;
	SColor text_color;
	if(forceCountdown > 0){
		forceAbility = (formatInt(forceCountdown, ""));
		text_color = SColor(255, 154, 0, 0);
	}
	else{
		forceAbility = "Go!";
		text_color = SColor(255, 28, 78, 12);
	}
	

	GUI::DrawText(forceAbility, ul + Vec2f(38, 8), text_color);
}


void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();

	ManageCursors( blob );

	// draw inventory

	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
	DrawInventoryOnHUD( blob, tl );	  

	u8 btype = blob.get_u8("bomb type");
	u8 frame = 1;
	if (btype == 0){
		frame = 0;
	}
	else if (btype < 255) {
		frame = 1 + btype;
	}

	// draw coins

	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD( blob, coins, tl, slotsSize-2 );

	// draw class icon

	GUI::DrawIcon( iconsFilename, frame, Vec2f(16,32), tl+Vec2f(8 + (slotsSize-1)*32,-16), 1.0f);

	DrawAbilities(this);
}

