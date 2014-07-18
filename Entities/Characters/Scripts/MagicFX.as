// Magical effects and animations

#include "Heroes_MapFunctions.as";


const uint TELEPORT_PERIOD = 5 * getTicksASecond();

void onTick( CBlob@ this){
	if(this.hasTag("telehall")){
		if(getGameTime() - this.get_u32("tele_called") > TELEPORT_PERIOD){
			this.Untag("telehall");
			this.Sync("telehall", true);
			CBlob@[] halls;
			getBlobsByName("hall", @halls);
			bool hallFound = false;
			uint hallIndex;
			for(uint i = 0; i < halls.length; i++){
				if(determineZone(halls[i]) == determineZone(this) &&
				   this.getTeamNum() == halls[i].getTeamNum()){
					if(hallFound){
						if(this.getTeamNum() == 0){
							if(halls[i].getPosition().x > halls[hallIndex].getPosition().x)
								hallIndex = i;
						}
						else{
							if(halls[i].getPosition().x < halls[hallIndex].getPosition().x)
								hallIndex = i;
						}
					}
					else{
						hallIndex = i;
						hallFound = true;
					}
				}
			}
			if (hallFound)
			{
				CBlob@ scroll = getBlobByNetworkID(this.get_u16("magicobject"));
				if(scroll !is null){
					scroll.server_Die();
				}

				if (this.isMyPlayer())
				{
					Sound::Play( "MagicWand.ogg" );
				}
				else
				{
					Sound::Play( "MagicWand.ogg", this.getPosition() );
				}

				if(this.get_u8("retinuesize") > 0){
					CBlob@[] retinue;
					getBlobsByTag("retinue", @retinue);
					for(uint j = 0; j < retinue.length; j++){
						CBlob@ traveller = retinue[j];
						if(traveller.get_u16("sergeant") == this.getNetworkID() &&
						   (traveller.getPosition() - this.getPosition()).Length() < t(7)){
							traveller.setPosition(halls[hallIndex].getPosition());
							traveller.setVelocity( Vec2f_zero );
							
						}
					}
				}

				if (!this.isMyPlayer())
				{
					Sound::Play( "MagicWand.ogg", this.getPosition() );
				}


				this.setPosition(halls[hallIndex].getPosition());
				this.setVelocity( Vec2f_zero );
				return;
			}
			else{
				Sound::Play( "NoAmmo.ogg", this.getPosition(), 1.0f, 0.75f );
			}
		}
	}
	else if(this.hasTag("telehome")){
		if(getGameTime() - this.get_u32("tele_called") > TELEPORT_PERIOD){
			this.Untag("telehome");
			this.Sync("telehome", true);
			CBlob@[] portals;
			getBlobsByName("portal", @portals);
			getBlobsByName("portaldead", @portals);
			bool portalFound = false;
			
			if (this.isMyPlayer())
			{
				Sound::Play( "MagicWand.ogg" );
			}
			else
			{
				Sound::Play( "MagicWand.ogg", this.getPosition() );
			}
			
			for(uint i = 0; i < portals.length; i++){
				if(determineZone(portals[i]) == determineZone(this) &&
				   this.getTeamNum() == portals[i].getTeamNum() &&
				   !portals[i].hasTag("exit")){
				
				CBlob@ scroll = getBlobByNetworkID(this.get_u16("magicobject"));
				if(scroll !is null){
					scroll.server_Die();
				}
				
				if(this.get_u8("retinuesize") > 0){
					CBlob@[] retinue;
					getBlobsByTag("retinue", @retinue);
					for(uint j = 0; j < retinue.length; j++){
						CBlob@ traveller = retinue[j];
						if(traveller.get_u16("sergeant") == this.getNetworkID() &&
						   (traveller.getPosition() - this.getPosition()).Length() < t(7)){
							traveller.setPosition(portals[i].getPosition());
							traveller.setVelocity( Vec2f_zero );
							
						}
					}
				}

				
				if (!this.isMyPlayer())
				{
					Sound::Play( "MagicWand.ogg", this.getPosition() );
				}
				

				this.setPosition(portals[i].getPosition());
				this.setVelocity( Vec2f_zero );

				return;
				}
			}
		}
	}
}
f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData ){
	if(this.hasTag("telehall")){
		this.Untag("telehall");
		this.Sync("telehall", true);
		Sound::Play( "NoAmmo.ogg", this.getPosition(), 1.0f, 0.75f );
	}
	else if(this.hasTag("telehome")){
		this.Untag("telehome");
		this.Sync("telehome", true);
		Sound::Play( "NoAmmo.ogg", this.getPosition(), 1.0f, 0.75f );
	}
	return damage;
}


//SPRITES



void onInit( CSprite@ this )
{
    //init blue particles
    CSpriteLayer@ blue = this.addSpriteLayer( "blue_animation_large", "../Mods/KagMoba/Entities/Effects/Sprites/BlueParticles.png", 16, 20, -1, -1 );

    if (blue !is null)
    {
        {
            Animation@ anim = blue.addAnimation( "reg", 3, true );
            anim.AddFrame(0);
            anim.AddFrame(1);
            anim.AddFrame(2);
            anim.AddFrame(3);
        }
        blue.SetVisible( false );
        blue.SetRelativeZ( 10 );
    }
	this.getCurrentScript().tickFrequency = 12;	
}

void onTick( CSprite@ this )
{
	this.getCurrentScript().tickFrequency = 12; // opt
	CBlob@ blob = this.getBlob();		    
    CSpriteLayer@ blue = this.getSpriteLayer( "blue_animation_large");	   
	if (blue !is null)
	{
		//if we're teleporting
		if (blob.hasTag("telehall") || blob.hasTag("telehome"))
		{
			this.getCurrentScript().tickFrequency = 6;

			blue.SetVisible( true );

			//TODO: draw the fire layer with varying sizes based on var - may need sync spam :/
			blue.SetAnimation( "reg" );
			
		}
		else{
			blue.SetVisible(false);
		}
	}
}