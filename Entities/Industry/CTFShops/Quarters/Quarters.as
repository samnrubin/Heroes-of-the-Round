// Quarters

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";
#include "StandardControlsCommon.as";
#include "CTFShopCommon.as";

s32 cost_beer = 5;
s32 cost_meal = 10;
s32 cost_burger = 20;

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// icons
	AddIconToken( "$quarters_beer$", "Quarters.png", Vec2f(24,24), 7 );
	AddIconToken( "$quarters_meal$", "Quarters.png", Vec2f(48,24), 2 );

	//load config

	if (getRules().exists("ctf_costs_config"))
	   cost_config_file = getRules().get_string("ctf_costs_config");
	
	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	cost_beer = cfg.read_s32("cost_beer", cost_beer);
	cost_meal = cfg.read_s32("cost_meal", cost_meal);

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(5,1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{	 
		ShopItem@ s = addShopItem( this, "Beer - 1 Heart", "$quarters_beer$", "beer", "A refreshing mug of beer.", false );
		s.spawnNothing = true;
		AddRequirement( s.requirements, "coin", "", "Coins", cost_beer );
	}
	
	{	 
		ShopItem@ s = addShopItem( this, "Meal - Full Health", "$quarters_meal$", "meal", "A hearty meal to get you back on your feet.", false );
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement( s.requirements, "coin", "", "Coins", cost_meal );
	}
	
	this.set_string("required class", "builder");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
		
		bool isServer = (getNet().isServer());
		
		
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		string name = params.read_string();
		
		{
			CBlob@ caller_blob = getBlobByNetworkID(caller);
			if(caller_blob is null)
				return;
			
			if(name == "beer")
			{
				//TODO: gulp gulp sound
				if(isServer)
				{
					caller_blob.server_Heal(1.0f);
				}
			}
			else if(name == "meal")
			{
				this.getSprite().PlaySound( "/Eat.ogg" );
				if(isServer)
				{
					caller_blob.server_SetHealth(caller_blob.getInitialHealth());
				}
			}
			else if(name == "burger")
			{
				CBlob@ food = server_CreateBlob( "food", -1, caller_blob.getPosition());
				if(food !is null)
					server_Pickup( caller_blob, caller_blob, food );
			}
		}
	}
}
