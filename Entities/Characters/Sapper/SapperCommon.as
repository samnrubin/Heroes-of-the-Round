#include "BuildBlock.as"
#include "PlacementCommon.as"
#include "CheckSpam.as"

#include "GameplayEvents.as"

shared class HitData
{
    u16 blobID;
    Vec2f tilepos;
};

Vec2f getBuildingOffsetPos(CBlob@ blob, CMap@ map, Vec2f required_tile_space)
{
	Vec2f halfSize = required_tile_space * 0.5f;	

	Vec2f pos = blob.getPosition();
	pos.x = int(pos.x / map.tilesize);
	pos.x *= map.tilesize;
	pos.x += map.tilesize * 0.5f;

	pos.y -= required_tile_space.y * map.tilesize * 0.5f - map.tilesize; 
	pos.y = int(pos.y / map.tilesize);
	pos.y *= map.tilesize;
	pos.y += map.tilesize * 0.5f;

	Vec2f offsetPos = pos - Vec2f(halfSize.x , halfSize.y) * map.tilesize;
	Vec2f alignedWorldPos = map.getAlignedWorldPos(offsetPos );
	return alignedWorldPos;
}

CBlob@ server_BuildBlob( CBlob@ this, BuildBlock[]@ blocks, uint index )
{
    if (index >= blocks.length) {
        return null;
    }

	this.set_u32( "cant build time", 0 );

	CInventory@ inv = this.getInventory();
    BuildBlock@ b = blocks[index];
    this.set_TileType( "buildtile", 0 );
    CBlob@ anotherBlob = inv.getItem( b.name );

    if (getNet().isServer() && anotherBlob !is null)   {
        this.server_Pickup( anotherBlob );
        this.set_u8( "buildblob", 255 );
        return null;
    }

	if (canBuild( this, blocks, index ) ) 
	{
		Vec2f pos = this.getPosition();

		if (b.buildOnGround)
		{
			const bool onground = this.isOnGround();

			bool fail = !onground;

			CMap@ map = getMap();

			Vec2f space = Vec2f(b.size.x/8, b.size.y/8);
			Vec2f offsetPos = getBuildingOffsetPos(this, map, space);

			if(!fail)
			{
				for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
				{
					for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
					{
						Vec2f temp = ( Vec2f( step_x + 0.5, step_y + 0.5 ) * map.tilesize );
						Vec2f v = offsetPos + temp;
						if (map.getSectorAtPosition( v , "no build") !is null ||
							map.isTileSolid(v))
						{
							fail = true;
							break;
						}
					}
				}
			}

			if(fail)
			{
				if (this.isMyPlayer()) {
					Sound::Play("/NoAmmo" );
				}
				this.set_Vec2f( "building space", space );
				this.set_u32( "cant build time", getGameTime() );
				return null;
			}

			pos = offsetPos + space * map.tilesize * 0.5f;

			// check spam
			//if (isSpammed( b.name, this.getPosition(), 3 ))
			//{
			// if (this.isMyPlayer())
			// {
			// client_AddToChat( "There is too many " + b.name + "'s here sorry." );
			// this.getSprite().PlaySound("/NoAmmo" );
			// }
			// return null;
			//}

			this.getSprite().PlaySound("/Construct" );
			// take inv here instead of in onDetach
			server_TakeRequirements( inv, b.reqs );

			SendGameplayEvent(createBuiltBlobEvent( this.getPlayer(), b.name ));
		}

		if (getNet().isServer())
		{
			CBlob@ blockBlob = server_CreateBlob( b.name, this.getTeamNum(), pos );  
			if (blockBlob !is null)
			{
				this.server_Pickup( blockBlob );
				this.set_u8( "buildblob", index );

				if (b.temporaryBlob) {
					blockBlob.Tag("temp blob");
				}

				return blockBlob;
			}
		}
    }

    return null;
}

bool canBuild( CBlob@ this, BuildBlock[]@ blocks, uint index )
{
	if (index >= blocks.length) {
		return false;
	}

	CInventory@ inv = this.getInventory();
	BuildBlock@ b = blocks[index];
	BlockCursor @bc;
	this.get( "blockCursor", @bc );			
	if (bc is null) {
		return false;
	}
	bc.missing.Clear();
	bc.hasReqs = hasRequirements( inv, b.reqs,bc. missing );
	return bc.hasReqs;
}
