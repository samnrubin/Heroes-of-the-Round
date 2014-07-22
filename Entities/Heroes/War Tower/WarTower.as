// WarTower

#include "Hitters.as"
#include "Heroes_MapFunctions.as"




void onInit( CBlob@ this )
{
    this.Tag("stone");
	this.getSprite().SetZ( -50.0f ); // push to background
    this.Tag("tower");
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if(hitterBlob.hasTag("doubling")){
		hitterBlob.Untag("doubling");
		//print("other tower: " + formatFloat(this.getHealth(), '0', 0, 2 ));
		return damage;
	}
	//print("this tower: " + formatFloat(this.getHealth(), '0', 0, 2 ));

    if (damage > 0.05f) //sound for all damage
    {
        if (hitterBlob !is this) {
            this.getSprite().PlaySound( "dig_stone", Maths::Min( 1.25f, Maths::Max(0.5f, damage) ) );
        }

        makeGibParticle( "GenericGibs", worldPoint, getRandomVelocity( (this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f )+Vec2f(0.0f,-2.0f),
                         2, 4+XORRandom(4), Vec2f(8,8), 2.0f, 0, "", 0 );
    }

	CBlob@[] towers;
	getBlobsByTag("tower", @towers);
	for(int i = 0; i < towers.length; i++){
		if(determineZone(this) == determineZone(towers[i]) &&
		   this.getTeamNum() == towers[i].getTeamNum() &&
		   towers[i] !is this){
			hitterBlob.Tag("doubling");
		   	hitterBlob.server_Hit(towers[i], worldPoint, velocity, damage, customData);
			//print("hitting other tower\n");
		   }
	}

    return damage;
}

void onTick( CBlob@ this){

	if(this.getName() == "wartowertop"){
		CBlob@ target = findTarget(this);

		if(target !is null && getGameTime() % 90 == 0){
			createOrb(this, target);
		}
	}
}

void createOrb(CBlob@ this, CBlob@ target){
	if (getNet().isServer()){
		server_CreateBlob("towerorb", this.getTeamNum(), this.getPosition() - Vec2f (0, t(1)/2));
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
			//&& (seeThroughWalls || isVisible(blob, potential))
			&& !potential.hasTag("dead")
			&& determineXZone(potential) == 2
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
			&& determineXZone(potential) == 2
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

void onGib( CSprite@ this )
{
    if (this.getBlob().hasTag("heavy weight")) {
        this.PlaySound( "WoodDestruct" );
    }
    else {
        this.PlaySound( "LogDestruct" );
    }
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
    if (!solid) {
        return;
    }

    if (!getNet().isServer()) {
        return;
    }

    f32 vellen = this.getShape().vellen;
    bool heavy = this.hasTag("heavy weight");
    // sound
    const f32 soundbase = heavy ? 0.7f : 2.5f;
    const f32 sounddampen = heavy ? soundbase : soundbase*2.0f;

    if (vellen > soundbase)
    {
        f32 volume = Maths::Min( 1.25f, Maths::Max(0.2f, (vellen-soundbase)/soundbase) );

        if (heavy)
        {
            if (vellen > 3.0f) {
                this.getSprite().PlayRandomSound( "/WoodHeavyHit", volume );
            }
            else {
                this.getSprite().PlayRandomSound( "/WoodHeavyBump", volume );
            }
        }
        else {
            this.getSprite().PlayRandomSound( "/WoodLightBump", volume );
        }
    }

    const f32 base = heavy ? 5.0f : 7.0f;
    const f32 ramp = 1.2f;

    //print("wood vel " + vellen + " base " + base );
    // damage

    if (vellen > base)
    {
        if (vellen > base * ramp)
        {
            f32 damage = 0.0f;

            if (vellen < base * Maths::Pow(ramp,1))
            {
                damage = 0.5f;
            }
            else if (vellen < base * Maths::Pow(ramp,2))
            {
                damage = 1.0f;
            }
            else if (vellen < base * Maths::Pow(ramp,3))
            {
                damage = 2.0f;
            }
            else if (vellen < base * Maths::Pow(ramp,3))
            {
                damage = 3.0f;
            }
            else //very dead
            {
                damage = 100.0f;
            }

            // check if we aren't touching a trampoline
            CBlob@[] overlapping;

            if (this.getOverlapping( @overlapping ))
            {
                for (uint i = 0; i < overlapping.length; i++)
                {
                    CBlob@ b = overlapping[i];

                    if (b.hasTag("no falldamage"))
                    {
                        return;
                    }
                }
            }

            this.server_Hit( this, point1, normal, damage, Hitters::fall );
        }
    }
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() == "arrow" && blob.getTeamNum() != this.getTeamNum())
		return true;
	return false;
}

bool isVisible( CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid( blob.getPosition(), target.getPosition(), col );
}
