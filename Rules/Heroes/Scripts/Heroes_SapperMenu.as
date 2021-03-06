
#include "BuildBlock.as"
#include "CommonSapperBlocks.as"

#include "WARCosts.as"

void onSetPlayer( CRules@ this, CBlob@ blob, CPlayer@ player )
{
	if (blob !is null && player !is null && blob.getName() == "sapper") 
	{
		BuildBlock[] blocks;
		
		addCommonBuilderBlocks( blocks );

		{   // building
			BuildBlock b( 0, "factory", "$building$", "Workshop" );
			AddRequirement( b.reqs, "blob", "mat_wood", "Wood", COST_WOOD_WORKSHOP );
			b.buildOnGround = true;
			b.size.Set( 40,24 );
			blocks.insert( blocks.size()-1, b ); //insert so that it's offset on the spikes :)
		}
		

		{   // workbench
			BuildBlock b( 0, "workbench", "$workbench$", "Workbench" );
			AddRequirement( b.reqs, "blob", "mat_wood", "Wood", 120 );
			b.buildOnGround = true;
			b.size.Set( 32,16 );
			blocks.push_back( b );
		}

		blob.set( blocks_property, blocks );
	}
}
