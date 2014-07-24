#include "EmotesCommon.as"
#include "Heroes_MapFunctions.as"

void handleEmote(CBlob@ this, int emote){
	if(this.getName() == "sapper")
		sapperCommand(this, emote);
	else if(this.hasTag("sapperposer")){
		sapperCommand(this, emote, 20, 20);
	}
}

void sapperCommand(CBlob@ this, int emote, int radius = 10, int maxretinue = 3){
	if(emote == Emotes::knight){
		if(!this.exists("retinuesize")){
			this.set_u8("retinuesize", 0);
		}
		u8 retinuesize = this.get_u8("retinuesize");
		CBlob@[] knights;
		this.getMap().getBlobsInRadius(this.getPosition(), t(radius), knights);
		this.set_u8("direction", 2);

		for(uint i = 0; i < knights.length && retinuesize < maxretinue; i++){
			CBlob@ knight = knights[i];
			if(knight.getName() == "knight" &&
			   knight.getTeamNum() == this.getTeamNum() &&
			   !knight.hasTag("retinue")
			){
				knight.Tag("retinue");
				knight.set_u16("sergeant", this.getNetworkID());
				set_emote(knight, Emotes::builder);
				knight.SetDamageOwnerPlayer(this.getPlayer());
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
				if(!knight.hasTag("personalGuard"))
					knight.Untag("retinue");
					knight.SetDamageOwnerPlayer(null);
			}
			
		}
	}
	else if(emote == Emotes::left){
		this.set_u8("direction", 0);
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::left);
			}
			
		}
		
	}
	else if(emote == Emotes::right){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);
		this.set_u8("direction", 1);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::right);
			}
			
		}
		
	}
	else if(emote == Emotes::down){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);
		this.set_u8("direction", 2);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::builder);
			}
			
		}
	}
	else if(emote == Emotes::wall){
		CBlob@[] knights;
		getBlobsByTag("retinue", @knights);
		this.set_u8("direction", 3);

		for(uint i = 0; i < knights.length; i++){
			CBlob@ knight = knights[i];
			if(knight.get_u16("sergeant") == this.getNetworkID()){
				set_emote(knight, Emotes::wall);
			}
			
		}
	}

}
