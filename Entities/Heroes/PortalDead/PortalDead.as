// Author: Nand
// Please do not use without prior permission

// Dead Portal logic

#include "Heroes_MapFunctions.as"


void onInit( CBlob@ this )
{
    this.getShape().SetStatic(true);
    this.getShape().getConsts().mapCollisions = false;

	this.getSprite().SetZ( -50.0f ); // push to background
}



void onTick (CBlob@ this){
	//if (getNet().isServer()){
		CBlob@[] blobsInRadius;
		if((this.getMap().getBlobsInRadius(this.getPosition(), 1.7*this.getMap().tilesize, @blobsInRadius)) 
		 && this.hasTag("entrance")){
		 	for (uint i = 0; i < blobsInRadius.length; i++){
				CBlob@ caller = blobsInRadius[i];
				if(caller !is this){
					CBlob@ exit = exitPortal(this);
					if(exit !is null){
						Vec2f exitPos = Vec2f(exit.getPosition().x + t(1.0f), exit.getPosition().y - t(1.0f));
						caller.setPosition( exit.getPosition() );
						caller.setVelocity( Vec2f_zero );			  
						caller.Tag("portalled");			  

						if (caller.isMyPlayer())
						{
							Sound::Play( "Thunder2.ogg" );
						}
						else
						{
							Sound::Play( "Thunder2.ogg", this.getPosition() );
						}
					}
				}
			}
		}
	
	//}
}

CBlob@ exitPortal(CBlob@ entrancePortal){
	CBlob@[] deadPortals;
    getBlobsByName( "portaldead", @deadPortals );
	for (uint i = 0; i < deadPortals.length; i++){
		if(determineSide(deadPortals[i]) == determineSide(entrancePortal)
		&& determineZone(deadPortals[i]) != determineZone(entrancePortal)
		&& deadPortals[i].hasTag("exit") ){
			return deadPortals[i];
		}
	}
	return null;

}


