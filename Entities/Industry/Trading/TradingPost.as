﻿// Trading Post

#include "MakeDustParticle.as";
							 
void onInit( CBlob@ this )
{	    
	this.getSprite().SetZ( -50.0f ); // push to background
	this.getShape().getConsts().mapCollisions = false;	   
	
	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));

	//TODO: set shop type and spawn trader based on some property
	this.server_setTeamNum(0);
}

void onInit (CSprite@ this){
	Animation@ shopframe = this.getAnimation("default");
	CBlob@ post = this.getBlob();

	if(post.hasTag("magic")){
		this.animation.frame = 1;
	}
	else if(post.hasTag("weapons")){

		this.animation.frame = 2;
	}
	else if(post.hasTag("armor")){
		this.animation.frame = 3;
	}
	else
		this.animation.frame = 0;
}

   

//Sprite updates

void onTick( CSprite@ this )
{
    //TODO: empty? show it.
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (hitterBlob.getTeamNum() == this.getTeamNum() && hitterBlob !is this) {
        return 0.0f;
    } //no griffing

	this.Damage( damage, hitterBlob );

	return 0.0f;
}


void onHealthChange( CBlob@ this, f32 oldHealth )
{
	CSprite @sprite = this.getSprite();

	if (oldHealth > 0.0f && this.getHealth() < 0.0f)
	{
		MakeDustParticle(this.getPosition(), "Smoke.png");
		this.getSprite().PlaySound("/BuildingExplosion");
	}
}
