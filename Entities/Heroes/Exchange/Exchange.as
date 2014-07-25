// Quarters

const int EXCHANGE_COST = 10;

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.addCommandID("exchangegold");

}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16( caller.getNetworkID() );

	CButton@ button = caller.CreateGenericButton( "$mat_gold$", Vec2f(0,0), this, this.getCommandID("exchangegold"), "Exchange your gold for coins at a " + EXCHANGE_COST + ":1 rate" , params);

	if(caller.getBlobCount("mat_gold") < EXCHANGE_COST )
	{
		button.SetEnabled( false );
	}
	
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("exchangegold"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID( callerID );
		
		if(caller !is null)
		{
			u16 goldCount = caller.getBlobCount("mat_gold");
			if( goldCount >= EXCHANGE_COST )
			{
				u16 coinCount = goldCount / EXCHANGE_COST;
				caller.TakeBlob("mat_gold", coinCount * EXCHANGE_COST);
				caller.getPlayer().server_setCoins(caller.getPlayer().getCoins() + coinCount);
				this.getSprite().PlaySound( "/ChaChing.ogg" );
			}
		
		}
	}
	
}
