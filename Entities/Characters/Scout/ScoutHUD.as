//archer HUD

#include "ScoutCommon.as";
#include "ActorHUDStartPos.as";

const string iconsFilename = "Entities/Characters/Archer/ArcherIcons.png";
const string abilityIconsFilename = "Entities/Characters/Scout/ScoutAbilityIcons.png";
const int slotsSize = 10;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors( CBlob@ this )
{
	// set cursor
	if (getHUD().hasButtons()) {
		getHUD().SetDefaultCursor();
	}
	else
	{
		// set cursor
		getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32,32));
		getHUD().SetCursorOffset( Vec2f(-32, -32) );
		// frame set in logic
	}
}

void DrawAbilities(CSprite@ this){
	ScoutInfo@ scout;
	if( !this.getBlob().get("archerInfo", @scout) )
		return;
	
	Vec2f dim = Vec2f(562, 64);
	Vec2f ul(HUD_X - dim.x/2.0f, HUD_Y - dim.y + 14 );
	ul+= Vec2f(48+16+304, -32.0f);
    GUI::DrawIcon(abilityIconsFilename, 0, Vec2f(16,16), ul, 1.0f);

	s16 cloakCountdown = (ArcherParams::cloak_ability_time - (getGameTime() - scout.cloakAbilityTimer)) / getTicksASecond() + 1;
	string cloakAbility;
	SColor text_color;
	if(cloakCountdown > 0 && scout.cloakAbilityTimer != 0){
		cloakAbility = (formatInt(cloakCountdown, ""));
		text_color = SColor(255, 154, 0, 0);
	}
	else{
		cloakAbility = "Go!";
		text_color = SColor(255, 28, 78, 12);
	}
	

	GUI::DrawText(cloakAbility, ul + Vec2f(38, 8), text_color);

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

	const u8 type = getArrowType( blob );
	u8 arrow_frame = 0;
	if (type != ArrowType::normal){
		arrow_frame = 2 + type;
	}

	// draw coins

	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD( blob, coins, tl, slotsSize-2 );
	
	// class weapon icon

	GUI::DrawIcon( iconsFilename, arrow_frame, Vec2f(16,32), tl+Vec2f(8 + (slotsSize-1)*32,-16), 1.0f);
	DrawAbilities(this);
}
