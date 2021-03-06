//trap block script for devious builders

#include "Hitters.as"
#include "MapFlags.as"

int openRecursion = 0;

void onInit(CBlob@ this){
	this.getShape().SetRotationsAllowed( false );
    this.getSprite().getConsts().accurateLighting = true;
    //this.set_bool("open", false);    
    this.Tag("place norotate");

	this.addCommandID("enable switch");

	this.Tag("up");
    
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;	 
}


void onInit(CSprite@ this){
	this.animation.frame = 0;
}


void GetButtonsFor(CBlob@ this, CBlob@ caller){
	CBitStream params;
	params.write_u16( caller.getNetworkID() );
	if(this.getTeamNum() == caller.getTeamNum() && this.getShape().isStatic()){
		string description = this.hasTag("up") ? "Set as Ground Waypoint" : "Set as Jump Waypoint";
		CButton@ button = caller.CreateGenericButton(2, Vec2f_zero, this, this.getCommandID("enable switch"), description, params);
	}
	
}

void onCommand(CBlob @this, u8 cmd, CBitStream @params){
	CSprite@ sprite = this.getSprite();
	if( cmd == this.getCommandID("enable switch")){
		if(this.hasTag("up")){
			sprite.animation.frame = 1;
			this.Untag("up");
		}
		else{
			sprite.animation.frame = 0;
			this.Tag("up");
		}
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() == "arrow" && blob.getTeamNum() != this.getTeamNum())
		return true;
	return false;
}


bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}


f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData ){
	switch(customData){
		case Hitters::sword:
		case Hitters::stab:
			return damage / 2;
			break;
		case Hitters::builder:
			if(this.getTeamNum() == hitterBlob.getTeamNum()){
				return damage * 2;
			}
			break;
		case Hitters::arrow:
			return damage * 2;
			break;
	}
	return damage;
}

