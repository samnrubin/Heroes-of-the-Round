// Knight brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "Explosion.as"
#include "Heroes_MapFunctions.as"

void onInit( CBrain@ this )
{
	InitBrain( this );
	CBlob @blob = this.getBlob();
	if(!blob.exists("stuckTime")){
		blob.set_u16("stuckTime", 0);
	}
	if(!blob.exists("lastXPos")){
		blob.set_f32("lastXPos", this.getBlob().getPosition().y);
	}
}

void isStuck( CBlob@ this ){

	u16 stuckTime = this.get_u16("stuckTime");
	f32 lastXPos = this.get_f32("lastXPos");
	Vec2f pos = this.getPosition();

	/*CBlob@[] nands;
	this.getMap().getBlobsInRadius(pos, t(3), @nands);
	for(uint i = 0; i < nands.length; i++){
		if(nands[i].hasTag("human")){
			print(formatInt(this.get_u8("direction"), ""));
			break;
		}
	}*/
	if(this.hasTag("retinue")){
		return;
	}
	if(Maths::Abs(pos.x - lastXPos) < t(0.5) && !this.isOnLadder()){
		stuckTime++;
		this.set_u16("stuckTime", stuckTime);
	}
	else{
		this.set_f32("lastXPos", pos.x);
		this.set_u16("stuckTime", 0);
		this.Untag("stuck");
	}

	if(stuckTime > getTicksASecond() * 2.25){
		this.Tag("stuck");
		if(stuckTime % 10 == 9){
			Vec2f wallpos;
			f32 radius = this.getRadius();

			CBlob @target = this.getBrain().getTarget();
			f32 yDistance = pos.y - target.getPosition().y;
			f32 xDistance = pos.x - target.getPosition().x;
			/*if(Maths::Abs(yDistance) < t(4)){
				if(yDistance < 0 ){
					//stab down
				}else{
					//stab up
				}
			}*/
			f32 direction;
			if(xDistance >= 0)
				direction = -1;
			else
				direction = 1;
			
			uint triple = XORRandom(3);
			//Dat dere stuck guidance system
			if(target.getName() == "hall" && Maths::Abs(xDistance) < t(2)){
				//Dig through hall roofs
				if(triple == 0)
					wallpos = target.getPosition() + Vec2f(t(-1), 0);
				else if(triple == 1)
					wallpos = target.getPosition();
				else
					wallpos = target.getPosition() + Vec2f(t(1), 0);
			}// Dig through sideways walls
			else{
				CMap@ map = this.getMap();
				if(map is null)
					return;
				
				bool isCeiling = map.rayCastSolid(pos, pos - Vec2f(0, t(2)));
				triple = isCeiling ? XORRandom(4) : XORRandom(2);
				
				if(triple == 0){
					wallpos = pos + Vec2f(1.3f*radius * direction, - t(0.5));
				}
				else if(triple == 1){
					wallpos = pos + Vec2f(1.3f*radius * direction, - t(0));
				}// Dig through ceiling if there is one
				else if(isCeiling){
					wallpos = pos + Vec2f(0, t(-2));

				}
			}
			this.setAimPos(wallpos);
			this.setKeyPressed( key_action1, true );
		}
		if(stuckTime % 10 == 8){
			this.setKeyPressed( key_action1, false );
		}
	}
	/*if(stuckTime > getTicksASecond() * 5){
		f32 radius = this.getRadius();
		Vec2f wallpos;
		if(this.isFacingLeft()){
			wallpos = this.getPosition() + Vec2f(-1.3f*radius, radius);
		}
		else{
			wallpos = this.getPosition() + Vec2f(1.3f*radius, radius);
		}
		CMap@ map = this.getMap();
		if (map is null) 
			return;

		TileType tile = map.getTile(wallpos).type;
		if(map.isTileCastle(tile)){
			this.set_f32("map_damage_radius", 24.0f);
			this.set_f32("map_damage_ratio", 0.2f);
			Explode(this, t(1), 0);
			this.set_u16("stuckTime", 0);
		}


	
	}*/
}



void onTick( CBrain@ this )
{
	SearchTarget( this, false, true );

    CBlob @blob = this.getBlob();
	isStuck(blob);
	CBlob @target = this.getTarget();

	// Handle stick close when direction is down
	//if (sv_test)
	//	return;
			 //	 blob.setKeyPressed( key_action2, true );
			//	return;
	// logic for target

	this.getCurrentScript().tickFrequency = 29;
	u8 strategy = blob.get_u8("strategy");
/*		CBlob@[] halls;
		CBlob@ hall;

		getBlobsByName("hall", @halls);*/
    if (target !is null)
    {
		this.getCurrentScript().tickFrequency = 1;


		f32 distance;
		const bool visibleTarget = isVisible( blob, target, distance);
		if (visibleTarget && distance < 50.0f && target.getName() != "waypoint" &&
		    target.getTeamNum() != blob.getTeamNum()) {
			strategy = Strategy::attacking; 
		}

		if (strategy == Strategy::idle)
		{
			strategy = Strategy::chasing; 
		}
		else if (strategy == Strategy::chasing)
		{
		}
		else if (strategy == Strategy::attacking)
		{
			if (!visibleTarget || distance > 120.0f || target.getName() == "waypoint" || target.getTeamNum() == blob.getTeamNum()) {
				strategy = Strategy::chasing; 
			}
		}
				
		UpdateBlob( blob, target, strategy ); 

        // lose target if its killed (with random cooldown)

		if (LoseTarget( this, target )) {
			strategy = Strategy::idle;
		}

		blob.set_u8("strategy", strategy);	  
    }

	FloatInWater( blob );
}

void UpdateBlob( CBlob@ blob, CBlob@ target, const u8 strategy )
{
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	if ( strategy == Strategy::chasing ) 
	{
		DefaultChaseBlob( blob, target );		
	}
	else if ( strategy == Strategy::attacking ) 
	{
		AttackBlob( blob, target );
	}
	/*else if ( strategy == Strategy::idle ){
		Charge(blob, blob.getTeamNum());
	}*/
}

	 
void AttackBlob( CBlob@ blob, CBlob @target )
{
    Vec2f mypos = blob.getPosition();
    Vec2f targetPos = target.getPosition();
    Vec2f targetVector = targetPos - mypos;
    f32 targetDistance = targetVector.Length();
	const s32 difficulty = blob.get_s32("difficulty");

    if (targetDistance > blob.getRadius() + 15.0f)
    {
		if (!isFriendAheadOfMe( blob, target )) {
			Chase( blob, target );
		}
    }

	JumpOverObstacles(blob);

    // aim always at enemy
	if(!blob.hasTag("stuck"))
    	blob.setAimPos( targetPos );

	const u32 gametime = getGameTime();

	bool shieldTime = gametime - blob.get_u32( "shield time") < uint(8+difficulty*1.33f+XORRandom(20));
	bool backOffTime = false;//gametime - blob.get_u32( "backoff time") < uint(1+XORRandom(20));

    if (target.isKeyPressed( key_action1 )) // enemy is attacking me
    {
		int r = XORRandom(35);
		if (difficulty > 2 && r < 2 && (!backOffTime || difficulty > 4))
		{
			blob.set_u32( "shield time", gametime );								  
			shieldTime = true;
		}
		else
			if (difficulty > 1 && r > 32 && !shieldTime)
			{
				// raycast to check if there is a hole behind

				Vec2f raypos = mypos;
				raypos += targetPos.x < mypos.x ? 32.0f : -32.0f;
				Vec2f col;
				if (getMap().rayCastSolid( raypos, raypos+Vec2f(0.0f, 32.0f), col ))
				{
					blob.set_u32( "backoff time", gametime );								  // base on difficulty
					//backOffTime = true;
				}
			}	 		
    }
    else
    {
        // start attack
        if (XORRandom(Maths::Max(3, 30 - (difficulty+4)*2)) == 0 && (getGameTime() - blob.get_u32( "attack time")) > 10)
        {		
			
			// base on difficulty
            blob.set_u32( "attack time", gametime );
        }
    }

    if ( shieldTime ) // hold shield for a while
    {
        blob.setKeyPressed( key_action2, true );
    }
	else if ( backOffTime ) // back off for a bit
	{
		Runaway( blob, target );
	}
    else if ( targetDistance < 40.0f && getGameTime() - blob.get_u32( "attack time") < (Maths::Min(13,difficulty+3)) ) // release and attack when appropriate
    {
        if (!target.isKeyPressed( key_action1 )) {
            blob.setKeyPressed( key_action2, false );
        }

        blob.setKeyPressed( key_action1, true );
    }
}

//NAND
/*void Charge( CBlob@ blob, int chargeDirection)
{
	CBrain@ brain = blob.getBrain();
	//TODO: Adjust for heights
	//TODO: Make attack bases
	CMap@ map = getMap();
    f32 side = map.tilesize * 5.0f;
    f32 x = chargeDirection != 0 ? side : (map.tilesize*map.tilemapwidth - side);
	f32 y = map.tilesize*map.tilemapheight/4 - 32.0f;
	Vec2f targetPos = Vec2f(x, y);
	Vec2f myPos = blob.getPosition();
	Vec2f targetVector = targetPos - myPos;
	// check if we have a clear area to the target
	bool justGo = false;


	// repath if no clear path after going at it
	if (XORRandom(50) == 0 && (blob.get_Vec2f("last pathing pos") - targetPos).getLength() > 50.0f)
	{
		Repath( brain );
		blob.set_Vec2f("last pathing pos", targetPos );
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		// printInt("state", this.getState() );
		if (state == CBrain::has_path) {
			brain.SetSuggestedKeys();  // set walk keys here
		}
		else {
			JustGoVec( blob, targetPos );
		}

		switch (state)
		{
		case CBrain::idle:
			Repath( brain );
			break;

		case CBrain::searching:
			//if (sv_test)
			//	set_emote( blob, Emotes::dots );
			break;

		case CBrain::stuck:
			Repath( brain );
			break;

		case CBrain::wrong_path:
			Repath( brain );
			break;
		}	  
	}

	// face the enemy
	blob.setAimPos( targetPos );

	// jump over small blocks	
	JumpOverObstacles( blob );
}

bool JustGoVec( CBlob@ blob, Vec2f point )
{
	Vec2f mypos = blob.getPosition();
	const f32 horiz_distance = Maths::Abs(point.x - mypos.x);

	if (horiz_distance > blob.getRadius()*0.75f)
	{
		if (point.x < mypos.x) {
			blob.setKeyPressed( key_left, true );
		}
		else {
			blob.setKeyPressed( key_right, true );
		}

		if (point.y + getMap().tilesize*0.7f < mypos.y ) {	  // dont hop with me
			blob.setKeyPressed( key_up, true );
		}

		if (blob.isOnLadder() && point.y > mypos.y) {
			blob.setKeyPressed( key_down, true );
		}

		return true;
	}

	return false;
}*/


void Charge( CBlob@ blob, int chargeDirection)
{
	Vec2f mypos = blob.getPosition();
	//TODO: Adjust for heights
	//TODO: Make attack bases
	CMap@ map = getMap();
    f32 side = map.tilesize * 5.0f;
    f32 x = chargeDirection != 0 ? side : (map.tilesize*map.tilemapwidth - side);
	f32 y = map.tilesize*map.tilemapheight/4 - 32.0f;
	Vec2f targetPos = Vec2f(x, y);
	Vec2f myPos = blob.getPosition();
	//blob.setKeyPressed( key_left, false );
	//blob.setKeyPressed( key_right, false );
	if (targetPos.x < mypos.x) {
		blob.setKeyPressed( key_left, true );
	}
	else {
		blob.setKeyPressed( key_right, true );
	}

}


