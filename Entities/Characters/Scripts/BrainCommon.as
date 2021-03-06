// brain

#include "/Entities/Common/Emotes/EmotesCommon.as"
#include "Heroes_MapFunctions.as"

#define SERVER_ONLY

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		chasing,
		attacking,
		retreating
	}
}

void InitBrain( CBrain@ this )
{
	CBlob @blob = this.getBlob();
	blob.set_Vec2f("last pathing pos", Vec2f_zero);
	blob.set_u8("strategy", Strategy::idle);
	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run

	if (!blob.exists("difficulty")) {
		blob.set_s32("difficulty", 15); // max
	}
}

CBlob@ getNewTarget( CBrain@ this, CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false )
{

	if(blob.hasTag("retinue")){
		
		CBlob@ sergeant = getBlobByNetworkID(blob.get_u16("sergeant"));
		if(sergeant is null || sergeant.hasTag("dead")){
			blob.Untag("retinue");
			blob.Sync("retinue", true);
			print("unretinue");
			blob.SetDamageOwnerPlayer(null);
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

			int direction = sergeant.get_u8("direction");
			int distance;

			if(direction == 0 || direction == 1){
				distance = 15;
				pos = blob.getPosition();
			}
			else if(direction == 3){
				distance = 5;
			}
			else
				distance = 10;


			for (uint i=0; i < potentials.length; i++)
			{

				CBlob@ potential = potentials[i];	
				Vec2f pos2 = potentials[i].getPosition();
				f32 enemyDist = (pos2 - pos).Length();
				if (blob.getTeamNum() != potential.getTeamNum()
					&& determineZone(blob) == determineZone(potential)
					&& enemyDist < t(distance)
					/*&& ((direction == 2 && (pos2 - pos).Length() < t(distance)) ||
					    (direction == 0 && (pos.x - pos2.x < t(distance) )) ||
						(direction == 1 && (pos2.x - pos.x < t(distance))))*/
					&& isVisible(blob, potential)
					&& !potential.hasTag("dead")
					&& !potential.hasTag("cloaked")
					&& !( potential.getName() == "scout" && enemyDist > t(7))
				)
				{
					if(enemyDist <= closestDist){
						closestDist = enemyDist;
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

	
	Vec2f pos = blob.getPosition();

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
			&& !( potential.getName() == "archer" && pos2.y < pos.y - t(6))
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
		f32 enemyDist = (pos2 - pos).Length();
		if (blob.getTeamNum() != potential.getTeamNum()
			&& determineZone(blob) == determineZone(potential)
			&& enemyDist < t(20)
			&& isVisible(blob, potential)
			&& !potential.hasTag("dead")
			&& !potential.hasTag("cloaked")
			&& !( potential.getName() == "scout" && enemyDist > t(7))
			)
		{
			if(enemyDist <= closestDist){
				closestDist = enemyDist;
				closest = i;
				towerClose = false;
				closeHuman = true;
				closeBot = false;
			}
			if(enemyDist < t(5) || (superCloseHuman && enemyDist < (humans[superClose].getPosition() - pos).Length() )){
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
		if(waypoint.getShape().isStatic() &&
		   determineZone(blob) == determineZone(waypoint) &&
		   waypoint.getTeamNum() == blob.getTeamNum() &&
		   ((blob.getTeamNum() == 0 && xDistance >= 0) ||
		    (blob.getTeamNum() == 1 && xDistance <= 0))
		){
			xDistance = Maths::Abs(xDistance);
			// Ignore a waypoint if you've been at it for a while
				if(
				xDistance < closestDist &&
				blob.get_u16("stuckTime") < 3 * getTicksASecond()){ 
				existsWaypoint = true;
				closestDist = xDistance;
				waypointIndex = i;
			}
		}
	}

	if(existsWaypoint){
		return waypoints[waypointIndex];
	}

	CBlob@[] halls;
    getBlobsByName( "hall", @halls );


	bool closeHall = false;
	// Only attack halls if not already in enemy base
	if(determineXZone(blob) == 2){
		for (uint i=0; i < halls.length; i++){
			f32 xDistance = halls[i].getPosition().x - pos.x;
			if(halls[i].getTeamNum() != blob.getTeamNum()
			  && determineZone(halls[i]) == determineZone(blob)
			  && Maths::Abs(halls[i].getPosition().x - pos.x) < closestDist
			  && ((blob.getTeamNum() == 0 && xDistance >= 0) ||
		    	  (blob.getTeamNum() == 1 && xDistance <= 0))
			){
				closeHall = true;
				closestDist = Maths::Abs(halls[i].getPosition().x - pos.x);
				closest = i;
			}
		}
	}


	if(closeHall){
		return halls[closest];
		
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

void Repath( CBrain@ this )
{
	this.SetPathTo( this.getTarget().getPosition(), false );
}

bool isVisible( CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid( blob.getPosition(), target.getPosition(), col );
}

bool isVisible( CBlob@ blob, CBlob@ target, f32 &out distance)
{
	Vec2f col;
	bool visible = !getMap().rayCastSolid( blob.getPosition(), target.getPosition(), col );
	distance = (blob.getPosition() - col).getLength();
	return visible;
}

void JustGo( CBlob@ blob, CBlob@ target )
{
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();

	/*if(horiz_distance < t(0.5) && target.getName() == "waypoint"){
		blob.setKeyPressed( key_up, true );
	}
	else*/
	bool retinue = target.getTeamNum() == blob.getTeamNum() && target.hasTag("human");
	int direction = 4;
	if(retinue){
		direction = target.get_u8("direction");
		//print(formatInt(direction, ""));
		if(direction == 0){
			point.x -= t(16);
		}
		else if(direction == 1){
			point.x += t(16);
		}
		blob.setAimPos(point);
	} // hack to get units off the top off the portal
	else if(target.getName() == "portal" && Maths::Abs(point.x - mypos.x) < t(10) && 
			mypos.y < point.y){
		if(blob.hasTag("blue"))
			blob.setKeyPressed(key_left, true);
		else
			blob.setKeyPressed(key_right, true);
		return;
	}
	
	const f32 horiz_distance = Maths::Abs(point.x - mypos.x);

	/*if(retinue && direction == 2 && horiz_distance < t(3) && point.y + t(1) < mypos.y){
		blob.setKeyPressed( key_up, true );
	}*/

	int limiter;

	if(direction == 3){
		limiter = t(1);
		if(horiz_distance < t(2)){
			if(retinue && target.isKeyPressed(key_up))
				blob.setKeyPressed(key_up, true);
			if(retinue && target.isKeyPressed(key_left))
				blob.setKeyPressed(key_left, true);
			if(retinue && target.isKeyPressed(key_right))
				blob.setKeyPressed(key_right, true);
		}
	}
	else{
		limiter = t((blob.get_u8("personality") % 50) / 10 + 2);
	}

	if(!(retinue && horiz_distance < limiter) &&
	   !(target.getName() == "hall" && horiz_distance < t(blob.get_u8("personality") % 2 + 2))){
		if (point.x < mypos.x) {
			blob.setKeyPressed( key_left, true );
			blob.SetFacingLeft(true);
		}
		else {
			blob.setKeyPressed( key_right, true );
			blob.SetFacingLeft(false);
		}

		if(target.getName() == "waypoint" && horiz_distance < t(2) && !target.hasTag("up")){
			if(blob.getTeamNum() == 0){
				blob.setKeyPressed( key_right, true);
				print("way1");
			}
			else if(blob.getTeamNum() == 1){
				blob.setKeyPressed( key_left, true);
			}

		}else if (point.y + getMap().tilesize*0.7f < mypos.y && (target.isOnGround()) ||
			(point.y - t(1) < mypos.y && target.getName() == "waypoint" && target.hasTag("up") &&
			 horiz_distance < t(3))){

			blob.setKeyPressed( key_up, true );
		}

		if (blob.isOnLadder() && point.y > mypos.y) {
			blob.setKeyPressed( key_down, true );
		}
	}

}

void JumpOverObstacles( CBlob@ blob )
{
	if(blob.getBrain().getTarget().getName() == "waypoint"){
		blob.setKeyPressed(key_right, true);
	}
	Vec2f pos = blob.getPosition();
		const f32 radius = blob.getRadius();
		if((pos.x < t(baseZone + wall + 2) && pos.x > t(baseZone - 6.0f))
		|| (pos.x > t(zoneWidth - baseZone - wall - 2)) && pos.x < t(zoneWidth - (baseZone - 6.0f)))
		{ return;}
		if (blob.isOnWall()){
			blob.setKeyPressed( key_up, true );
		}
		else
			if (!blob.isOnLadder())
				if ( (blob.isKeyPressed( key_right ) && (getMap().isTileSolid( pos + Vec2f( 1.3f*radius, radius)*1.0f ) || blob.getShape().vellen < 0.1f) ) ||
					(blob.isKeyPressed( key_left )  && (getMap().isTileSolid( pos + Vec2f(-1.3f*radius, radius)*1.0f ) || blob.getShape().vellen < 0.1f) ) )
				{
					blob.setKeyPressed( key_up, true );
				}
}

void DefaultChaseBlob( CBlob@ blob, CBlob @target )
{
	// check if we have a clear area to the target

	// repath if no clear path after going at it
	/*if (XORRandom(50) == 0 && (blob.get_Vec2f("last pathing pos") - targetPos).getLength() > 50.0f)
	{
		Repath( brain );
		blob.set_Vec2f("last pathing pos", targetPos );
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (!isFriendAheadOfMe( blob, target ))
		{
			if (state == CBrain::has_path) {
				brain.SetSuggestedKeys();  // set walk keys here
			}
			else {
			}
		}

		// printInt("state", this.getState() );
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
	}*/


	JustGo( blob, target );

	// face the enemy
	if(!blob.hasTag("stuck") && !(target.hasTag("human") && target.getTeamNum() == blob.getTeamNum())){
		blob.setAimPos( target.getPosition() );
	}

	// jump over small blocks	
	if(!(target.getName() == "waypoint" && !target.hasTag("up") &&
		(target.getPosition() - blob.getPosition()).Length() < t(3) )){
		JumpOverObstacles( blob );
	}
	else{
		if(blob.getTeamNum() == 0){
			blob.setKeyPressed( key_right, true);
		}
		else if(blob.getTeamNum() == 1){
			blob.setKeyPressed( key_left, true);
		}

	}
}

bool DefaultRetreatBlob( CBlob@ blob, CBlob@ target )
{
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	if (point.x > mypos.x) {
		blob.setKeyPressed( key_left, true );
	}
	else {
		blob.setKeyPressed( key_right, true );
	}

	if (mypos.y-blob.getRadius() > point.y) {
		blob.setKeyPressed( key_up, true );
	}

	if (blob.isOnLadder() && point.y < mypos.y) {
		blob.setKeyPressed( key_down, true );
	}

	JumpOverObstacles( blob );

	return true;
}

void SearchTarget( CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true )
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none

	CBlob@ oldTarget = target;
	@target = getNewTarget(this, blob, seeThroughWalls, seeBehindBack);
	this.SetTarget( target );

	if (target !is oldTarget) {
		onChangeTarget( blob, target, oldTarget );
	}
	
}	   

void onChangeTarget( CBlob@ blob, CBlob@ target, CBlob@ oldTarget )
{
	//set_emote( blob, Emotes::attn, 1 );
	blob.set_u16("target", target.getNetworkID());
	blob.Sync("target", true);
}

bool LoseTarget( CBrain@ this, CBlob@ target )
{
	if (XORRandom(5) == 0 && target.hasTag("dead"))
	{
		@target = null;
		this.SetTarget( target );
		return true;
	}
	return false;
}

void Runaway( CBlob@ blob, CBlob@ target )
{
	blob.setKeyPressed( key_left, false );
	blob.setKeyPressed( key_right, false );
	if (target.getPosition().x > blob.getPosition().x) {
		blob.setKeyPressed( key_left, true );
	}
	else {
		blob.setKeyPressed( key_right, true );
	}
}

void Chase( CBlob@ blob, CBlob@ target )
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	blob.setKeyPressed( key_left, false );
	blob.setKeyPressed( key_right, false );
	if (targetPos.x < mypos.x) {
		blob.setKeyPressed( key_left, true );
	}
	else {
		blob.setKeyPressed( key_right, true );
	}

	if (targetPos.y + getMap().tilesize > mypos.y) {
		blob.setKeyPressed( key_up, true );
	}
}

bool isFriendAheadOfMe( CBlob @blob, CBlob @target, const f32 spread = 70.0f )
{
	//NAND
	return false;
	// optimization
	if ((getGameTime() + blob.getNetworkID()) % 10 > 0 && blob.exists("friend ahead of me"))
	{
		return blob.get_bool("friend ahead of me");
	}
												
	CBlob@[] players;
	getBlobsByTag( "player", @players );
	Vec2f pos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	for (uint i=0; i < players.length; i++)
	{
		CBlob@ potential = players[i];	
		Vec2f pos2 = potential.getPosition();
		if (potential !is blob && blob.getTeamNum() == potential.getTeamNum()
			&& (pos2 - pos).getLength() < spread
			&& (blob.isFacingLeft() && pos.x > pos2.x && pos2.x > targetPos.x) ||  (!blob.isFacingLeft() && pos.x < pos2.x && pos2.x < targetPos.x) 
			&& !potential.hasTag("dead") && !potential.hasTag("migrant")
			)
		{
			blob.set_bool("friend ahead of me", true);
			return true;
		}
	}
	blob.set_bool("friend ahead of me", false);
	return false;
}

void FloatInWater( CBlob@ blob )
{
	if (blob.isInWater())
	{	
		blob.setKeyPressed( key_up, true );
	} 
}

void RandomTurn( CBlob@ blob )
{
	if (XORRandom(4) == 0)
	{
		CMap@ map = getMap();
		blob.setAimPos( Vec2f( XORRandom( int(map.tilemapwidth*map.tilesize)), XORRandom( int(map.tilemapheight*map.tilesize) ) ) );
	}
}
