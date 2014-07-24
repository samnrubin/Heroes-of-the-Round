//archer HUD

#include "/ActorHUDStartPos.as";

const string iconsFilename = "Entities/Characters/Builder/BuilderIcons.png";
const string abilityIconsFilename = "Entities/Characters/Sapper/SergeantAbilityIcons.png";
const int slotsSize = 10;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
	//AddIconToken("$knight_summon$", "Entities/Characters/Sapper/SergeantAbilityIcons.png", Vec2f(16,16)
}

void ManageCursors( CBlob@ this )
{
	// set cursor
	if (getHUD().hasButtons()) {
		getHUD().SetDefaultCursor();
	}
	else {
		if (this.isAttached() && this.isAttachedToPoint("GUNNER")) {
			getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32,32));
			getHUD().SetCursorOffset( Vec2f(-32, -32) );
		}
		else {
			getHUD().SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
		}

	}
}

void DrawAbilities(CSprite@ this){
	CBlob@ blob = this.getBlob();

	Vec2f dim = Vec2f(562, 64);
	Vec2f ul(HUD_X - dim.x/2.0f, HUD_Y - dim.y + 14 );
	ul+= Vec2f(48+16+304, -32.0f);
    GUI::DrawIcon(abilityIconsFilename, 0, Vec2f(16,16), ul, 1.0f);

	u8 guardCount = blob.get_u8("guardsize");
	u8 guardMax = blob.get_u8("maxguard");

	SColor text_color;

	if(guardCount < guardMax)
		text_color = SColor(255, 28, 78, 12);
	else
		text_color = SColor(255, 154, 0, 0);

	GUI::DrawText(formatInt(guardCount, ""), ul + Vec2f(38, 8), text_color);

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

	// draw coins

	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD( blob, coins, tl, slotsSize-2 );

	// draw class icon 

    GUI::DrawIcon(iconsFilename, 3, Vec2f(16,32), tl+Vec2f(8 + (slotsSize-1)*32,-13), 1.0f);
	DrawAbilities(this);
}
