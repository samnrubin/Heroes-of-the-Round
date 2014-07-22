// Sergeant logic

#include "Hitters.as";
#include "Knocked.as";
#include "SapperCommon.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "MakeMat.as";
#include "Help.as";
#include "Requirements.as"
#include "SapperHittable.as";
#include "PlacementCommon.as";
#include "Heroes_MapFunctions.as";

void onInit( CBlob@ this )
{
    this.set_f32( "pickaxe_distance", 10.0f );
    //no spinning
    this.getShape().SetRotationsAllowed(false);
    this.set_f32("gib health", -3.0f);
    this.Tag("player");
    this.Tag("flesh");
    HitData hitdata;
    this.set("hitdata", hitdata );
	this.addCommandID("pickaxe");
    setKnockable( this );
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.SetScoreboardVars("ScoreboardIcons.png", 1, Vec2f(16,16));

	SetHelp( this, "help self action2", "builder", "$Pick$Dig/Chop  $KEY_HOLD$$RMB$", "", 3 );

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick( CBlob@ this )
{
    Knocked(this);

	if (this.isInInventory())
		return;

	const bool ismyplayer = this.isMyPlayer();

	if (ismyplayer && getHUD().hasMenus()) {
		return;
	}

    // activate/throw

    if ( ismyplayer )
    {
		Pickaxe( this );

        if (this.isKeyJustPressed(key_action3))
        {
			CBlob@ carried = this.getCarriedBlob();
			if (carried is null || !carried.hasTag("temp blob")) {
				client_SendThrowOrActivateCommand( this );
			}
        }
    }

	// slow down walking   

	if (this.isKeyPressed(key_action2))
	{
		RunnerMoveVars@ moveVars;
		if (this.get( "moveVars", @moveVars ))
		{
			moveVars.walkFactor = 0.5f;
			moveVars.jumpFactor = 0.5f;
		}
	}

	if (ismyplayer && this.isKeyPressed(key_action1))
	{
		BlockCursor @bc;
		this.get( "blockCursor", @bc );

		HitData@ hitdata;
		this.get("hitdata", @hitdata);
		hitdata.blobID = 0;
		hitdata.tilepos = bc.buildable ? bc.tileAimPos : Vec2f_zero;
	}


    // get rid of the built item

    if (this.isKeyJustPressed(key_inventory) || this.isKeyJustPressed(key_pickup))
    {
		this.set_u8( "buildblob", 255 );
		this.set_TileType( "buildtile", 0 );
        CBlob@ blob = this.getCarriedBlob();
		if (blob !is null && blob.hasTag("temp blob"))
        {
            blob.Untag("temp blob");
            blob.server_Die();
        }
    }

	if(this.isKeyJustPressed(key_taunts)){
		summonKnight(this);
	}
}

void summonKnight(CBlob@ this){
	ParticleZombieLightning(this.getPosition() - Vec2f(0, t(2)));
	
	if(getNet().isServer()){
		CBlob@ blob = server_CreateBlobNoInit( "knight" );
		blob.setSexNum(0);
		blob.setPosition(this.getPosition() - Vec2f(0, t(2)));
		blob.setHeadNum( this.getHeadNum() );
		blob.Init();						  
		blob.set_u8("personality", XORRandom(10));
		blob.set_f32("defaulthearts", 0.5);
		blob.getBrain().server_SetActive( true );
		blob.server_SetHealth( blob.getInitialHealth() * 0.5 );
		if(this.getTeamNum() == 0){
			blob.Tag("blue");
			blob.server_setTeamNum(0);
		}
		else{
			blob.Tag("red");
			blob.server_setTeamNum(1);
		}
	}
}

void SendHitCommand( CBlob@ this, CBlob@ blob, const Vec2f tilepos, const Vec2f attackVel, const f32 attack_power )
{
	CBitStream params;
	if (blob is null)
		params.write_netid( 0 );
	else
		params.write_netid( blob.getNetworkID() );
	params.write_Vec2f( tilepos );
	params.write_Vec2f( attackVel );
	params.write_f32( attack_power );
	this.SendCommand( this.getCommandID("pickaxe"), params );
}

bool RecdHitCommand( CBlob@ this, CBitStream@ params )
{
	u16 blobID;
	Vec2f tilepos, attackVel;
	f32 attack_power;
	if (!params.saferead_netid( blobID ))
		return false;
	if (!params.saferead_Vec2f( tilepos ))
		return false;
	if (!params.saferead_Vec2f( attackVel ))
		return false;
	if (!params.saferead_f32( attack_power ))
		return false;

	if (blobID == 0) {
		this.server_HitMap( tilepos, attackVel, attack_power, Hitters::builder );
	}
	else
	{
		CBlob@ blob = getBlobByNetworkID( blobID );
		if (blob !is null)
		{
			const bool teamHurt = (!blob.hasTag("flesh") || blob.hasTag("dead"));
			this.server_Hit( blob, tilepos, attackVel, attack_power, Hitters::builder, teamHurt);
		}
	}
	return true;
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("pickaxe"))
	{
		if (!RecdHitCommand( this, params ))
			warn("error when recieving pickaxe command");
	}
}

void Pickaxe( CBlob@ this )
{
    HitData@ hitdata;
    CSprite @sprite = this.getSprite();
    bool strikeAnim = sprite.isAnimation("strike");

    if (!strikeAnim)
    {
        this.get("hitdata", @hitdata);
        hitdata.blobID = 0;
        hitdata.tilepos = Vec2f_zero;
        return;
    }

    bool justCheck = !(strikeAnim && sprite.isFrameIndex(3));   // no damage cause we just check hit for cursor display

    // pickaxe!

    if (hitdata is null)
    {
        this.get("hitdata", @hitdata);
        hitdata.blobID = 0;
        hitdata.tilepos = Vec2f_zero;
    }
    
    f32 arcdegrees = 90.0f;

    Vec2f blobPos = this.getPosition();
    Vec2f aimPos = this.getAimPos();
    Vec2f aimDir = aimPos - blobPos;
    f32 aimangle = aimDir.Angle();
    Vec2f pos = blobPos - Vec2f(2,0).RotateBy(-aimangle);
    f32 attack_distance = this.getRadius() + this.get_f32( "pickaxe_distance" );
    f32 damage = 1.5f;
    f32 radius = this.getRadius();
    CMap@ map = this.getMap();
	bool dontHitMore = false;
	
    bool hasHit = false;
	
    // this gathers HitInfo objects which contain blob or tile hit information
    HitInfo@ bestinfo = null;
    f32 bestDistance = 100000.0f;
    
    HitInfo@[] hitInfos;

    if (map.getHitInfosFromArc( pos, -aimangle, arcdegrees, attack_distance, this, @hitInfos ))
    {
        //HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
		
			CBlob@ b = hi.blob;
			if (b !is null) // blob
			{			
				if ( !canHit(this, b) )	{
					continue;
				}
				
				if( !justCheck && isUrgent(this, b) )
				{
					hasHit = true;
					SendHitCommand( this, hi.blob, hi.hitpos, hi.blob.getPosition() - pos, damage );
				}
				else
				{				
					f32 len = (aimPos - b.getPosition()).Length();
					if ( len < bestDistance )
					{
						bestDistance = len;
						@bestinfo = hi;
					}
				}
			}
		}
    }
    
	
	Vec2f normal = aimDir;
    normal.Normalize();
    
    Vec2f attackVel = normal;

	const f32 tile_attack_distance = attack_distance * 1.5f;
    Vec2f tilepos = blobPos + normal * Maths::Min(aimDir.Length() - 1, tile_attack_distance);
    Vec2f surfacepos;
    map.rayCastSolid( blobPos, tilepos, surfacepos );
    
    bool noBuildZone = map.getSectorAtPosition( tilepos, "no build") !is null;
    
    Vec2f surfaceoff = (tilepos - surfacepos);
    f32 surfacedist = surfaceoff.Normalize();
    tilepos = (surfacepos + (surfaceoff * (map.tilesize*0.5f)));
    
    if( (tilepos - aimPos).Length() < bestDistance && map.getBlobAtPosition(tilepos) is null )
    {
		Tile tile = map.getTile( surfacepos );

		if (!noBuildZone && !map.isTileGroundBack( tile.type ) && (map.isTileBackgroundNonEmpty( tile ) || map.isTileSolid( tile ) ||
			(map.isTileGrass( tile.type ) && bestinfo is null ) ))
		{
			if (!justCheck) {
				SendHitCommand( this, null, tilepos, attackVel, 1.0f );
			}
			
			hasHit = true;
			hitdata.tilepos = tilepos;
		}
	}
    
    if (bestinfo !is null && !hasHit)
    {
		hitdata.blobID = bestinfo.blob.getNetworkID();
    
		if (!justCheck)
		{
			SendHitCommand( this, bestinfo.blob, bestinfo.hitpos, bestinfo.blob.getPosition() - pos, damage );
		}
	}
    
}

bool canHit( CBlob@ this, CBlob@ b )
{
	//normal check
	if ((b.getTeamNum() == this.getTeamNum() &&
		( (!b.hasTag("flesh") || !b.hasTag("dead")) && !b.isCollidable()) ) ||
		b.hasTag("invincible"))
	{
		//maybe we shouldn't hit this..
		//check if we should always hit
		return BuilderAlwaysHit(b);
	}
	//should be hit
	return true;
	
}

bool isUrgent( CBlob@ this, CBlob@ b )
{
	return (b.getTeamNum() != this.getTeamNum() || b.hasTag("dead")) && b.hasTag("player");
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint )
{
	// ignore collision for built blob
	BuildBlock[]@ blocks;
	this.get( "blocks", @blocks );	
	for (uint i = 0; i < blocks.length; i++)
	{
		BuildBlock@ b = blocks[i];
		if (b.name == detached.getName())
		{
			this.IgnoreCollisionWhileOverlapped( null );
			detached.IgnoreCollisionWhileOverlapped( null );
		}
	}

    // BUILD BLOB
    // take requirements from blob that is built and play sound
    // put out another one of the same
    if (detached.hasTag("temp blob"))	   // wont happen on client
    {
		if (!detached.hasTag("temp blob placed"))
		{
			detached.server_Die();
			return;
		}		

		uint i = this.get_u8( "buildblob" );
        if (blocks !is null && i >= 0 && i < blocks.length)
        {
            BuildBlock@ b = blocks[i];	
            if (b.name == detached.getName())
            {
                CInventory@ inv = this.getInventory();
                CBitStream missing;	  
				this.set_u8( "buildblob", 255 );
				this.set_TileType( "buildtile", 0 );
                if (hasRequirements( inv, b.reqs, missing ))
                {
                    server_TakeRequirements( inv, b.reqs );
                    this.getSprite().PlaySound( "/ConstructShort.ogg" );
                }
				// take out another one if in inventory
				server_BuildBlob( this, @blocks, i );

            }
        }
    }
    else // take out another seed
        if (detached.getName() == "seed")
        {
            CBlob@ anotherBlob = this.getInventory().getItem( detached.getName() );

            if (anotherBlob !is null)   {
                this.server_Pickup( anotherBlob );
            }
        }
}

void onAddToInventory( CBlob@ this, CBlob@ blob )
{
    // destroy built blob if somehow they got into inventory
    if (blob.hasTag("temp blob"))
    {
        blob.server_Die();
        blob.Untag("temp blob");
    }

	if (this.isMyPlayer() && blob.hasTag("material"))
	{		
		SetHelp( this, "help inventory", "builder", "$Help_Block1$$Swap$$Help_Block2$           $KEY_HOLD$$KEY_F$", "", 3 );		
	}
}
