
#include "BuildBlock.as"
#include "Requirements.as"

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks( BuildBlock[]@ blocks )
{
	{   // stone_block
		BuildBlock b( CMap::tile_castle, "stone_block", "$stone_block$",
						"Stone Block\nBasic building block" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 25 );
		blocks.push_back( b );
	}
	{   // back_stone_block
		BuildBlock b( CMap::tile_castle_back, "back_stone_block", "$back_stone_block$",
						"Back Stone Wall\nExtra support" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 5 );
		blocks.push_back( b );
	}
	{   // stone_door
		BuildBlock b( 0, "stone_door", "$stone_door$",
						"Stone Door\nPlace next to walls" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 50 );
		blocks.push_back( b );
	}    

	{   // wood_block
		BuildBlock b( CMap::tile_wood, "wood_block", "$wood_block$",
						"Wood Block\nCheap block\nwatch out for fire!" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 5 );
		blocks.push_back( b );
	}
	{   // back_wood_block
		BuildBlock b( CMap::tile_wood_back, "back_wood_block", "$back_wood_block$",
						"Back Wood Wall\nCheap extra support" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 2 );
		blocks.push_back( b );
	}
	{   // wooden_door
		BuildBlock b( 0, "wooden_door", "$wooden_door$",
						"Wooden Door\nPlace next to walls" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 20 );
		blocks.push_back( b );
	}

	{   // ladder
		BuildBlock b( 0, "ladder", "$ladder$",
						"Ladder\nAnyone can climb it" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 10 );
		blocks.push_back( b );
	}
	{   // platform
		BuildBlock b( 0, "wooden_platform", "$wooden_platform$",
						"Wooden Platform\nOne way platform" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 50 );
		blocks.push_back( b );
	}
	
	{   // spikes
		BuildBlock b( 0, "spikes", "$spikes$",
						"Spikes\nPlace on Stone Block\nfor Retracting Trap" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 60 );
		blocks.push_back( b );
	}

	{   // spikes
		BuildBlock b( 0, "waypoint", "$waypoint$",
						"Waypoint\nGuide your knights" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 10 );
		blocks.push_back( b );
	}
}
