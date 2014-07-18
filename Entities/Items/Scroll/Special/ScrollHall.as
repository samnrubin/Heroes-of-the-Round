// Teleport to furthest hall scroll 

#include "Hitters.as";
#include "Heroes_MapFunctions.as";


void onInit( CBlob@ this )
{
	this.addCommandID( "telehall" );
	
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("telehall"), "Teleport to your furthest owned hall in this lane.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("telehall") && !this.hasTag("telehall") && !this.hasTag("telehome"))
	{
		CBlob@ caller = getBlobByNetworkID (params.read_u16());
		CBlob@[] halls;
		getBlobsByName("hall", @halls);
		bool hallFound = false;
		uint hallIndex;
		for(uint i = 0; i < halls.length; i++){
			if(determineZone(halls[i]) == determineZone(caller) &&
			   caller.getTeamNum() == halls[i].getTeamNum()){
				if(hallFound){
					if(caller.getTeamNum() == 0){
						if(halls[i].getPosition().x > halls[hallIndex].getPosition().x)
							hallIndex = i;
					}
					else{
						if(halls[i].getPosition().x < halls[hallIndex].getPosition().x)
							hallIndex = i;
					}
				}
				else{
					hallIndex = i;
					hallFound = true;
				}
			}
		}
		if (hallFound)
		{
			//this.server_Die();
			//Sound::Play( "MagicWand.ogg", this.getPosition(), 1.0f, 0.75f );

			caller.set_u32("tele_called", getGameTime());
			caller.set_u16("magicobject", this.getNetworkID());
			caller.Tag("telehall");
			caller.Sync("magicobject", true);
			caller.Sync("telehall", true);
			caller.Sync("tele_called", true);
			caller.server_PutInInventory(this);
			//caller.setPosition(halls[hallIndex].getPosition());
			//caller.setVelocity( Vec2f_zero );
		}
	}
}
