// Portal logic

#include "Explosion.as"
#include "Heroes_MapFunctions.as"

void onInit( CBlob@ this )
{
    this.getShape().SetStatic(true);
    this.getShape().getConsts().mapCollisions = false;


	this.getSprite().SetZ( -50.0f ); // push to background
}

void onDie( CBlob@ this ){
	Vec2f thisPos = this.getPosition();
	Explode(this,96.0f,8.0f);
	if(getNet().isServer()){
		CBlob@ entrance = server_CreateBlob("portaldead", this.getTeamNum(), thisPos);
		entrance.Tag("entrance");
		Vec2f[] portalPos;
		CMap@ map = getMap();
		if(map.getMarkers("portal marker", portalPos)){
			for (uint i = 0; i < portalPos.length; i++){
				if(determineSide(portalPos[i]) == determineSide(this)
				&& determineZone(portalPos[i]) != determineZone(this)){
					if(this.getTeamNum() == 0){
						CBlob@ exit = server_CreateBlob("portaldead", 1, portalPos[i]);
						exit.Tag("exit");
					}
					else{
						CBlob@ exit = server_CreateBlob("portaldead", 0, portalPos[i]);
						exit.Tag("exit");
					}
					break;
				}
			}
		}
	}
}
