// scroll script that makes enemies insta gib within some radius

#include "Hitters.as";
#include "Heroes_MapFunctions.as";
#include "EmotesCommon.as";

void onInit( CBlob@ this )
{
	this.addCommandID( "healteam" );
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton( 11, Vec2f_zero, this, this.getCommandID("healteam"), "Use this to heal all allies in a 5 tile radius.", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("healteam"))
	{
		bool hit = false;
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		if (caller !is null)
		{
			const int team = caller.getTeamNum();
			CBlob@[] blobsInRadius;	   
			if (this.getMap().getBlobsInRadius( this.getPosition(), t(5), @blobsInRadius )) 
			{
				for (uint i = 0; i < blobsInRadius.length; i++)
				{
					CBlob @b = blobsInRadius[i];
					if (b.getTeamNum() == team && b.hasTag("flesh"))
					{
						hit = true;
						f32 hearts = this.exists("defaulthearts") ? this.get_f32("defaulthearts") : 1.0f;
						b.server_SetHealth(b.getInitialHealth() * hearts);
						set_emote(b, Emotes::heart);
					}
				}
			}
		}

		if (hit)
		{
			this.server_Die();
			Sound::Play( "MagicWand.ogg" );
		}
	}
}
