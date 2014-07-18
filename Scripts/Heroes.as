
//war gamemode logic script

#define SERVER_ONLY

#include "WAR_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";                 
#include "WAR_PopulateSpawnList.as"
#include "MakeCrate.as";                     
#include "ScrollCommon.as"; 
#include "WAR_HUDCommon.as";
#include "Descriptions.as";
#include "MigrantCommon.as";
#include "WAR_Population.as";
#include "Heroes_MapFunctions.as";

//simple config function - edit the variables in the config file
void Config(HeroesCore@ this)
{
    string configstr = sv_test ? "../Mods/KagMoba/Rules/Heroes/heroes_vars_test.cfg" : "../Mods/KagMoba/Rules/Heroes/heroes_vars.cfg";
    if (this.rules.exists("heroesconfig")) {
       configstr = this.rules.get_string("heroesconfig");
    }
    ConfigFile cfg = ConfigFile( configstr );

    //how long to wait for everyone to spawn in?
    s32 warmUpTimeSeconds = cfg.read_s32("warmup_time",30);
    this.warmUpTime = (getTicksASecond() * warmUpTimeSeconds);
    //how long for the game to play out?
    s32 gameDurationMinutes = cfg.read_s32("game_time",-1);
    if (gameDurationMinutes <= 0)
    {
        this.gameDuration = 0;
        this.rules.set_bool("no timer", true);
    }
    else
    {
        this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes);
    }
    //how many players have to be in for the game to start
    this.minimum_players_in_team = cfg.read_s32("minimum_players_in_team",2);
    //whether to scramble each game or not
    this.scramble_teams = cfg.read_bool("scramble_teams",true);


    //how far away counts as raiding?
    f32 raid_percent = cfg.read_f32("raid_percent", 30) / 100.0f;
    
    CMap@ map = getMap();
    if (map is null)
        this.raid_distance = raid_percent * 2048.0f; //presume 256 tile map
    else
        this.raid_distance = raid_percent * map.tilemapwidth * map.tilesize;

    //spawn after death time 
    this.defaultSpawnTime = this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 15));
}


// without "shared" we cannot hot-swap this class :(
// with "shared" we needt o use other function that are "shared" too

shared class HeroesSpawns : RespawnSystem
{
    HeroesCore@ heroes_core;

    WarPlayerInfo@[] spawns;

    bool force;
    s32 nextSpawn;

    void SetCore(RulesCore@ _core)
    {
        RespawnSystem::SetCore(_core);
        @heroes_core = cast<HeroesCore@>(core);

        nextSpawn = getGameTime();
    }

    void Update()
    {
        s32 time = getGameTime();
        if (time % 28 == 0 )
        {
            for (uint i = 0; i < spawns.length; i++)
            {
                updatePlayerSpawnTime(spawns[i]);
            }

            // calculate team sizes

            getRules().set_u8("team 0 count", getTeamSize(heroes_core.teams, 0));
            getRules().set_u8("team 1 count", getTeamSize(heroes_core.teams, 1));
        }

        if (time > nextSpawn)
        {
            for (uint i = 0; i < spawns.length; i++)
            {
                WarPlayerInfo@ info = spawns[i];
                if (info.wave_delay > 0)
                {
                    info.wave_delay--;
                }
            }
            int delta = -1;
            //we do erases in here, and unfortunately don't
            //have any other way to detect them than just looping until nothing more comes out.
            while(delta != 0)
            {
                uint len = spawns.length;
                for (uint i = 0; i < spawns.length; i++)
                {
                    WarPlayerInfo@ info = spawns[i];
                //  print("spawn for "+info.username+" , waves to go: "+info.wave_delay);

                    DoSpawnPlayer( info ); //check if we should spawn them
                }
                delta = spawns.length-len;
            }

            nextSpawn = getGameTime() + getTimeMultipliedByPlayerCount(heroes_core.spawnTime);
        }
    }
    
    void updatePlayerSpawnTime(WarPlayerInfo@ w_info)
    {
        WarTeamInfo@ team = cast<WarTeamInfo@>(core.getTeam(w_info.team));
        //sync player time to them directly
        string propname = "time to spawn "+w_info.username;
        const s32 time = w_info.wave_delay <= 2 ? getSpawnTime( team, w_info ) : -10000;   // no spawns?
        heroes_core.rules.set_s32( propname, time );
        heroes_core.rules.SyncToPlayer( propname, getPlayerByUsername(w_info.username) );
        propname = "needs respawn hud "+w_info.username;
        heroes_core.rules.set_bool( propname, (time < -1000 || time > s32(getGameTime())) );
        heroes_core.rules.SyncToPlayer( propname, getPlayerByUsername(w_info.username) );  
    }

    void DoSpawnPlayer( PlayerInfo@ p_info )
    {
        WarPlayerInfo@ w_info = cast<WarPlayerInfo@>(p_info);

        if (canSpawnPlayer(p_info))
        {
            CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?
            if (player is null) {
                return;
            }
            RemovePlayerFromSpawn(player);
                                      
            // force blue on tutorials
            if (getRules().exists("singleplayer")){
                p_info.team = 0;
            }

            CBlob@ spawnBlob;               
            CBlob@ playerBlob;
            {
                @spawnBlob = getSpawnBlobs( p_info ); 
                if(p_info.blob_name == "knight") // hack to force off basic classes
                	p_info.blob_name = sv_test ? "sapper" : "sapper";
                if (spawnBlob !is null)
                { 
                    if (spawnBlob.hasTag("migrant")) { // kill the migrant
                        spawnBlob.server_Die();                 
                    }
					// Hack to make sure the player doesnt spawn at a fucking hall
					// like they seem to do randomly
					Vec2f at = spawnBlob.getPosition();
					if(determineXZone(at) == 2){
						if(p_info.team == 0)
							at = Vec2f(4, 32);
						else
							at = Vec2f(365, 32);
					}
							
                    @playerBlob = SpawnPlayerIntoWorld( at, p_info );

                    if (playerBlob !is null && spawnBlob.hasTag("bed"))  // send "respawn" cmd
                    { 
                        CBitStream params;
                        params.write_netid( playerBlob.getNetworkID() ); 
                        spawnBlob.SendCommand( spawnBlob.getCommandID("respawn"), params );         
                    }
                }
                else
                if (!heroes_core.rules.isMatchRunning())
                {               
                    // create new builder at edge
                    if (p_info.team < heroes_core.teams.length)
                    {  
                        WarTeamInfo@ team = cast<WarTeamInfo@>(core.getTeam(p_info.team));
                        if (team.bedsCount > 0 || !team.under_raid) {
                            @playerBlob = SpawnPlayerIntoWorld( getSpawnLocation(p_info.team), p_info );
                        }
                    }
                }
            }

            if (playerBlob !is null)
            {
				playerBlob.Tag("human");
                //hud        
                string propname = "needs respawn hud "+p_info.username;
                heroes_core.rules.set_bool( propname, false );
                heroes_core.rules.SyncToPlayer( propname, getPlayerByUsername(p_info.username) );

                p_info.spawnsCount++;
            }
            else // search for spawn again
            {
                AddPlayerToSpawn( player );
            }   
                       
        }
    }

    bool canSpawnPlayer(PlayerInfo@ p_info)
    {
        if (force) { return true; }                     
        WarPlayerInfo@ w_info = cast<WarPlayerInfo@>(p_info);   
        return ( w_info.wave_delay == 0 );
    }

    s32 getSpawnTime( WarTeamInfo@ team, WarPlayerInfo@ w_info  )
    {
        return nextSpawn + ( (w_info.wave_delay-1) * getTimeMultipliedByPlayerCount(heroes_core.spawnTime) );
    }

    Vec2f getSpawnLocation(int team)
    {
        CMap@ map = getMap();
        f32 side = map.tilesize * 5.0f;
        f32 x = team == 0 ? side : (map.tilesize*map.tilemapwidth - side);
        f32 y = map.tilesize*map.tilemapheight;
        for (uint i = 0; i < map.tilemapheight; i++)
        {
            y -= map.tilesize;
            if ( !map.isTileSolid(map.getTile(Vec2f(x,y))) 
                && !map.isTileSolid(map.getTile(Vec2f(x-map.tilesize,y)))
                && !map.isTileSolid(map.getTile(Vec2f(x+map.tilesize,y)))
                && !map.isTileSolid(map.getTile(Vec2f(x,y-map.tilesize)))
                && !map.isTileSolid(map.getTile(Vec2f(x,y-2*map.tilesize)))
                && !map.isTileSolid(map.getTile(Vec2f(x,y-3*map.tilesize)))
                )
                break;
        }
        y -= 32.0f;
        return Vec2f(x,y);
    }

    s32 getTimeMultipliedByPlayerCount( s32 time )
    {
        // change spawn time according to player count
        if (heroes_core.players.length < 6) {
            time *= 0.33f;
        } else if (heroes_core.players.length < 9) {
            time *= 0.5f;
        } else if (heroes_core.players.length < 13) {
            time *= 0.75f;
        } else if (heroes_core.players.length > 16) {
            time *= 1.2f;
        } else if (heroes_core.players.length > 22) {
            time *= 1.5f;
        } else if (heroes_core.players.length > 27) {
            time *= 1.75f;
        }
        return time;
    }

    void RemovePlayerFromSpawn(CPlayer@ player)
    {
        WarPlayerInfo@ info = cast<WarPlayerInfo@>(core.getInfoFromPlayer(player));
        if (info is null) { warn("WAR LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(CPlayer@ player) )"); return; }

        int pos = spawns.find(info);
        if (pos != -1) {
            spawns.erase(pos);
        }
    }

    void AddPlayerToSpawn( CPlayer@ player )
    {
        RemovePlayerFromSpawn(player);
        if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
            return;
        
        WarPlayerInfo@ info = cast<WarPlayerInfo@>(core.getInfoFromPlayer(player));

        if (info is null) { warn("WAR LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

        //default to next wave spawn (not this wave spawn)
        info.wave_delay = 1;         

        if (nextSpawn-getGameTime() <= heroes_core.spawnTime/2)
            info.wave_delay += 1;   
        
        CBlob@ spawnBlob = getSpawnBlobs( info, true ); 
        if (spawnBlob !is null)
        { 
            if (spawnBlob.hasTag("under raid")) {
                info.wave_delay += 1;
            }
            if (isHallDepleted(spawnBlob))  {
                info.wave_delay += 1;
            }
        }

    //  print("Player " + player.getUsername() + " spawning in " + info.wave_delay + " waves.");

        info.spawnpoint = player.getSpawnPoint();
        spawns.push_back(info);
    }

    bool isSpawning( CPlayer@ player )
    {
        WarPlayerInfo@ info = cast<WarPlayerInfo@>(core.getInfoFromPlayer(player));
        int pos = spawns.find(info);
        return (pos != -1);
    }

     CBlob@ getSpawnBlobs( PlayerInfo@ p_info, bool takeUnderRaid = false )
     {
         CBlob@[] available;
         WarPlayerInfo@ w_info = cast<WarPlayerInfo@>(p_info);

        u16 spawnpoint = w_info.spawnpoint;

        // pick closest to death position
         if (spawnpoint > 0)
         {
             CBlob@ pickSpawn = getBlobByNetworkID( spawnpoint );
             if (pickSpawn !is null 
                 && (takeUnderRaid || !pickSpawn.hasTag("under raid"))
                 && pickSpawn.getTeamNum() == w_info.team
                 ) {
                return pickSpawn;
             }
             else  {
                 spawnpoint = 0; // can't pick this -> auto-pick
             }
         }

         // auto-pick closest
         if (spawnpoint == 0) 
         {               
             // get "respawn" bases
             PopulateSpawnList( @available, w_info.team, takeUnderRaid );

             while (available.size() > 0)
             {
                 f32 closestDist = 999999.9f;
                 uint closestIndex = 999;  
                 for (uint i = 0; i < available.length; i++)
                 {
                     CBlob @b = available[i];
                     Vec2f bpos = b.getPosition();
                     const f32 dist = (bpos - w_info.deathPosition).getLength();
                     if (dist < closestDist)
                     {
                         closestDist = dist;
                         closestIndex = i;
                     }
                 } 
                 if (closestIndex >= 999) {
                     break;
                 }    
                 return available[closestIndex];
             }                
         }

         return null;
     }

};

shared class HeroesCore : RulesCore
{
    string base_name = "war_base";

    s32 warmUpTime;
    s32 gameDuration;
    s32 spawnTime;
    s32 defaultSpawnTime;
    s32 minimum_players_in_team;
    bool scramble_teams;
    f32 alivePercent;
    s32 startingMigrants;
	int intervalSpawnerCount;
	bool startSpawn;
	int maintopblue;
	int maintopred;
	int mainbottomblue;
	int mainbottomred;
	u16 totalSpawned;
	
	//Testing variables
	int waveNum;


    f32 raid_distance;

    HeroesSpawns@ war_spawns;

    HeroesCore() {}

    HeroesCore(CRules@ _rules, RespawnSystem@ _respawns )
    {
        super(_rules, _respawns );
    }

    void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
    {
        RulesCore::Setup(_rules, _respawns);
        gametime = getGameTime();
        startTime = 0;
		startSpawn = false;
		waveNum = 0;
		totalSpawned = 0;
		maintopblue = 0;
		maintopred = 0;
		mainbottomblue = 0;
		mainbottomred = 0;
		intervalSpawnerCount = 1;
		bool spawnStarted = false;
        @war_spawns = cast<HeroesSpawns@>(_respawns);
        rules.SetCurrentState(WARMUP);
        server_CreateBlob( "Entities/Meta/WARMusic.cfg" );
    }

    int gametime;
    int startTime;

	//Respawns gold once mined HACKY AS SHIT
	void createGoldBlocks(){
		CMap@ map = getMap();
		Vec2f goldLoc = Vec2f(t(7), t(28));
		TileType tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(7), t(53));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(362), t(28));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(362), t(53));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(7), t(26));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(7), t(51));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(362), t(26));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
		goldLoc = Vec2f(t(362), t(51));
		tileT = map.getTile(goldLoc).type;
		if(!map.isTileGold(tileT)){
			map.server_SetTile(goldLoc, CMap::tile_gold);
		}
	}
    //NAND
	void UpdateMooks()	// run every second
	{
		CMap@ map = getMap(); 

		if (startSpawn == true && intervalSpawnerCount % 6 == 0) {
			IntervalSpawnMooks( map);
			waveNum++;
			if(sv_test){
				//print("\nWave: " + formatInt(waveNum, "",0 ));
			}
		}
		if(startSpawn == true){
			intervalSpawnerCount++;
		}
	}


	void IntervalSpawnMooks( CMap@ map)
	{
		bool spawnArchers = intervalSpawnerCount % 18 == 0;
        
		CBlob@[] quarters;
        getBlobsByName( "quarters", @quarters );

		/*CBlob@[] barracks;
        getBlobsByName( "barracks", @barracks );

        CBlob@[] archerbarracks;
        getBlobsByName( "archerbarracks", @archerbarracks );*/

		for (uint i=0; i < quarters.length; i++)
		{

			bool hasBarracks = false;
			bool hasArcherBarracks = false;

			CBlob@[] blobs;

			int knightSpawn = 3;
			int archerSpawn = 1;

			int waveSize = 0;
			
			getMap().getBlobsInRadius(quarters[i].getPosition(), t(20), blobs);


			Vec2f bpos;
			Vec2f apos;

			for(uint j = 0; j < blobs.length; j++){
				if(blobs[j].getName() == "barracks"){
					hasBarracks = true;
					waveSize += knightSpawn;
					bpos = blobs[j].getPosition();
				}
				else if(blobs[j].getName() == "archerbarracks" && spawnArchers){
					hasArcherBarracks = true;
					waveSize += archerSpawn;
					apos = blobs[j].getPosition();
				}
				
			}

			bool blue = !determineSide(quarters[i]);
			int zone = determineZone(quarters[i]);
			int difference = 45;

			if(blue){
				if(zone == 0){
					if(maintopblue + waveSize - maintopred > difference){
						waveSize = difference - (maintopblue - maintopred);
					}
				}
				else if(zone == 1){
					if(mainbottomblue + waveSize - mainbottomred > difference){
						waveSize = difference - (mainbottomblue - mainbottomred);
					}
				}
			}
			else{
				if(zone == 0){
					if(maintopred + waveSize - maintopblue > difference){
						waveSize = difference - (maintopred - maintopblue);
					}
				}
				else if(zone == 1){
					if(mainbottomred + waveSize - mainbottomblue > difference){
						waveSize = difference - (mainbottomred - mainbottomblue);
					}
				}

			}

			
			for(int j =1; j <= waveSize; j++) {
				Vec2f spawn;
				if(j <= knightSpawn){
					if(blue){
						spawn = Vec2f(bpos.x - t(j), bpos.y);
					}
					else{
						spawn = Vec2f(bpos.x + t(j), bpos.y);
					}
					SpawnMook( spawn, "knight", blue, zone);
				}
				else{
					if(blue){
						spawn = Vec2f(apos.x - t(j - 3), apos.y);
					}
					else{
						spawn = Vec2f(apos.x + t(j - 3), apos.y);
					}
					SpawnMook( spawn, "archer", blue, zone);
				}
			}
		}
		return;
	}


	CBlob@ SpawnMook( Vec2f pos, const string &in classname, bool blue, int zone  )
	{
		if((!sv_test || true) || !(!blue && zone == 0)){
		CBlob@ blob = server_CreateBlobNoInit( classname );
		if (blob !is null) {
			//setup ready for init
			blob.setSexNum( XORRandom(2) );
			blob.setPosition(pos + Vec2f(4.0f,0.0f));	
			blob.set_s32("difficulty", 15 );
			SetMookHead( blob, classname );			

			blob.Init();						  
			blob.server_setTeamNum(blue ? 0 : 1);
			blob.set_s32("defaultHealth", 100 );
			blob.set_s32("health", 100 );
			u8 r = XORRandom(10);
			blob.set_u8("personality", XORRandom(10));
			blob.getBrain().server_SetActive( true );
			blob.server_SetHealth( blob.getInitialHealth() * 0.75f );
			if(blue)
				blob.Tag("blue");
			else
				blob.Tag("red");
			GiveAmmo( blob );
		}
		return blob;
		}
		else
			return null;
	}

	void mookNumbers(){
        CBlob@[] knights;
        getBlobsByName( "knight", @knights );
		int topblue = 0;
		int topred = 0;
		int bottomblue = 0;
		int bottomred = 0;
		for(int i = 0; i < knights.length; i++){
			if(knights[i].getTeamNum() == 0 && !knights[i].hasTag("dead")){
				if(determineZone(knights[i]) == 0) 
					topblue++;
				else
					bottomblue++;
			}
			else if(!knights[i].hasTag("dead")){
				if(determineZone(knights[i]) == 0) 
					topred++;
				else
					bottomred++;
			}
		}

		maintopblue = topblue;
		maintopred = topred;
		mainbottomblue = bottomblue;
		mainbottomred = bottomred;

		/*if(sv_test){
			print("\nTOP\n");
			print("\nBlue: " + formatInt(topblue, "",0 ));
			print("\nRed: " + formatInt(topred, "",0 ));
			print("\nBOTTOM\n");
			print("\nBlue: " + formatInt(bottomblue, "",0 ));
			print("\nRed: " + formatInt(bottomred, "",0 ));
			print("\nTotal: " + formatInt(knights.length, "",0 ));
		}*/
	}

	void GiveAmmo( CBlob@ blob )
	{
		if (blob.getName() == "archer")
		{
			CBlob@ mat = server_CreateBlob( "mat_arrows" );
			CBlob@ mat2 = server_CreateBlob( "mat_arrows" );
			if (mat !is null && mat2 !is null) {
				blob.server_PutInInventory(mat);
				blob.server_PutInInventory(mat2);
			}
		}
	}

	void SetMookHead( CBlob@ blob, const string &in classname )
	{
		const bool isKnight = classname == "knight";

		int head = 15;
		int selection = XORRandom(16);
        if (isKnight)
        {
            switch (selection)
            {
            case 0:  head = 37; break;
            case 1:  head = 18; break;
            case 2:  head = 19; break;
            case 3:  head = 42; break;
            case 4:  head = 22; break;
            case 5:  head = 23; break;
            case 6:  head = 16; break;
            case 7:  head = 48; break;
            case 8:  head = 46; break;
            case 9:  head = 45; break;
            case 10: head = 47; break;
            case 11: head = 20; break;
            case 12: head = 21; break;
            case 13: head = 44; break;
            case 14: head = 43; break;
            case 15: head = 36; break;
            }
        }
        else
        {
            switch (selection)
            {
            case 0:  head = 35; break;
            case 1:  head = 51; break;
            case 2:  head = 52; break;
            case 3:  head = 26; break;
            case 4:  head = 22; break;
            case 5:  head = 27; break;
            case 6:  head = 24; break;
            case 7:  head = 49; break;
            case 8:  head = 17; break;
            case 9:  head = 17; break;
            case 10: head = 17; break;
            case 11: head = 33; break;
            case 12: head = 32; break;
            case 13: head = 34; break;
            case 14: head = 25; break;
            case 15: head = 36; break;
            }
        }

		head += 16; //reserved heads changed

		blob.setHeadNum( head );
	}

    void Update()
    {
        //HUD
        if (getGameTime() % 31 == 0)
        {
            updateHUD();
        }


        if (rules.isGameOver()) { return; }

        const u32 time = getGameTime();
        const bool havePlayers = allTeamsHavePlayers();

        int tick = 35;

        //NAND
        if (time % tick == 0) 
        {
            updateMigrants(time % (10*tick) == 0 );
            UpdatePlayerCounts();
            UpdatePopulationCounter();
			mookNumbers();
            UpdateMooks();
        }
        

        //CHECK IF TEAMS HAVE ENOUGH PLAYERS
        if ((rules.isIntermission() || rules.isWarmup()) && (!havePlayers) )
        {
            gametime = time + warmUpTime;
            rules.set_u32("game_end_time", time + gameDuration);
            rules.SetGlobalMessage( "Not enough players in each team for the game to start.\nPlease wait for someone to join..." );
            war_spawns.force = true;
        }
        else
        {
            if (time % tick == 0)
            {
                //needs to be updated before the teamwon
                //check if the team won
                CheckTeamWon(tick);
                if (rules.isMatchRunning()) {
                    rules.SetGlobalMessage( "" );
                }
				createGoldBlocks();
            }
        }
        if (havePlayers && time % tick == 0)
        {
            if (startTime == 0) {
                startTime = time;
            }
        }

        if (havePlayers && rules.isWarmup())
        {
            s32 ticksToStart = gametime - time;
            //setting the game state to running after warmup
            war_spawns.force = false;
            //printf("ticksToStart " + ticksToStart );
            //printf("gametime " + gametime );
            //printf("time " + time );
            if (ticksToStart <= 0)
            {
                rules.SetCurrentState(GAME);
                printf("WAR STARTED");                  
				startSpawn = true;
				CMap@ map = getMap();
				IntervalSpawnMooks( map);
            }
            else if (ticksToStart > 0) //is the start of the game, spawn everyone + give mats
            {
                rules.SetGlobalMessage( "\nMatch starts in "+((ticksToStart/30)+1) );
                war_spawns.force = true;
            }
        }

        RulesCore::Update(); //update respawns
    }
    
    void updateHUD()
    {
        CBitStream serialised_team_hud;
        serialised_team_hud.write_u16(0x54f3);

        WAR_HUD hud;

        WarTeamInfo@[] temp_teams;
        for (uint team_num = 0; team_num < teams.length; ++team_num )
        {
            WarTeamInfo@ team = cast<WarTeamInfo@>(teams[team_num]);

            if (team !is null) {
                temp_teams.push_back(team);
            }
        }
        
        CBlob@[] halls;
        getBlobsByName( "hall", @halls );
        
        hud.Generate(temp_teams, halls);
        
        hud.Serialise(serialised_team_hud);

        rules.set_CBitStream("WAR_serialised_team_hud",serialised_team_hud);
        rules.Sync("WAR_serialised_team_hud",true);
    }

    //HELPERS

    bool allTeamsHavePlayers()
    {
        for (uint i = 0; i < teams.length; i++)
        {
            if (teams[i].players_count < minimum_players_in_team)
            {
                return false;
            }
        }
        return true;
    }

    //team stuff

    void AddTeam(CTeam@ team)
    {
        WarTeamInfo t(teams.length, team.getName());
        teams.push_back(t);
    }

    void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
    {
        WarPlayerInfo p(player.getUsername(), player.getTeamNum(), "knight");
        players.push_back(p);
        ChangeTeamPlayerCount( p.team, 1);
    }

    void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
    {
        if (victim !is null )
        {
            CBlob@ blob = victim.getBlob();
            if (blob !is null)
            {
                f32 deathDistanceToBase = Maths::Abs( war_spawns.getSpawnLocation( blob.getTeamNum() ).x - blob.getPosition().x );
                NotifyDeathPosition( victim, blob.getPosition(), deathDistanceToBase );
            }
        }
    }

    void UpdatePlayerCounts()
    {              
        for (uint i = 0; i < teams.length; i++)
        {
            WarTeamInfo@ team = cast<WarTeamInfo@>( teams[i] );
            //"reset" with migrant count
            team.alive_count = team.migrantCount;
            team.under_raid = false;
        }

        for (uint step = 0; step < players.length; ++step)
        {
            CPlayer@ p = getPlayerByUsername(players[step].username);
            if (p is null) continue;
            CBlob@ player = p.getBlob();
            if (player is null) continue;
            //whew, actually got a blob now..
            if (!player.hasTag("dead"))
            {
                uint teamNum = uint(player.getTeamNum());
                if (teamNum >= 0 && teamNum < teams.length) {
                    teams[teamNum].alive_count++;
                }
            }
        }
        
        CBlob@[] rooms;     
        getBlobsByName( "hall", @rooms );   
        for (uint i = 0; i < teams.length; i++)
        {
            WarTeamInfo@ team = cast<WarTeamInfo@>( teams[i] );

            for (uint roomStep=0; roomStep < rooms.length; roomStep++)
            {
                CBlob@ room = rooms[roomStep];
                const u8 teamNum = room.getTeamNum();
                if (teamNum == i)
                {
                    if (room.hasTag("under raid")) {
                        team.under_raid = true;
                    }
                }
            }   
        }
    }

    //checks
    void CheckTeamWon( int tickFrequency )
    {
        // calc alive players before this function with UpdatePlayerCounts!
        
        // can't lose if the match isn't running
	//TODO: Win Condition
        if (!rules.isMatchRunning()) { return; }

        int bluePortals = 0;
        int redPortals = 0;

        CBlob@[] portals;
        getBlobsByName( "portal", @portals );

        for (uint i = 0; i < portals.length; i++)
        {
			portals[i].getTeamNum() == 0 ? bluePortals++ : redPortals++;
        }
        if ( bluePortals == 0 && redPortals == 0 )
        {
           return; // tie condition - no portals
        }
        else if ( bluePortals == 0 || redPortals == 0 )
        {
			if(bluePortals > 0){
            	rules.SetTeamWon( 0 );
                rules.SetCurrentState(GAME_OVER);
                rules.SetGlobalMessage( "Blue wins the game!" );
			}
			else{
            	rules.SetTeamWon( 1 );
                rules.SetCurrentState(GAME_OVER);
                rules.SetGlobalMessage( "Red wins the game!" );
			}
        }
    }


    void NotifyDeathPosition( CPlayer@ player, Vec2f deathPosition, const f32 distance )
    {
        WarPlayerInfo@ info = cast<WarPlayerInfo@>(getInfoFromPlayer(player));
        if (info is null) { return; }
        info.deathDistanceToBase = distance;
        info.deathPosition = deathPosition;
    }
                     
    void updateMigrants(bool spawn)
    {
        for (uint i = 0; i < teams.length; i++)
        {   
            WarTeamInfo@ team = cast<WarTeamInfo@>(teams[i]);
            team.migrantsInDormCount = getMigrantsInDormCount( i );
            team.migrantCount = getMigrantsCount( i );
            team.bedsCount = getBedsCount( i );
        }
    }

    CBlob@ SpawnMigrant( const int teamNum )
    {
        Vec2f pos = war_spawns.getSpawnLocation( teamNum );
        return CreateMigant( pos, teamNum );
    }

    int getBedsCount( const int teamNum )
    {
        int count = 0;
        CBlob@[] rooms;
        getBlobsByTag( "migrant room", @rooms );   
        for (uint i=0; i < rooms.length; i++)
        {
            CBlob@ room = rooms[i];
            if (room.getTeamNum() == teamNum) 
            {
                count += room.get_u8("migrants max");
            }
        }       
        return count;
    }

    int getMigrantsCount( const int teamNum )
    {
        int count = 0;
        CBlob@[] migrants;
        getBlobsByTag( "migrant", @migrants );   
        for (uint i=0; i < migrants.length; i++)
        {
            CBlob@ migrant = migrants[i];
            if (migrant.getTeamNum() == teamNum && !migrant.hasTag("dead")) {
                count++;
            }
        }

        return count;
    }

    int getMigrantsInDormCount( const int teamNum )
    {
        int count = 0;

        // rooms with migrants

        CBlob@[] rooms;
        getBlobsByTag( "migrant room", @rooms );   
        for (uint i=0; i < rooms.length; i++)
        {
            CBlob@ room = rooms[i];
            if (room.getTeamNum() == teamNum) {
                count += room.get_u8("migrants count");
            }
        }

        return count;
    }

    //////////////////////////////////////////////////////////////////////////
    
    void UpdatePopulationCounter()
    {              
        for (uint teamNum = 0; teamNum < teams.length; teamNum++)
        {
            WarTeamInfo@ team = cast<WarTeamInfo@>( teams[ teamNum ] );
            setPopulation( teamNum, team.migrantCount + team.migrantsInDormCount );
        }
    }
};

//pass stuff to the core from each of the hooks

void onRestart( CRules@ this )
{
    printf("Restarting rules script: " + getCurrentScriptName() );
    HeroesSpawns spawns();
    HeroesCore core(this, spawns);
    Config(core);
    this.set("core", @core);

    core.gametime = getGameTime() + core.warmUpTime;

    this.set("start_gametime", core.gametime);//is this legacy?
    
    this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as

    // place no build zones at sides
    CMap@ map = getMap();
    f32 space = map.tilesize * 5.0f;
    map.server_AddSector( Vec2f(0.0f,0.0f), Vec2f(space, map.tilemapheight*map.tilesize), "no build" );
    map.server_AddSector( Vec2f(map.tilemapwidth*map.tilesize-space,0.0f), Vec2f(map.tilemapwidth*map.tilesize, map.tilemapheight*map.tilesize), "no build" );    

    //

    for (uint i = 0; i < core.teams.length; i++)
    {
        setPopulation( i, 0 );
    }
}

void CheckWin( CRules@ this, CBlob@ blob, const int oldTeam )
{
    // check if any halls remain
    int teamHalls = 0;
    CBlob@[] rooms;     
    getBlobsByName( "hall", @rooms );
    for (uint roomStep=0; roomStep < rooms.length; roomStep++)
    {
        CBlob@ room = rooms[roomStep];
        const u8 teamNum = room.getTeamNum();
        if (teamNum == oldTeam) {
            teamHalls++;
        }
    }   

    RulesCore@ core;
    this.get("core", @core);     
    if (core !is null && oldTeam < 2) 
    {
        HeroesCore@ heroes_core = cast<HeroesCore@>(core);
        heroes_core.teams[oldTeam].lost = teamHalls == 0;
    }
}

void onBlobChangeTeam( CRules@ this, CBlob@ blob, const int oldTeam )
{
    if (blob.getName() == "hall" && oldTeam < 2)
    {
        CheckWin( this, blob, oldTeam );
    }
}

void onBlobDie( CRules@ this, CBlob@ blob )
{
    if (blob.getName() == "hall")
    {
        CheckWin( this, blob, blob.getTeamNum() );
    }
}

// TRADING

/*void onBlobCreated( CRules@ this, CBlob@ blob )
{
    if (blob.getName() == "trader")
    {
        MakeWarTradeMenu( blob );
    }
}

TradeItem@ addGoldForItem( CBlob@ this, const string &in name,
                            int cost, const string &in cost_mat, const string &in cost_mat_description, 
                            const bool instantShipping,
                            const string &in iconName,
                            const string &in configFilename,
                            const string &in description )
{
    TradeItem@ item = addTradeItem( this, name, 0, instantShipping, iconName, configFilename, description );
    if (item !is null && cost > 0) 
    {
        AddRequirement( item.reqs, "blob", cost_mat, cost_mat_description, cost );
        item.buyIntoInventory = true;
    }
    return item;
}

void MakeWarTradeMenu( CBlob@ trader )
{       
    // build menu
    CreateTradeMenu( trader, Vec2f(3,11), "Trade" );

    //econ techs
//  addTradeSeparatorItem( trader, "$MENU_INDUSTRY$", Vec2f(3,1) );
//  addTradeScrollFromScrollDef(trader, "saw", cost_crappiest, descriptions[12]);   
    //addTradeEmptyItem(trader);

    //siege techs
    addTradeSeparatorItem( trader, "$MENU_SIEGE$", Vec2f(3,1) );
    addTradeScrollFromScrollDef(trader, "mounted bow", cost_medium, descriptions[31]);
    addTradeScrollFromScrollDef(trader, "ballista", cost_medium, descriptions[6]);
    addTradeScrollFromScrollDef(trader, "catapult", cost_big, descriptions[5]);

    //boats
    addTradeSeparatorItem( trader, "$MENU_NAVAL$", Vec2f(3,1) );    
    addTradeScrollFromScrollDef(trader, "longboat", cost_medium, descriptions[33]);
    addTradeScrollFromScrollDef(trader, "warboat", cost_big, descriptions[37]);
    addTradeEmptyItem(trader);

    //item kits
    addTradeSeparatorItem( trader, "$MENU_KITS$", Vec2f(3,1) ); 
    //addTradeScrollFromScrollDef(trader, "military basics", cost_crappy, descriptions[44]); 
    addTradeScrollFromScrollDef(trader, "water ammo", cost_crappy, descriptions[50]);       
    addTradeScrollFromScrollDef(trader, "bomb ammo", cost_big, descriptions[51]);
    addTradeScrollFromScrollDef(trader, "pyro", cost_big, descriptions[46]);
    addTradeScrollFromScrollDef(trader, "drill", cost_crappiest, descriptions[43]); 
    addTradeScrollFromScrollDef(trader, "saw", cost_crappiest, descriptions[12]); 
    addTradeScrollFromScrollDef(trader, "explosives", cost_big, descriptions[45]);  

    //exchange
    addTradeSeparatorItem( trader, "$MENU_OTHER$", Vec2f(3,1) );    
    addTradeScrollFromScrollDef(trader, "carnage", 400, "This magic scroll when cast will turn all nearby enemies into a pile of bloody gibs.");        
    addTradeScrollFromScrollDef(trader, "drought", 120, "This magic scroll will evaporate all water in a large surrounding orb.");      
    addTradeEmptyItem( trader );
    
    //exchange
    addTradeSeparatorItem( trader, "$MENU_OTHER$", Vec2f(3,1) );    
    
    f32 wood_sell_price = 5.0f;
    f32 wood_buy_price = 4.0f;
    
    f32 stone_sell_price = 2.5f;
    f32 stone_buy_price = 2.0f;
    
    s32 wood_stack_price = s32(500/wood_sell_price);
    s32 gold_wood_price = s32(500*wood_buy_price);
    
    s32 stone_stack_price = s32(500.0f/stone_sell_price);
    s32 gold_stone_price = s32(500.0f*stone_buy_price);
    
    addTradeItem( trader, "Wood", wood_stack_price, true,                       "$mat_wood$", "mat_wood", "Exchange "+wood_stack_price+" Gold for 500 Wood" );
    addTradeItem( trader, "Stone", stone_stack_price, true,                     "$mat_stone$", "mat_stone", "Exchange "+stone_stack_price+" Gold for 500 Stone" );
    //addTradeEmptyItem( trader );
    //addGoldForItem( trader, "Gold", gold_wood_price, "mat_wood", "Wood", true,    "$mat_gold$", "mat_gold", "Exchange "+gold_wood_price+" Wood for 250 Gold" );
    //addGoldForItem( trader, "Gold", gold_stone_price, "mat_stone", "Stone", true, "$mat_gold$", "mat_gold", "Exchange "+gold_stone_price+" Stone for 250 Gold" );

    //individual items
    //addTradeSeparatorItem( trader, "$MENU_OTHER$", Vec2f(3,1) );  
    //addTradeScrollFromScrollDef(trader, "boulder", cost_crappy, descriptions[17]);
    //addTradeEmptyItem(trader);
    //addTradeEmptyItem(trader);

    //individual items
    //addTradeSeparatorItem( trader, "$MENU_TECHS$", Vec2f(3,1) );  
    //addTradeScrollFromScrollDef(trader, "stone", cost_crappy, descriptions[47]);
}*/
