// Scroll that confers enhanced retinue powers

#include "Hitters.as";


void onInit( CBlob@ this )
{
	this.addCommandID( "retinueme" );
	
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("retinueme"), "Gain an enhanced version of the sergeant's command powers for the next 30 seconds.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("retinueme") && !this.hasTag("sapperposer"))
	{
		CBlob@ caller = getBlobByNetworkID (params.read_u16());
		caller.set_u32("retinue_called", getGameTime());
		caller.Tag("sapperposer");
		caller.Sync("retinue_called", true);
		if(caller.isMyPlayer()){
			Sound::Play("Travel.ogg");
		}
		this.server_Die();
	}
}
