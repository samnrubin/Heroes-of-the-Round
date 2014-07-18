// Builder logic

#include "SapperCommon.as"
#include "PlacementCommon.as"
#include "Help.as"

#include "CommonSapperBlocks.as"

namespace Builder
{
enum Cmd
{
    nil = 0,
    make_workshop = 59,
    make_block = 60,
    make_reserved = 99
};
}

Vec2f MENU_SIZE( 3, 4 );
const u32 SHOW_NO_BUILD_TIME = 90;

void onInit( CInventory@ this )
{
	CBlob@ blob = this.getBlob();
	
	BuildBlock[] blocks;
	
	{
		BuildBlock[]@ temp;
		if( !blob.get( blocks_property, @temp ) )
		{
			addCommonBuilderBlocks( blocks );
			blob.set( blocks_property, blocks );
		}
	
	}
	
	if(!blob.exists(inventory_offset))
		blob.set_Vec2f(inventory_offset, Vec2f(0.0f, 174));
	
    blob.set_u8( "buildblob", 255 );
	blob.set_TileType( "buildtile", 0 );
	blob.set_u32( "cant build time", 0 );
	blob.set_u32( "show build time", 0 );
	this.getCurrentScript().removeIfTag = "dead";
	blob.set_u8("block cycle", 0 );
}

void MakeBlocksMenu( CInventory@ this, CGridMenu @invmenu )
{
    int buildtile = this.getBlob().get_TileType("buildtile");
    BuildBlock[]@ blocks;
    this.getBlob().get( blocks_property, @blocks );

    if (blocks !is null)
    {
        f32 fl = blocks.length;
        Vec2f pos( invmenu.getUpperLeftPosition().x + 0.5f*(invmenu.getLowerRightPosition().x - invmenu.getUpperLeftPosition().x),
                   invmenu.getUpperLeftPosition().y - 24 * MENU_SIZE.y - 50 );
        CGridMenu@ menu = CreateGridMenu( pos, this.getBlob(), MENU_SIZE, "Build" );

        if (menu !is null)
        {
			menu.deleteAfterClick = false;

            for (uint i = 0; i < blocks.length; i++)
            {
                BuildBlock@ b = blocks[i];
                CGridButton @button = menu.AddButton( b.icon, "\n"+b.description, Builder::make_block + i );

                if (button !is null)
                {
					button.selectOneOnClick = true;
                    CBitStream missing;

                    if (hasRequirements( this, b.reqs, missing )) {
                        button.hoverText = b.description + "\n" + getButtonRequirementsText( b.reqs, false );
                    }
                    else
                    {
                        button.hoverText = b.description + "\n" + getButtonRequirementsText( missing, true );
                        button.SetEnabled( false );
                    }

                    if (int(b.tile) == buildtile && b.tile != 0) {
                        button.SetSelected(1);
                    }

					CBlob @carryBlob = this.getBlob().getCarriedBlob(); 
					if (carryBlob !is null && carryBlob.getName() == b.name)
						button.SetSelected(1);
                }

				if (i == 11) { // gap before spikes 
					menu.AddEmptyButton();
				}
            }
        }
    }
}

void onCreateInventoryMenu( CInventory@ this, CBlob@ forBlob, CGridMenu @gridmenu )
{
    this.getBlob().ClearGridMenusExceptInventory();
    // blocks
    MakeBlocksMenu( this, gridmenu );
}

void onCommand( CInventory@ this, u8 cmd, CBitStream @params )
{
    string dbg = "BuilderInventory.as: Unknown command ";
    CBlob@ blob = this.getBlob();

    if (cmd >= Builder::make_block && cmd < Builder::make_reserved)
    {
        const bool isServer = getNet().isServer();
        BuildBlock[]@ blocks;
        blob.get( blocks_property, @blocks );
        uint i = cmd - Builder::make_block;

        if (blocks !is null && i >= 0 && i < blocks.length)
        {
            BuildBlock@ b = blocks[i];

			if (!canBuild( blob, @blocks, i )) {
				return;
			}

			// put carried in inventory thing first

            if (isServer)
            {
                CBlob @carryBlob = blob.getCarriedBlob();

                if (carryBlob !is null)
                {
                    // check if this isn't what we wanted to create
                    if (carryBlob.getName() == b.name) {
                        return;    // this is it
                    }

					// kill this 

					if (carryBlob.hasTag("temp blob"))
					{
						carryBlob.Untag("temp blob");
						carryBlob.server_Die();			
					}
					else // try put into inventory whatever was in hands
					{
						// creates infinite mats duplicating if used on build block, not great :/
						if (!b.buildOnGround && !blob.server_PutInInventory( carryBlob ))
						{
							carryBlob.server_DetachFromAll();
						}
					}
                }
            }

            if (b.tile == 0) // blob block
            {
				server_BuildBlob( blob, @blocks, i );	 
            }
            else // block
            {
                blob.set_TileType( "buildtile", b.tile );
            }

			blob.set_u8("block cycle", i );

			if (blob.isMyPlayer()) {
				SetHelp( blob, "help self action", "builder", "$Build$Build/Place  $LMB$", "", 3 );
			}
        }
    }
	//else if (cmd == blob.getCommandID("cycle"))  //from standardcontrols
	//{
	//	// cycle blocks
	//	u8 type = blob.get_u8( "block cycle" );
	//	int count = 0;
	//	BuildBlock[]@ blocks;
	//	blob.get( blocks_property, @blocks );
	//	while(count < blocks.length)
	//	{
	//		type++;
	//		count++;
	//		if (type >= blocks.length) {  
	//			type = 0;
	//		}
	//		BuildBlock@ b = blocks[type];
	//		if (!b.buildOnGround && canBuild( blob, @blocks, type )) 
	//		{
	//			if (blob.isMyPlayer())
	//			{
	//				Sound::Play("/CycleInventory.ogg");
	//				blob.SendCommand( Builder::make_block + type );	 
	//			}
	//			break;
	//		}
	//	}
	//}

// blob.set_u8("lastcmd", cmd );
}




// SPRITE
void onRender( CSprite@ this )
{
	CBlob@ blob = this.getBlob();			  
	CMap@ map = blob.getMap();	   
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is blob)						 
	{
		// no build zone show

		const bool onground = blob.isOnGround();
		const u32 time = blob.get_u32( "cant build time" );
		if (time + SHOW_NO_BUILD_TIME > getGameTime())
		{
			Vec2f space = blob.get_Vec2f( "building space" );
			Vec2f offsetPos = getBuildingOffsetPos(blob, map, space);

			const f32 scalex = getDriver().getResolutionScaleFactor();
			const f32 zoom = getCamera().targetDistance * scalex;
			Vec2f aligned = getDriver().getScreenPosFromWorldPos( offsetPos );

			for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = ( Vec2f( step_x + 0.5, step_y + 0.5 ) * map.tilesize );
					Vec2f v = offsetPos + temp;
					Vec2f pos = aligned + (temp - Vec2f(0.5f,0.5f)* map.tilesize) * 2*zoom;
					if (!onground || map.getSectorAtPosition( v , "no build") !is null ||
						map.isTileSolid(v))
					{
						GUI::DrawIcon( "CrateSlots.png", 5, Vec2f(8,8), pos, zoom );
					}
					else
					{
						GUI::DrawIcon( "CrateSlots.png", 9, Vec2f(8,8), pos, zoom );
					}
				}
			}
		}

		// show cant build

		if (blob.isKeyPressed(key_action1) || blob.get_u32( "show build time")+15 >getGameTime() )
		{
			if (blob.isKeyPressed(key_action1)) {
				blob.set_u32( "show build time", getGameTime() );
			}

			BlockCursor @bc;
			blob.get( "blockCursor", @bc );
			if (bc !is null) 
			{		
				if (bc.blockActive || bc.blobActive)
				{
					Vec2f pos = blob.getPosition();
					Vec2f myPos =  blob.getScreenPos() + Vec2f(0.0f,(pos.y > blob.getAimPos().y) ? -blob.getRadius() : blob.getRadius());
					Vec2f aimPos2D = getDriver().getScreenPosFromWorldPos( blob.getAimPos() );

					if (!bc.hasReqs)
					{
						 const string missingText = getButtonRequirementsText( bc.missing, true );
						 Vec2f boxpos( myPos.x, myPos.y - 120.0f );
						 GUI::DrawText( "Requires\n" + missingText, Vec2f(boxpos.x - 50, boxpos.y - 15.0f), Vec2f(boxpos.x + 50, boxpos.y + 15.0f), color_black, false, false, true );
					}
					else
					if (bc.cursorClose)
					{
						if (bc.rayBlocked)
						{  
							Vec2f blockedPos2D = getDriver().getScreenPosFromWorldPos(bc.rayBlockedPos);
							//GUI::DrawArrow2D( myPos, blockedPos2D, SColor(0xffdd2212) );
							GUI::DrawArrow2D( aimPos2D, blockedPos2D, SColor(0xffdd2212) );
						}

						if (!bc.buildableAtPos && !bc.sameTileOnBack)
						{
							CMap@ map = getMap();
							Vec2f middle = blob.getAimPos() + Vec2f(map.tilesize*0.5f, map.tilesize*0.5f);
							CMap::Sector@ sector = map.getSectorAtPosition( middle, "no build");   
							if (sector !is null)
							{ 
								GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(sector.upperleft), getDriver().getScreenPosFromWorldPos(sector.lowerright), SColor(0x65ed1202) );
							}
							else
							{		
								CBlob@[] blobsInRadius;	   
								if (map.getBlobsInRadius( middle, map.tilesize, @blobsInRadius )) 
								{
									for (uint i = 0; i < blobsInRadius.length; i++)
									{
										CBlob @b = blobsInRadius[i];
										if (!b.isAttached())
										{
										//b.RenderForHUD( RenderStyle::outline );
											Vec2f bpos = b.getPosition();
											GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(bpos + Vec2f(b.getWidth()/-2.0f, b.getHeight()/-2.0f)), 
																getDriver().getScreenPosFromWorldPos(bpos + Vec2f(b.getWidth()/2.0f, b.getHeight()/2.0f)),
																SColor(0x65ed1202) );
										}
									}
								}
							}
						}
					}
					else
					{
						const f32 maxDist = getMaxBuildDistance(blob) + 8.0f;
						Vec2f norm = aimPos2D - myPos;
						const f32 dist = norm.Normalize();
						norm *= (maxDist - dist);
						GUI::DrawArrow2D( aimPos2D, aimPos2D + norm, SColor(0xffdd2212) );
					}
				}
			}
		}
	}
}
