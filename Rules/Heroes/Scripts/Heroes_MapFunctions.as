// Heroes Map Utilities
// Author: Nand

const f32 wall = 10.0f;
const f32 baseZone = 44.0f;
const f32 centerZone = 262.0f;
const f32 zoneWidth = 370.0f; 

const u16 bottomZone = 29.0f;
const u16 middleZone = 25.0f;
const u16 topZone = 46.0f;
const u16 roofZone = 21.0f;
const f32 zoneHeight = 100.0f; 



shared bool determineSide( CBlob@ blob){
	return blob.getPosition().x > t(zoneWidth/2);
}

shared bool determineSide( Vec2f loc){
	return loc.x > t(zoneWidth/2);
}

//Converts to tilemapsize
shared f32 t(f32 loc){
	CMap@ map = getMap();
	return map.tilesize * loc;
}

shared Vec2f t(Vec2f vecLoc){
	return Vec2f(t(vecLoc.x), t(vecLoc.y));
}

shared u8 determineZone( CBlob@ blob){
	if( blob.getPosition().y < t(topZone)){
		return 0;
	}
	else if( blob.getPosition().y < t(topZone + middleZone)){
		return 1;
	}
	
	return 2;
}

shared u8 determineZone( Vec2f loc){
	if( loc.y < t(topZone)){
		return 0;
	}
	else if( loc.y < t(topZone + middleZone)){
		return 1;
	}
	
	return 2;
}

shared u8 determineXZone( CBlob@ blob){
	if( blob.getPosition().x < t(baseZone + wall)){
		return 0;
	}
	else if( blob.getPosition().x < t(baseZone + centerZone + wall)){
		return 2;
	}
	
	return 1;
}

shared u8 determineXZone( Vec2f loc){
	if( loc.x < t(baseZone + wall)){
		return 0;
	}
	else if( loc.x < t(baseZone + centerZone + wall * 2)){
		return 2;
	}
	
	return 1;
}
