﻿// Hall

#include "MigrantCommon.as";  
#include "HallCommon.as";
#include "Requirements.as"
#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"

#include "Help.as"

const int MIGRANTS = 5;
const int MIGRANT_COST = 30;	// these should probably be in war_vars.cfg...
const int CAPTURE_SECS = 45;	// is faster when more attackers			  
const bool NEUTRAL_IN_WATER = true; //go neutral if underwater
const int WATER_FLOOD_REQUIRED = 2; //2 or more "levels" of water to flood

const int EXCHANGE_COST = 15;

const int START_TICKETS = 10;
const int MAXIMUM_TICKETS = 25;
const int SHOW_TICKETS_TIME = 30*5;
const int REGENERATE_TICKET_TIME = 30*20; 	
const int REGENERATE_TICKETS_AMOUNT = 1;	//per one ticket
const int REPAIR_HALL_TIME = 30*45;			//if you run out

const bool USE_TICKETS = false; //off for now

const string buymigrantcmd = "buy migrant";

const string drowncmd = "drowned";

const string framecmd = "setframe";
const string exchangecmd = "exchange";

void onInit( CBlob@ this )
{
	//this.CreateRespawnPoint( "hallClassChange", Vec2f(0.0f, 0.0f) );
	this.getCurrentScript().tickFrequency = 30;

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.set_u8("migrants max", MIGRANTS );		   		 // how many physical migrants it needs
	this.Tag("change class sack inventory");

	this.addCommandID(buymigrantcmd);

	this.addCommandID(drowncmd);
	
	this.addCommandID(framecmd);
	this.addCommandID(exchangecmd);
	this.addCommandID("class menu");

	this.set_s32("capture time", 0 );
	this.set_s32("respawned time", 0 );
	
	this.set_s32("regenerate time", getGameTime() );
	
	this.set_u8("hall state", HallState::normal );

	this.set_Vec2f("travel button pos", Vec2f(-24.0, -5.0));

	AddIconToken( "$knight_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 12);
	AddIconToken( "$archer_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 16 );
	AddIconToken( "$builder_class_icon$", "GUI/MenuItems.png", Vec2f(32,32), 8 );
    //Heroes classes
    addPlayerClass( this, "Paladin", "$knight_class_icon$", "paladin", "Hack and Slash." );
    addPlayerClass( this, "Ranger", "$archer_class_icon$", "scout", "The Ranged Advantage." );
    addPlayerClass( this, "Sergeant", "$builder_class_icon$", "sapper", "Sapper" );


	// shipment

	//minimap icon
	SetMinimap( this );

	if(USE_TICKETS)
	{
		this.set_u16("tickets", START_TICKETS );
	}
	else
	{
		this.set_u16("tickets", 0xcdcd );
	}
	
	// hall workers
	if(getNet().isServer())
	{
		HallWorkerSet s(this);
		this.set(workers_property, s);
	}

	this.getShape().getConsts().waterPasses = false;

	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));

	// wont work in basichelps in single for some map loading reason
	SetHelp( this, "help use", "", "Change class    $KEY_E$", "", 5 );
}

void onTick( CBlob@ this )
{
	SetMinimap( this ); //needed for under raid check
	
	// capture HALL
	if( getNet().isServer() )
	{
		f32 height = this.getHeight();
		CMap@ map = this.getMap();
		
		const u8 state = this.get_u8("hall state" );
		if(NEUTRAL_IN_WATER && map.isInWater(this.getPosition() + Vec2f(0,height/2.0f - ((WATER_FLOOD_REQUIRED - 0.5f) * map.tilesize)) ) )
		{
			if(state != HallState::underwater)
			{
				Capture( this, -1 );   				
				this.SendCommand( this.getCommandID(drowncmd) );
			}
			
			return; //-------------------------------------------------------- early-out in water
		}
		
		
		//scratch vars
		const u32 gametime = getGameTime();
		bool raiding = false;
		
		const bool not_neutral = (this.getTeamNum() <= 10);

		// regenerate tickets

		if(USE_TICKETS)
		{
			const s32 regenTime = this.get_s32("regenerate time" );
			if (not_neutral && regenTime + REGENERATE_TICKET_TIME <= getGameTime())
			{					
				RegenTickets( this );
			}
		}
		
		//get relevant blobs
		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius( this.getPosition(), RAID_RADIUS, @blobsInRadius ))
		{
			
			Vec2f pos = this.getPosition();

			// first check if enemies nearby
			int attackersCount = 0;
			int friendlyCount = 0;
			int friendlyInProximity = 0;
			int attackerTeam;
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
			    if (b !is this && b.hasTag("player") && !b.hasTag("dead") && !b.hasTag("migrant"))
				{
					bool attacker = (b.getTeamNum() != this.getTeamNum());
					if(not_neutral && attacker)
					{
						raiding = true;
					}

					Vec2f bpos = b.getPosition();
					if (bpos.x > pos.x - this.getWidth()/2.0f && bpos.x < pos.x + this.getWidth()/2.0f &&
						bpos.y < pos.y + this.getHeight()/2.0f && bpos.y > pos.y - this.getHeight()/2.0f)
					{
						if (attacker)
						{
							attackersCount++;
							attackerTeam = b.getTeamNum();
						}
						else
						{
							friendlyCount++;
						}
					}

					if (!attacker)
					{
						friendlyInProximity++;
					}
				}
			}
						   
			if (raiding) //implies not neutral
			{
				this.set_u8("hall state", HallState::raid );
				this.Tag("under raid");
			}
		//printf("r friendlyCount " + friendlyCount + " " + this.getTeamNum() );

			if (attackersCount > 0 && ( friendlyCount == 0 || !not_neutral ) )
			{

				const int tickFreq = this.getCurrentScript().tickFrequency;
				s32 captureTime = this.get_s32("capture time" );		

				f32 imbalanceFactor = 1.0f;
				CRules@ rules = getRules();
				if (rules.exists("team 0 count") && rules.exists("team 1 count"))
				{
					const u8 team0 = rules.get_u8("team 0 count");
					const u8 team1 = rules.get_u8("team 1 count");
					if (getNet().isClient() || team0 <= 1)
					{  
						imbalanceFactor = 80.0f;	// super fast capture when nobody playing - singleplayer
					}
					else
					if (this.getTeamNum() == 0 && team1 > 0) {
						imbalanceFactor = float(team0) / float(team1);
					}
					else if (team0 > 0) {
						imbalanceFactor = float(team1) / float(team0);
					}
					
				}

				// faster capture under water
				if (getMap().isInWater( this.getPosition() + Vec2f(0.0f, this.getRadius()*0.66f) )) { 
					imbalanceFactor = 20.0f;
				}

				// faster capture if no friendly around
				if (imbalanceFactor < 20.0f && friendlyInProximity == 0) {
					imbalanceFactor = 6.0f;
				}
	
				captureTime += tickFreq * Maths::Max( 1, Maths::Min( Maths::Round(Maths::Sqrt(attackersCount)), 8)) * imbalanceFactor; // the more attackers the faster
				this.set_s32("capture time", captureTime );
				
				s32 captureLimit = getCaptureLimit(this);
				if (!not_neutral) { // immediate capture neutral hall
					captureLimit = 0;
				}

				if (captureTime >= captureLimit)
				{
					Capture( this, attackerTeam );
				}
	//			print("captureTime attack " + captureTime + " " + captureLimit );

				this.Sync("capture time", true );
				this.Sync("hall state", true );
				this.Sync("under raid", true );

				return;

				// NOTHING BEYOND THIS POINT

			}
			else
			{
				if (attackersCount > 0)
				{
					return;
				}

				ReturnState( this );
			}
		}
		else
		{
			ReturnState( this );
		}

		// update our worker objects and calculate capture
	
		// note: not much performed when under raid
		if (!getRules().exists("singleplayer") || getRules().exists("tutorial")) {
			updateWorkers(this, raiding);
		}

		// reduce capture if nothing going on

		s32 captureTime = this.get_s32("capture time" );
		if (captureTime > 0)
		{
			captureTime -= this.getCurrentScript().tickFrequency;
		}
		else
		{
			captureTime = 0;
		}
		
	   this.set_s32("capture time", captureTime );	   
	   this.Sync("capture time", true );
	   this.Sync( "hall state", true );		
	   this.Sync("under raid", true );
	}

}

void SyncFrame(CBlob@ this, u8 frame)
{
	CBitStream params;
	params.write_u8(frame);
	this.SendCommand( this.getCommandID(framecmd), params );
}

void ReturnState( CBlob@ this )
{
	this.Untag("under raid");
	
	u8 oldstate = this.get_u8("hall state");
	
	u8 state = this.get_u16("tickets") > 0 ? HallState::normal : HallState::depleted;
	this.set_u8("hall state", state );
	
	if (state == HallState::normal)
		SyncFrame(this, 1);
	else
		SyncFrame(this, 3);
		
	if(oldstate != state)
	{
		this.set_s32("regenerate time", getGameTime() + (REPAIR_HALL_TIME - REGENERATE_TICKET_TIME) );
	}
}

void SetMinimap( CBlob@ this )
{
	// minimap icon
	if (isUnderRaid(this))
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(16,16));
	}
	else
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_none);
		if (this.getTeamNum() >= 0 && this.getTeamNum() < 10)
			this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 2, Vec2f(16,8));
		else
			this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 3, Vec2f(16,8));
	}
	
	this.SetMinimapRenderAlways(true);
}

int getCaptureLimit( CBlob@ this )
{
	return CAPTURE_SECS * (float(getTicksASecond()) / float(this.getCurrentScript().tickFrequency)) * getTicksASecond();
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if(!caller.isOverlapping(this))
		return;
	
	if (this.getTeamNum() != 255)
	{
		CBitStream params;
		params.write_u16( caller.getNetworkID() );
		CButton@ button = caller.CreateGenericButton( "$change_class$", Vec2f(24.0f, 20.0f), this, this.getCommandID("class menu"), "Change class", params);
		
		Vec2f buttonpos = Vec2f(-24.0f, 20.0f);
		Vec2f buttonpos2 = Vec2f(24.0f, -5.0f);
		
		if( caller.getPlayer().getCoins() >= MIGRANT_COST )
		{
			//buy migrant button
			CButton@ button = caller.CreateGenericButton( "$migrant$", buttonpos, this, this.getCommandID(buymigrantcmd), "Buy a worker for "+MIGRANT_COST+" Coins" , params);
		}
		else
		{
			CButton@ button = caller.CreateGenericButton( "$migrant$", buttonpos, this, 0, "Buy worker: Requires "+MIGRANT_COST+" Coins" );
			if (button !is null) {
				button.SetEnabled( false );
			}
		}
		if( caller.getPlayer().getCoins() >= EXCHANGE_COST )
		{
			//buy migrant button
			CButton@ button = caller.CreateGenericButton( "$mat_gold$", buttonpos2, this, this.getCommandID(exchangecmd), "Exchange "+EXCHANGE_COST+" Coins for 10 gold" , params);
		}
		else
		{
			CButton@ button = caller.CreateGenericButton( "$mat_gold$", buttonpos2, this, 0, "Exchange for 10 gold: Requires "+EXCHANGE_COST+" Coins" );
			if (button !is null) {
				button.SetEnabled( false );
			}
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	/*
	CSprite@ sprite = this.getSprite();
	if (cmd == this.getCommandID("respawn"))
	{
		if(USE_TICKETS && getRules().isMatchRunning())
		{
			this.set_s32("respawned time", getGameTime() );

			u16 tickets = this.get_u16("tickets");
			if (tickets > 0)
			{
				tickets--;
				this.set_u16("tickets", tickets );
			}
			
			if (tickets == 0)
			{
				if (this.get_u8("hall state") != HallState::underwater)
				{							  
					ReturnState( this );
				}
			}
			//printf("RESPAWN IN HALL - " + tickets + " TICKETS LEFT");
		}
	}
	*/
	if (cmd == this.getCommandID(buymigrantcmd))
	{
		
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID( callerID );
		
		if(caller !is null)
		{
			if( caller.getPlayer().getCoins() >= MIGRANT_COST )
			{
				caller.getPlayer().server_setCoins( caller.getPlayer().getCoins() - MIGRANT_COST);
				this.set_u8("migrants max", this.get_u8("migrants max") + 1);
				
				CPlayer@ localPlayer = getLocalPlayer();
				if (localPlayer !is null && localPlayer.getTeamNum() == this.getTeamNum()) {
					Sound::Play("/party_join.ogg");
					client_AddToChat( "Another worker has been hired!" );
				}
			}
		}
	}
	else if (cmd == this.getCommandID(framecmd))
	{
		this.getSprite().animation.frame = params.read_u8();
	}
	else if (cmd == this.getCommandID(drowncmd))
	{
		this.set_u8("hall state", HallState::underwater);
		this.Untag("under raid");
		this.set_s32("capture time", 0 );
		this.getSprite().animation.frame = 2;
	}
	else if (cmd == this.getCommandID(exchangecmd))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID( callerID );
		
		if(caller !is null)
		{
			if( caller.getPlayer().getCoins() >= EXCHANGE_COST )
			{
				caller.getPlayer().server_setCoins( caller.getPlayer().getCoins() - EXCHANGE_COST);
				CBlob@ mat = server_CreateBlob("mat_gold");
				if(mat !is null){
					mat.Tag("do not set materials");
					mat.server_SetQuantity(10);
					if(!caller.server_PutInInventory(mat))
						mat.setPosition(caller.getPosition());
				}
			}
		}
	}
	else if (cmd == this.getCommandID("class menu"))
    {
        u16 callerID = params.read_u16();
        CBlob@ caller = getBlobByNetworkID( callerID );

        if (caller !is null && caller.isMyPlayer())     {
            BuildRespawnMenuFor( this, caller );
        }
    
	}
	else{
		onRespawnCommand(this, cmd, params);
	}
}

bool isInventoryAccessible( CBlob@ this, CBlob@ forBlob )
{
	return (this.getTeamNum() != 255 && //not neutral
			forBlob.getTeamNum() == this.getTeamNum() && //teammate
			forBlob.isOverlapping(this) && //inside
			!getRules().exists("singleplayer"));
}

void Capture( CBlob@ this, const int attackerTeam )
{
	if (getNet().isServer())
	{
		// convert all buildings and doors

		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius( this.getPosition(), BASE_RADIUS / 3.0f, @blobsInRadius ))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b.getTeamNum() != attackerTeam &&
					(b.getName() != "wartowertop" && b.getName() != "wartowerbottom") &&
					(b.hasTag("door") ||
					b.hasTag("building") ||
					b.getName() == "workbench" ||
					b.hasTag("migrant") ||
					b.getName() == "spikes" ||
					b.getName() == "trap_block"))
				{
					b.server_setTeamNum( attackerTeam );
				}
			}
		}
	}

	this.server_setTeamNum( attackerTeam );
}

void onChangeTeam( CBlob@ this, const int oldTeam )
{
	SetMinimap( this );
	
	if (this.getTeamNum() >= 0 && this.getTeamNum() < 10)
	{
		Sound::Play("/VehicleCapture");
		this.set_s32("capture time", 0 );

		// add Researching.as
			this.RemoveScript("Researching");


		RegenTickets( this );
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		const u8 state = this.get_u8("hall state");
		if (state == HallState::underwater) {
			sprite.animation.frame = 2;
		}
		else if (state == HallState::depleted) {
			sprite.animation.frame = 3;
		}
		else {
			sprite.animation.frame = 1;
		}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	return 0.0f;
}

bool isFirstHall( CBlob@ this, int team )
{
	CBlob@[] halls;
	getBlobsByName( "hall", @halls );
	for (uint i=0; i < halls.length; i++)
	{
		CBlob@ hall = halls[i];
		const u8 teamNumFactory = hall.getTeamNum();
		if (hall !is this && team == teamNumFactory)
		{
			return false;
		} 
	}
	return true;
}

void RegenTickets( CBlob@ this )
{
	u16 tickets = this.get_u16("tickets" );
	if (tickets < MAXIMUM_TICKETS)
	{
		tickets = Maths::Min( MAXIMUM_TICKETS, tickets + REGENERATE_TICKETS_AMOUNT );
		this.set_u16("tickets", tickets );
		this.Sync("tickets", true);
	}
	this.set_s32("regenerate time", getGameTime() + (REPAIR_HALL_TIME - REGENERATE_TICKET_TIME) );
}
		
// SPRITE

void onInit(CSprite@ this)
{
	int team = this.getBlob().getTeamNum();
	if(team >= 0 && team < 8) //"normal" team
		this.animation.frame = 1;
}


// alert and capture progress bar

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	if (isUnderRaid(blob))
	{
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos( blob.getPosition() + Vec2f(0.0f, -blob.getHeight()) );
		s32 captureLimit = getCaptureLimit(blob);
		if (getGameTime() % 20 > 4 && captureLimit > 0)
		{
			const s32 captureTime = blob.get_s32("capture time" );			
			GUI::DrawProgressBar( Vec2f(pos2d.x - 80.0f, pos2d.y + 45.0f), Vec2f(pos2d.x + 80.0f, pos2d.y + 60.0f), float(captureTime)/float(captureLimit) );
		}

		if (getGameTime() % 20 > 10)
		{
			GUI::DrawIconByName( "$ALERT$", Vec2f(pos2d.x-32.0f, pos2d.y-30.0f) );
		}
	}
	else
	{
		if(USE_TICKETS)
		{
			const u8 tickets = blob.get_u16("tickets");		
			s32 diffTime = (blob.get_s32("respawned time") + SHOW_TICKETS_TIME) - getGameTime();
			if (tickets == 0 || diffTime > 0)
			{
				Vec2f pos = getDriver().getScreenPosFromWorldPos( blob.getPosition() + Vec2f(0.0f, -blob.getHeight()/2.0f) );
				SColor color;

				if (tickets == 0) {
					color = SColor(255, 255, 55, 0);
				}
				else if (tickets < 6) {
					color = SColor(Maths::Min(255, diffTime*3), 255, 255, 55);
				}
				else {
					color = SColor(Maths::Min(255, diffTime*3), 255, 255, 255);
				}

				GUI::DrawText( "Units " + tickets,
					pos + Vec2f(-30,-4 + (tickets > 0 ? (-SHOW_TICKETS_TIME + diffTime)/5 : 0)),
					color );
			}
		}
	}
}
