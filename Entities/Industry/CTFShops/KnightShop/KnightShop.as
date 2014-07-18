// Knight Workshop

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";

void onInit( CBlob@ this )
{
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	
	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4,1));	
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	
	//setup shop items
	{
		ShopItem@ s = addShopItem( this, "Bomb", "$bomb$", "mat_bombs", descriptions[1], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 25 );
	}
	{
		ShopItem@ s = addShopItem( this, "Water Bomb", "$waterbomb$", "mat_waterbombs", descriptions[52], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 30 );
	}
	{
		ShopItem@ s = addShopItem( this, "Mine", "$mine$", "mine", descriptions[20], false );
		AddRequirement( s.requirements, "coin", "", "Coins", 75 );
	}
	{
		ShopItem@ s = addShopItem( this, "Keg", "$keg$", "keg", descriptions[4], false );
		AddRequirement( s.requirements, "coin", "", "Coins", 200 );
	}
	this.set_string("required class", "paladin");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "knight"*/ );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
	}
}
