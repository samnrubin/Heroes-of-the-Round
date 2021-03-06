// Teleport home 

#include "Hitters.as";
#include "Heroes_MapFunctions.as";


void onInit( CBlob@ this )
{
	this.addCommandID( "telehome" );
	
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("telehome"), "Teleport back to your base in this lane.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("telehome") && !this.hasTag("telehall") && !this.hasTag("telehome"))
	{
		CBlob@ caller = getBlobByNetworkID (params.read_u16());
		//this.server_Die();
		//Sound::Play( "MagicWand.ogg", this.getPosition(), 1.0f, 0.75f );

		caller.set_u32("tele_called", getGameTime());
		caller.set_u16("magicobject", this.getNetworkID());
		caller.Sync("magicobject", true);
		caller.Sync("telehome", true);
		caller.Sync("tele_called", true);
		caller.Tag("telehome");
		caller.server_PutInInventory(this);
		//caller.setPosition(halls[hallIndex].getPosition());
		//caller.setVelocity( Vec2f_zero );
	}
}
