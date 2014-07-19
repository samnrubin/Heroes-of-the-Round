// Archer brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "ArcherCommon.as"
#include "Heroes_MapFunctions.as"

void onInit( CBrain@ this )
{
	InitBrain( this );
}

void onTick( CBrain@ this )
{
	/*CBlob@[] nands;
				getMap().getBlobsInRadius(this.getBlob().getPosition(), t(3), @nands);
				for(uint i = 0; i < nands.length; i++){
					if(nands[i].hasTag("human")){
						print(this.getTarget().getName());
						print(formatInt(this.getBlob().get_u8("strategy"), ""));
						break;
					}
				}*/
	
	SearchTarget( this, false, true );

    CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// logic for target
								   	
	this.getCurrentScript().tickFrequency = 29;
    if (target !is null)
    {			
		this.getCurrentScript().tickFrequency = 1;

		u8 strategy = blob.get_u8("strategy");
		const bool gotarrows = hasArrows( blob );
		if (!gotarrows) {
			strategy = Strategy::idle;
			blob.server_Die();
		}
		else if (strategy == Strategy::idle || strategy == Strategy::retreating)
		{
			strategy = Strategy::chasing; 
		}
		

		f32 distance;
		const bool visibleTarget = isVisible( blob, target, distance);
		if (visibleTarget) 
		{
			if ( distance < t(3) && target.hasTag("player") &&
			!(target.getTeamNum() == blob.getTeamNum()) || !gotarrows || target.getName() == "wartowerbottom")
				strategy = Strategy::retreating; 
			else
				if (gotarrows) {
					strategy = Strategy::attacking; 
				}
		}
		else if(strategy == Strategy::attacking){
			strategy = Strategy::chasing;
		}
					   		
		UpdateBlob( blob, target, strategy ); 

        // lose target if its killed (with random cooldown)

		if (LoseTarget( this, target )) {
			strategy = Strategy::idle;
		}

		blob.set_u8("strategy", strategy);	  
    }
	else
	{
		RandomTurn( blob );
	}

	FloatInWater( blob );
}

void ArcherSearchTarget( CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true )
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none

	CBlob@ oldTarget = target;
	@target = archerGetNewTarget(this, blob, seeThroughWalls, seeBehindBack);
	this.SetTarget( target );

	if (target !is oldTarget) {
		onChangeTarget( blob, target, oldTarget );
	}
	
}


CBlob@ archerGetNewTarget( CBrain@ this, CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false )
{

	Vec2f pos = blob.getPosition();


	{
		CBlob@[] scouts;
		getBlobsByName( "scout", @scouts );
		f32 closestDist = t(300);
		int closest;
		bool scoutClose = false;

		
		for (uint i=0; i < scouts.length; i++)
		{
			CBlob@ potential = scouts[i];	
			Vec2f pos2 = potential.getPosition();
			if (!(potential.getTeamNum() == blob.getTeamNum())
				&& determineZone(blob) == determineZone(potential)
				&& (pos2 - pos).Length() < t(30)
				&& isVisible(blob, potential)
				&& !potential.hasTag("dead")
				)
			{
				f32 dist = (pos - pos2).Length();
				if(dist < closestDist){
					closestDist = dist;
					closest = i;
					scoutClose = true;
				}
			}
		}
		if(scoutClose)
			return scouts[closest];
	}

	if(blob.hasTag("retinue")){
		
		CBlob@ sergeant = getBlobByNetworkID(blob.get_u16("sergeant"));
		if(sergeant is null || sergeant.hasTag("dead")){
			blob.Untag("retinue");
		}
		else{
			f32 closestDist = t(300);
			uint closest;
			Vec2f pos = sergeant.getPosition();
			CBlob@[] potentials;
			getBlobsByTag( "human", @potentials );
			if(blob.hasTag("blue"))
				getBlobsByTag( "red", @potentials );
			else
				getBlobsByTag("blue", @potentials );
			getBlobsByName("wartowerbottom", @potentials);

			int direction = blob.get_u8("direction");
			int distance;

			if(direction == 0 || direction == 1){
				distance = 25;
				pos = blob.getPosition();
			}
			else if(blob.hasTag("close")){
				distance = 5;
			}
			else
				distance = 20;


			for (uint i=0; i < potentials.length; i++)
			{

				CBlob@ potential = potentials[i];	
				Vec2f pos2 = potentials[i].getPosition();
				if (blob.getTeamNum() != potential.getTeamNum()
					&& determineZone(blob) == determineZone(potential)
					&& (pos2 - pos).Length() < t(distance)
					/*&& ((direction == 2 && (pos2 - pos).Length() < t(distance)) ||
					    (direction == 0 && (pos.x - pos2.x < t(distance) )) ||
						(direction == 1 && (pos2.x - pos.x < t(distance))))*/
					&& isVisible(blob, potential)
					&& !potential.hasTag("dead")
				)
				{
					f32 dist = (pos - pos2).Length();
					if(dist <= closestDist){
						closestDist = dist;
						closest = i;
					}

				}
			}
			if(closestDist < t(300)){
				return potentials[closest];
			}
			if(!(Maths::Abs(blob.getPosition().x - sergeant.getPosition().x) > t(50))){
				return sergeant;
			}
			else{
				blob.Untag("retinue");
				sergeant.set_u8("retinuesize", sergeant.get_u8("retinuesize") - 1);
			}
		}
	}

	

	CBlob@[] humans;
	getBlobsByTag( "human", @humans );

	f32 closestDist = t(300);

	CBlob@[] players;
	if(blob.hasTag("blue"))
		getBlobsByTag( "red", @players );
	else
		getBlobsByTag("blue", @players );


	CBlob@[] towers;
    getBlobsByName( "wartowerbottom", @towers );

	int mytower;

	bool towerClose = false;


	for(int i = 0; i < towers.length; i++){
		if(determineZone(blob) == determineZone(towers[i])
		   && (towers[i].getPosition() - pos).Length() < t(20)
		   && blob.getTeamNum() != towers[i].getTeamNum()){
		   mytower = i;
		   closestDist = (towers[i].getPosition() - pos).Length();
		   towerClose = true;
		   break;
		}
	}

	int closest = players.length + humans.length;

	bool closeBot = false;
	

	for (uint i=0; i < players.length; i++)
	{
		CBlob@ potential = players[i];	
		Vec2f pos2 = potential.getPosition();
		if (potential !is blob
			&& determineZone(blob) == determineZone(potential)
			&& (pos2 - pos).Length() < t(20)
			&& isVisible(blob, potential)
			&& !potential.hasTag("dead")
			)
		{
			f32 dist = (pos - pos2).Length();
			if(dist < closestDist){
				closestDist = dist;
				closest = i;
				towerClose = false;
				closeBot = true;
			}
		}
	}

	bool closeHuman = false;


	int superClose;
	bool superCloseHuman = false;
	//f32 closestDist = t(100);

	for (uint i=0; i < humans.length; i++)
	{
		CBlob@ potential = humans[i];	
		Vec2f pos2 = humans[i].getPosition();
		if (blob.getTeamNum() != potential.getTeamNum()
			&& determineZone(blob) == determineZone(potential)
			&& (pos2 - pos).Length() < t(20)
			&& isVisible(blob, potential)
			&& !potential.hasTag("dead")
			)
		{
			f32 dist = (pos - pos2).Length();
			if(dist <= closestDist){
				closestDist = dist;
				closest = i;
				towerClose = false;
				closeHuman = true;
				closeBot = false;
			}
			if(dist < t(5) || (superCloseHuman && dist < (humans[superClose].getPosition() - pos).Length() )){
				superCloseHuman = true;
				superClose = i;
			}

		}
	}
	
	// Determine results
	if(superCloseHuman){
		blob.set_Vec2f("last pathing pos", humans[superClose].getPosition() );
		return humans[superClose];
	}
	else if(towerClose){
		// DONT DUU IT IF YOURE ATTACKIN A BASE WHILE PORTALLED
		if(!blob.hasTag("portalled")){
			blob.set_Vec2f("last pathing pos", towers[mytower].getPosition() );
			return towers[mytower];
		}
	}
	else if(closeHuman){
		blob.set_Vec2f("last pathing pos", humans[closest].getPosition() );
		return humans[closest];
	}
	else if(closeBot){
		blob.set_Vec2f("last pathing pos", players[closest].getPosition() );
		return players[closest];  
	}


	CBlob@[] waypoints;
	int waypointIndex;
	bool existsWaypoint = false;
	
	getBlobsByName("waypoint", waypoints);
	for(uint i = 0; i < waypoints.length; i++){
		CBlob@ waypoint = waypoints[i];
		Vec2f pos2 = waypoint.getPosition();
		f32 xDistance = pos2.x - pos.x;
		if(waypoint.hasTag("enabled") &&
		   waypoint.getShape().isStatic() &&
		   determineZone(blob) == determineZone(waypoint) &&
		   waypoint.getTeamNum() == blob.getTeamNum() &&
		   ((blob.getTeamNum() == 0 && xDistance >= 0) ||
		    (blob.getTeamNum() == 1 && xDistance <= 0))
		){
			xDistance = Maths::Abs(xDistance);
			// Ignore a waypoint if you're already jumping above it or you've been at it for a while
				if(
				xDistance < closestDist &&
				blob.get_u16("stuckTime") < 3 * getTicksASecond()){ 
				existsWaypoint = true;
				closestDist = xDistance;
				waypointIndex = i;
			}
		}
	}

	CBlob@[] halls;
    getBlobsByName( "hall", @halls );


	// Only attack halls if not already in enemy base
	if(determineXZone(blob) == 2){
		for (uint i=0; i < halls.length; i++){
			if(halls[i].getTeamNum() != blob.getTeamNum()
			  && determineZone(halls[i]) == determineZone(blob)
			  && Maths::Abs(halls[i].getPosition().x - pos.x) < closestDist)
				return halls[i];
		}
	}

	if(existsWaypoint){
		return waypoints[waypointIndex];
	}

	CBlob@[] barracks;
    getBlobsByName( "barracks", @barracks );
	
	for (uint i=0; i < barracks.length; i++){
		if(barracks[i].getTeamNum() != blob.getTeamNum()
		  && determineZone(barracks[i]) == determineZone(blob))
			return barracks[i];
	}

	CBlob@[] archerbarracks;
    getBlobsByName( "archerbarracks", @archerbarracks );
	
	for (uint i=0; i < archerbarracks.length; i++){
		if(archerbarracks[i].getTeamNum() != blob.getTeamNum()
		  && determineZone(archerbarracks[i]) == determineZone(blob))
			return archerbarracks[i];
	}

	CBlob@[] portals;
    getBlobsByName( "portal", @portals );
	
	for (uint i=0; i < portals.length; i++){
		if(portals[i].getTeamNum() != blob.getTeamNum()
		  && determineZone(portals[i]) == determineZone(blob))
			return portals[i];
	}

	CBlob@[] deadPortals;
    getBlobsByName( "portaldead", @deadPortals );
	
	for (uint i=0; i < deadPortals.length; i++){
		if(deadPortals[i].hasTag("entrance")
		  && determineZone(deadPortals[i]) == determineZone(blob)
		  && deadPortals[i].getTeamNum() != blob.getTeamNum())
			return deadPortals[i];
	}
	
	return null;
}

void UpdateBlob( CBlob@ blob, CBlob@ target, const u8 strategy )
{
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();

	if ( strategy == Strategy::chasing ) {
		JustGo( blob, target );

		// face the enemy
		if(!(target.hasTag("human") && target.getTeamNum() == blob.getTeamNum())){
			blob.setAimPos( target.getPosition() );
		}

		// jump over small blocks	
		JumpOverObstacles( blob );
	}
	else if ( strategy == Strategy::retreating ) {		
		DefaultRetreatBlob( blob, target );		
		if((myPos - targetPos).Length() < t(10) && isVisible(blob, target)){

			AttackBlob( blob, target );
		}
	}
	else if ( strategy == Strategy::attacking && target.hasTag("player") && target.getTeamNum() != blob.getTeamNum())	{		
		AttackBlob( blob, target );
	}
}



	 
void AttackBlob( CBlob@ blob, CBlob @target )
{
    Vec2f mypos = blob.getPosition();
    Vec2f targetPos = target.getPosition();
    Vec2f targetVector = targetPos - mypos;
    f32 targetDistance = targetVector.Length();

	JumpOverObstacles(blob);

	const u32 gametime = getGameTime();		 
		   
	// fire

	if (targetDistance > 25.0f)
	{
		u32 fTime = blob.get_u32( "fire time"); // first shot
		bool fireTime = gametime < fTime;

		if (!fireTime && (fTime == 0 || XORRandom(90) == 0))		// difficulty
		{
			const f32 vert_dist = Maths::Abs(targetPos.y - mypos.y);
			const u32 shootTime = Maths::Max( ArcherParams::ready_time, Maths::Min(uint(targetDistance*(0.3f*Maths::Max(130.0f,vert_dist)/100.0f)+XORRandom(20)), ArcherParams::shoot_period ) );
			blob.set_u32( "fire time", gametime + shootTime );
		}

		if (fireTime)
		{				
			bool worthShooting;
			bool hardShot = targetDistance > 30.0f*8.0f || target.getShape().vellen > 5.0f;
			f32 aimFactor = 0.45f-XORRandom(100)*0.003f;
			aimFactor += (-0.2f + XORRandom(100)*0.004f) / 50.0f; //DIFFICULTY
			blob.setAimPos( blob.getBrain().getShootAimPosition( targetPos, hardShot, worthShooting, aimFactor ) );
			if (worthShooting)
			{
				blob.setKeyPressed( key_action1, true );
			}
		}
	}
	else
	{
		blob.setAimPos( targetPos );
	}
}

