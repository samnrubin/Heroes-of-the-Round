//not server only so the client also gets the game event setup stuff

#include "GameplayEvents.as"

const int coinsOnDamageAdd = 0;
const int coinsOnKillAdd = 50;

const int coinsOnDeathLosePercent = 40;
const int coinsOnTKLose = 50;

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 2;
const int coinsOnKillSiege = 10;


const int coinsOnBuild = 0;
const int coinsOnBuildWood = 0;

const int warmupFactor = 1;

string[] names;

void GiveRestartCoins(CPlayer@ p)
{
	if(keepCoinsOnRestart)
		p.server_setCoins( p.getCoins() + coinsOnRestartAdd);
	else
		p.server_setCoins( coinsOnRestartAdd);
}

void GiveRestartCoinsIfNeeded(CPlayer@ player)
{
	const string s = player.getUsername();
	for(uint i = 0; i < names.length; ++i)
	{
		if(names[i] == s)
		{
			return;
		}
	}
	
	names.push_back(s);
	GiveRestartCoins(player);
}

//extra coins on start to prevent stagnant round start
void onRestart(CRules@ this)
{
	if(!getNet().isServer())
		return;
	
	names.clear();
	
    uint count = getPlayerCount();
    for(uint p_step = 0; p_step < count; ++p_step)
    {
		CPlayer@ p = getPlayer(p_step);
		GiveRestartCoins( p );
		names.push_back(p.getUsername());
	}
}

//also given when plugging player -> on first spawn
void onSetPlayer( CRules@ this, CBlob@ blob, CPlayer@ player )
{
	if(!getNet().isServer())
		return;
		
	if(player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

//
// give coins for killing

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData )
{
	if(!getNet().isServer())
		return;
	
	if (victim !is null )
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				killer.server_setCoins( killer.getCoins() + coinsOnKillAdd );
			}
			else if(killer.getTeamNum() == victim.getTeamNum())
			{
				killer.server_setCoins( killer.getCoins() - coinsOnTKLose );
			}
		}

		s32 lost = victim.getCoins() * (coinsOnDeathLosePercent*0.01f);

		victim.server_setCoins( victim.getCoins() - lost );
		
		//drop coins
		CBlob@ blob = victim.getBlob();
		if(blob !is null)
			server_DropCoins( blob.getPosition(), XORRandom(lost) );
	}
}

// give coins for damage

f32 onPlayerTakeDamage( CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale )
{
	if(!getNet().isServer())
		return DamageScale;
	
	if (attacker !is null && attacker !is victim) {
		attacker.server_setCoins( attacker.getCoins() + DamageScale*coinsOnDamageAdd/this.attackdamage_modifier );
	}

	return DamageScale;
}

void onPlayerLeave( CRules@ this, CPlayer@ player )
{
	if(player is null) return;	
	int coins = player.getCoins();
	uint count = getPlayerCount();
    
	uint teamcount = 0;
	for(uint p_step = 0; p_step < count; ++p_step)
    {
		CPlayer@ p = getPlayer(p_step);
		if(p.getUsername() != player.getUsername() && p.getTeamNum() == player.getTeamNum()){
			teamcount++;
		}
	}

	if(teamcount == 0){
		return;
	}

	coins = coins / teamcount;

	for(uint p_step = 0; p_step < count; ++p_step)
    {
		CPlayer@ p = getPlayer(p_step);
		if(p.getUsername() != player.getUsername() && p.getTeamNum() == player.getTeamNum()){
			p.server_setCoins(p.getCoins() + coins);
		}
	}
	

}

// coins for various game events
void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	//only important on server
	if(!getNet().isServer())
		return;
	
	if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);
		
		CPlayer@ p = g.getPlayer();
		if(p !is null)
		{
			u32 coins = 0;
			
			switch (g.getType())
			{
			case GE_built_block:
			
				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if(tile == CMap::tile_castle)
					{
						coins = coinsOnBuild;
					}
					else if(tile == CMap::tile_wood)
					{
						coins = coinsOnBuildWood;
					}
				}
				
				break;
				
			case GE_built_blob:
			
				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();
					
					if(name.findFirst("door") != -1 ||
						name == "wooden_platform" ||
						name == "trap_block" || 
						name == "spikes" )
					{
						coins = coinsOnBuild;
					}
				}
				
				break;
				
			case GE_hit_vehicle:
				coins = coinsOnHitSiege;
				break;
			
			case GE_kill_vehicle:
				coins = coinsOnKillSiege;
				break;
				
			}
			
			if(coins > 0)
			{
				if(this.isWarmup())
					coins /= warmupFactor;
				
				p.server_setCoins( p.getCoins() + coins );
			}
		}
	}
}
