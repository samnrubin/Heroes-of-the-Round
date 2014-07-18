#include "EmotesCommon.as"
#include "Heroes_MapFunctions.as"

void handleEmote(CBlob@ this, int emote){
	if(this.getName() == "sapper")
		sapperCommand(this, emote);
}

void sapperCommand(CBlob@ this, int emote){
	if(emote == Emotes::knight){
		if(!this.exists("retinuesize")){
			this.set_u8("retinuesize", 0);
		}
		u8 retinuesize = this.get_u8("retinuesize");
		CBlob@[] knights;
		this.getMap().getBlobsInRadius(this.getPosition(), t(10), knights);

		for(uint i = 0; i < knights.length && retinuesize < 3; i++){
			CBlob@ knight = knights[i];
			if(knight.getName() == "knight" &&
			   knight.getTeamNum() == this.getTeamNum() &&
			   !knight.hasTag("retinue")
			){
				knight.Tag("retinue");
				knight.set_u16("sergeant", this.getNetworkID());
				knight.set_u8("direction", 2);
				set_emote(knight, Emotes::builder);
				retinuesize++;
			}
		}
		this.set_u8("retinuesize", retinuesize);
		return;
	}
	else if(emote == Emotes::builder){
		this.set_u8("retinuesize", 0);
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::knight);
				knight.Untag("retinue");
			}
			
		}
	}
	else if(emote == Emotes::left){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::left);
				knight.set_u8("direction", 0);
			}
			
		}
		
	}
	else if(emote == Emotes::right){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::right);
				knight.set_u8("direction", 1);
			}
			
		}
		
	}
	else if(emote == Emotes::down){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::builder);
				knight.set_u8("direction", 2);
				knight.set_u32("closetime", getGameTime());
				knight.Tag("close");
			}
			
		}
	}

}
