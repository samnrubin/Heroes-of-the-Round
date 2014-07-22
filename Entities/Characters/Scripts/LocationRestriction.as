#include "Heroes_MapFunctions.as";

void onTick(CBlob@ this){
	this.getCurrentScript().tickFrequency = 30;

	// Fixing topzone bugs
	if(this.getPosition().y <= t(topZone)){
		CBlob@[] tents;
		getBlobsByName("tent", @tents);
		for(int i = 0; i < tents.length; i++){
			if(tents[i].getTeamNum() == this.getTeamNum()){
				this.setPosition(tents[i].getPosition());
				this.setVelocity(Vec2f_zero);
				return;
			}
		}
	}

}
