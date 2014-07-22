// Portal logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "Explosion.as"
#include "Heroes_MapFunctions.as"

void onInit( CBlob@ this )
{
    this.CreateRespawnPoint( "portal", Vec2f(0.0f, 0.0f) );
	AddIconToken( "$knight_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 12);
	AddIconToken( "$archer_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 16 );
	AddIconToken( "$builder_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 8 );
	AddIconToken( "$change_class$", "GUI/InteractionIcons.png", Vec2f(32,32), 12, 2 );
    //Heroes classes
    addPlayerClass( this, "Paladin", "$knight_class_icon$", "paladin", "Hack and Slash." );
    addPlayerClass( this, "Ranger", "$archer_class_icon$", "scout", "The Ranged Advantage." );
    addPlayerClass( this, "Sergeant", "$builder_class_icon$", "sapper", "Sapper" );
    this.getShape().SetStatic(true);
    this.getShape().getConsts().mapCollisions = false;
    this.addCommandID("class menu");
    this.addCommandID("respawn");
	this.Tag("change class");
	//this.Tag("bed");


	this.getSprite().SetZ( -50.0f ); // push to background
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("class menu"))
    {
        u16 callerID = params.read_u16();
        CBlob@ caller = getBlobByNetworkID( callerID );

        if (caller !is null && caller.isMyPlayer())     {
            BuildRespawnMenuFor( this, caller );
        }
    }
	else if(cmd == this.getCommandID("respawn")){
	}
    else {
        onRespawnCommand( this, cmd, params );
    }
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
    if (canChangeClass( this, caller )) 
	{
		Vec2f pos = this.getPosition();
		if ((pos - caller.getPosition()).Length() < this.getRadius()) {
			BuildRespawnMenuFor( this, caller );
		}
		else 
		{
			CBitStream params;
			params.write_u16( caller.getNetworkID() );
			caller.CreateGenericButton( "$change_class$", Vec2f(0, 12), this, this.getCommandID("class menu"), "Change class", params );
		}
    }

    // warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
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
