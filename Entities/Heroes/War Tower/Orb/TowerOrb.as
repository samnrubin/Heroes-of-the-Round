#include "Heroes_MapFunctions.as"

void onInit( CBlob@ this )
{
	this.Tag("exploding");
	this.set_f32("explosive_radius", 12.0f );
	this.set_f32("explosive_damage", 8.0f);
	this.set_f32("map_damage_radius", 0.0f);
	this.set_f32("map_damage_ratio", 0.0f); //heck no!
	this.set_bool("explosive_teamkill", false);
}	

void onTick( CBlob@ this )
{
	if(this.getCurrentScript().tickFrequency == 1){
		this.getShape().SetGravityScale( 0.0f );
		this.server_SetTimeToDie(3);
		this.SetLight( true );
		this.SetLightRadius( 24.0f );
		this.SetLightColor( SColor(255, 211, 121, 224 ) );
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("OrbFireSound.ogg");
		this.getSprite().SetZ(1000.0f);
		
		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );
		
		// done post init
		this.getCurrentScript().tickFrequency = 10;
	}

	if(!this.exists("target")){
		CBlob@ c = findTarget(this);
		if(c !is null){
			this.set_u16("target", c.getNetworkID());
		}
	}
	
	CBlob@ b = getBlobByNetworkID(this.get_u16("target"));
	if(b !is null){
	
		Vec2f vel = this.getVelocity();

		if(!b.hasTag("dead"))
		{
			//if(vel.LengthSquared() < 9.0f)
			//{				
				Vec2f dir = b.getPosition()-this.getPosition();
				dir.Normalize();
				this.setVelocity(vel+dir*3.0f);
			//}
		}
	}

}

CBlob@ findTarget(CBlob@ this){
	CBlob@[] humans;
	getBlobsByTag( "human", @humans );

	Vec2f pos = this.getPosition();
	int closest = humans.length;
	f32 closestDist = t(100);


	for (uint i=0; i < humans.length; i++)
	{
		CBlob@ potential = humans[i];	
		Vec2f pos2 = humans[i].getPosition();
		if (this.getTeamNum() != potential.getTeamNum()
			&& determineZone(this) == determineZone(potential)
			&& (pos2 - pos).Length() < t(25)
			&& !potential.hasTag("dead")
			&& determineXZone(this) == determineXZone(potential)
			)
		{
			f32 dist = (pos - pos2).Length();
			if(dist < closestDist){
				closestDist = dist;
				closest = i;
			}
		}
	}

	if(closest < humans.length){
		this.Tag("humantarget");
		return humans[closest];
	}

	CBlob@[] players;
	if(this.getTeamNum() == 0)
		getBlobsByTag( "red", @players );
	else
		getBlobsByTag("blue", @players );


	closest = players.length;

	for (uint i=0; i < players.length; i++)
	{
		CBlob@ potential = players[i];	
		Vec2f pos2 = potential.getPosition();
		if (determineZone(this) == determineZone(potential)
			&& (pos2 - pos).Length() < t(25)
			&& !potential.hasTag("dead")
			&& determineXZone(potential) == determineXZone(this)
			&& isVisible(this, potential)
			)
		{
			f32 dist = (pos - pos2).Length();
			if(dist < closestDist){
				closestDist = dist;
				closest = i;
			}
		}
	}

	if(closest < players.length){
		return players[closest];
	}
	else
		return null;

}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return ((blob.hasTag("flesh") && !blob.hasTag("dead")) && blob.getTeamNum() != this.getTeamNum());
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
	if (solid)
	{
		if(blob !is null && blob.getTeamNum() != this.getTeamNum())
			this.server_Die();			
	}
}

bool isVisible( CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid( blob.getPosition(), target.getPosition(), col );
}

