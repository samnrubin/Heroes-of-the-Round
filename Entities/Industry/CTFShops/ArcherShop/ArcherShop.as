﻿// Archer Workshop

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

	{
		ShopItem@ s = addShopItem( this, "Arrows", "$mat_arrows$", "mat_arrows", descriptions[2], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 15 );
	}
	{
		ShopItem@ s = addShopItem( this, "Water Arrows", "$mat_waterarrows$", "mat_waterarrows", descriptions[50], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 40 );
	}
	{
		ShopItem@ s = addShopItem( this, "Fire Arrows", "$mat_firearrows$", "mat_firearrows", descriptions[32], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 60 );
	}
	{
		ShopItem@ s = addShopItem( this, "Bomb Arrows", "$mat_bombarrows$", "mat_bombarrows", descriptions[51], true );
		AddRequirement( s.requirements, "coin", "", "Coins", 50 );
	}
	this.set_string("required class", "scout");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	this.set_bool("shop available", this.isOverlapping(caller)/* && caller.getName() == "archer"*/ );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
	}
}
