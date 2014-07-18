// Trader brain

#define SERVER_ONLY

#include "/Entities/Common/Emotes/EmotesCommon.as"

#include "TraderWantedList.as";
#include "Heroes_MapFunctions.as"
#include "BrainCommon.as"

void onInit( CBrain@ this )
{
    CBlob @blob = this.getBlob();
	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	if(!blob.exists("stuckTime")){
		blob.set_u16("stuckTime", 0);
		blob.Sync("stuckTime", true);
	}
	if(!blob.exists("lastXPos")){
		blob.set_f32("lastXPos", this.getBlob().getPosition().y);
	}



}

void isStuck(CBlob@ this){
	u16 stuckTime = this.get_u16("stuckTime");
	f32 lastXPos = this.get_f32("lastXPos");
	f32 currentXPos = this.getPosition().x;

	if(!this.exists("target"))
		this.set_u16("target", this.getNetworkID());

	if(Maths::Abs(currentXPos - lastXPos) < t(0.25) && !this.isOnLadder()
	&& this.get_u16("target") != this.getNetworkID()){
		stuckTime++;
		this.set_u16("stuckTime", stuckTime);
		this.Sync("stuckTime", true);
	}
	else{
		this.set_f32("lastXPos", currentXPos);
		this.set_u16("stuckTime", 0);
		this.Sync("stuckTime", true);
	}	

	if(stuckTime > getTicksASecond() * 9 && !this.hasTag("SCREAM")){
		this.Tag("SCREAM");
		this.Sync("SCREAM", true);
	}


	if(stuckTime > getTicksASecond() * 10){
		this.set_u16("stuckTime", 0);
		this.Sync("stuckTime", true);
		f32 yloc;
		f32 direction;
		//print("stuck");
		if(determineZone(this) == 0)
			yloc = t(roofZone + 6);
		else
			yloc = t(topZone + 6);

		if(this.get_u8("team target") == 0)
			direction = -1;
		else
			direction = 1;
		for(int i = this.getPosition().x + t(direction * 5); i > 0 && i < t(zoneWidth); i += direction){
			if(!this.getMap().isTileSolid(this.getMap().getTile(Vec2f(i, yloc)))){
				this.setPosition(Vec2f(i, yloc));
				this.setVelocity(Vec2f(0, -1.0f));
				break;
				//print(format
			}
		
		}


		
	}
}

void onTick( CBrain@ this )
{
    CBlob @blob = this.getBlob();
    u32 gametime = getGameTime();

	if(blob.hasTag("wandering"))
		isStuck(blob);

	// underwater!

	if (blob.isInWater()) 
	{
		blob.setKeyPressed( key_up, true );
		return;

	}

    if (gametime % 30 == 0)  // optimized retarget every couple secs
    {
		if(determineXZone(blob) == 0)
			blob.set_u8("team target", 1);
		else if(determineXZone(blob) == 1)
			blob.set_u8("team target", 0);

        FindNewTarget(this, blob);

        if (this.getTarget() is null)
            if (blob.hasTag("at post")) {
				set_emote(blob, Emotes::disappoint, 100);
            }
    }

    if (this.getTarget() !is null || blob.exists("target"))
    {
		if(blob.hasTag("wandering")){
            GoToBlob(this, getBlobByNetworkID(blob.get_u16("target")) );
		}
        else if (!blob.hasTag("at post")) // going to post
        {
            GoToBlob(this,  this.getTarget() );
        }
        else // at post
		{
			f32 distance = (this.getTarget().getPosition() - blob.getPosition()).Length();	 
			if (distance > 1.2f * blob.getRadius())
			{
				blob.Untag("at post");
				blob.Sync("at post", true);
				this.SetTarget( null );
				//blob.set_u8("emote", Emotes::disappoint);
			}

		}
    }
    else // if standing randomly turn
    {
        if (XORRandom(50) == 0) {
			
            blob.setAimPos( blob.getPosition() + Vec2f( - 100.0f + XORRandom(200), 0.0f) );
        }  
	}
}


bool hasTraderNear( CBlob@ this, CBlob@ post, CBlob@[]@ traders )
{
    Vec2f postPos = post.getPosition();

    for (uint i=0; i < traders.length; i++)
    {
        CBlob@ trader = traders[i];

        if (trader !is this && !trader.hasTag("dead") && (trader.getPosition() - postPos).getLength() < 1.2f * post.getRadius() )
        {
            return true;
        }
    }

    return false;
}

bool FindWantedPlayerTarget(CBrain@ this)
{
	f32 closestDistance;
	CBlob@ closest;
	
	CBlob@[] players;
    getBlobsByTag( "player", @players );
    
    Vec2f pos = this.getBlob().getPosition();
    closestDistance = 40000.0f; //squared - max 200 px dist
    TraderWantedList@ list = getWantedList();
    
    CMap@ map = this.getBlob().getMap();
    
    for (uint i=0; i < players.length; i++)
    {
		CBlob@ b = players[i];
		if (!b.hasTag("dead") && list.hasPlayer(b.getPlayer())) //this search should be fairly quick
		{
			Vec2f bpos = b.getPosition();
			f32 dist = (bpos - pos).LengthSquared();
			if(dist < 130.0f && dist < closestDistance && !map.rayCastSolid(pos, bpos))
			{
				@closest = b;
				closestDistance = dist;
			}
		}
	}
	
	if (closest !is null) // FOUND TARGET TO SHOOT!
	{
		this.SetTarget( closest );
		
		if (!this.getBlob().hasTag("shoot wanted")) //new target
		{
			this.getBlob().set_u32("target time", getGameTime());
		}
		
		this.getBlob().Tag("shoot wanted");
		this.getBlob().Sync("shoot wanted", true);
		
		return true;
	}
	
	this.getBlob().Untag("shoot wanted");
	this.getBlob().Sync("shoot wanted", true);
	
	return false;
	
}

void FindNewTarget( CBrain@ this, CBlob @blob ) //TODO: clean up all of the getblob()s in here
{
	//if(FindWantedPlayerTarget(this)) return;

	if(blob.hasTag("wandering")){

		CBlob@[] blobsInRadius;
		if(blob.getMap().getBlobsInRadius(blob.getPosition(), t(5), @blobsInRadius)){
			for (uint i = 0; i < blobsInRadius.length; i++){
				if(blobsInRadius[i].getPlayer() !is null){
					blob.set_u16("target", blob.getNetworkID());
					set_emote(blob, Emotes::smile);
					return;
				}
			}
		}
		
		u8 targetteam = blob.get_u8("team target");
	
		CBlob@[] tunnels;
		getBlobsByName( "tunnel", @tunnels );
		
		for (uint i=0; i < tunnels.length; i++){
			if(tunnels[i].getTeamNum() == targetteam
			  && determineZone(tunnels[i]) == determineZone(blob)){
				
				//print("targetfound");
				blob.set_u16("target", tunnels[i].getNetworkID());
					//print(formatFloat(blob.getPosition().x/t(1), ""));
				return;
			}
		}
	}


	
	f32 closestDistance;
	CBlob@ closest;
	
	Vec2f pos = this.getBlob().getPosition();
	
    CBlob@[] posts;
    getBlobsByName( "tradingpost", @posts );
    CBlob@[] traders;
    getBlobsByName( "trader", @traders );
    closestDistance = 9999999.9f;

    for (uint i=0; i < posts.length; i++)
    {
        CBlob@ potential = posts[i];

        if (potential !is blob && potential.getTeamNum() == this.getBlob().getTeamNum() &&
                !potential.isInWater() && !hasTraderNear( this.getBlob(), potential, @traders ) )
        {
            f32 dist = (potential.getPosition() - pos).getLength();

            if (dist < closestDistance)
            {
                closestDistance = dist;
                @closest = potential;
            }
        }
    }

    this.SetTarget( closest );
										   
    if (closest is null)
    {
        this.getBlob().Untag("at post");
        this.getBlob().Sync("at post", true);
    }
}

void GoToBlob( CBrain@ this, CBlob @target )
{
    CBlob @blob = this.getBlob();
    Vec2f targetVector = target.getPosition() - blob.getPosition();
    f32 targetDistance = targetVector.Length();

	//if (targetDistance > target.getRadius() * 0.5f)
	//{
		// check if we have a clear area to the target
		JustGo( this, target.getPosition() );
										  
		// face the enemy
		blob.setAimPos( target.getPosition() );
		// jump over small blocks
		Vec2f pos = blob.getPosition();

		if ( (blob.isKeyPressed( key_right ) && getMap().isTileSolid( pos + Vec2f(1.3f*blob.getRadius(), 5.0f)*1.2f ) ) ||
			 (blob.isKeyPressed( key_right ) && getMap().isTileSolid( pos + Vec2f(1.3f*blob.getRadius(), -5.0f)*1.2f ) ) ||
			 (blob.isKeyPressed( key_left ) && getMap().isTileSolid( pos + Vec2f(-1.3f*blob.getRadius(), 5.0f)*1.2f ) )	||
			 (blob.isKeyPressed( key_left ) && getMap().isTileSolid( pos + Vec2f(-1.3f*blob.getRadius(), -5.0f)*1.2f ) )
				)
		{
			blob.setKeyPressed( key_up, true );
		}
	//}
}

void JustGo( CBrain@ this, Vec2f point )
{
    CBlob @blob = this.getBlob();
    Vec2f mypos = blob.getPosition();
    f32 distance = (point - mypos).Length();

	//print("in just go");
	//print(formatFloat(point.x/t(1), ""));
    if (distance > 1.5f * blob.getRadius())
    {
        if (point.x < mypos.x) {
            blob.setKeyPressed( key_left, true );
        }
        else {
            blob.setKeyPressed( key_right, true );
        }

        this.getBlob().Untag("at post");
    }
    else if ( this.getTarget() !is null && this.getTarget().getName() == "tradingpost" )
    {
        this.getBlob().Tag("at post");
    }

    this.getBlob().Sync("at post", true);

    if (distance < 40.0f && point.y + getMap().tilesize + blob.getRadius() < mypos.y) {
        blob.setKeyPressed( key_up, true );
    }
}

