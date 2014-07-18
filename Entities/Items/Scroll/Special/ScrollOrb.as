// scroll script that summons a towerorb

#include "Hitters.as";

void onInit( CBlob@ this )
{
	this.addCommandID( "orbsummon" );
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("orbsummon"), "Use this to summon an orb which will seek out enemies, prioritizing other players.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("orbsummon"))
	{
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		if(getNet().isServer()){
			server_CreateBlob("towerorb", caller.getTeamNum(), this.getPosition());
		}
		ParticleZombieLightning(this.getPosition());
		this.server_Die();
	}
}
