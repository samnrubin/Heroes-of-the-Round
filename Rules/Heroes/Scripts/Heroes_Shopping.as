#include "TradingCommon.as";
#include "Descriptions.as"

#define SERVER_ONLY


//
void onBlobCreated( CRules@ this, CBlob@ blob )
{												
	if (blob.getName() == "trader")
	{
			MakeTradeMenu( blob );
	}
}							

TradeItem@ heroesAddTradeScroll(CBlob@ this, const string &in name, s32 cost, const string &in description, s32 unavailableTime)
{
	ScrollDef@ def = getScrollDef( "all scrolls", name );
	if (def !is null)
	{
		BuildItemsArrayIfNeeded( this );

		TradeItem item;
		item.scrollName = name;
		item.name = def.name;
		item.iconName = "$scroll"+def.scrollFrame+"$";
		item.configFilename = "scroll";
		item.iconFrame = def.scrollFrame;

		string techPrefix = def.name + "   ";
		for (uint i = 0; i < def.items.length; i++)
			techPrefix = techPrefix + "   " + def.items[i].iconName;
		techPrefix = techPrefix + "\n\n\n";

		item.description = techPrefix + description;
		item.instantShipping = true;
		item.isSeparator = false;
		//item.prepaidGold = true; // stack gold  ITS BUGGY

		item.unavailableTime = unavailableTime;

		AddRequirement( item.reqs, "coin", "", "Coins", cost );
		this.push("items", item);
		TradeItem@ p_ref;
		this.getLast( "items", @p_ref );
		return p_ref;
	}
	else
	{
		warn("missing scroll def by name: "+name);
		return null;
	}
}


TradeItem@ addItemForCoin( CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description )
{
	TradeItem@ item = addTradeItem( this, name, 0, instantShipping, iconName, configFilename, description );
	if (item !is null && cost > 0) 
	{
		AddRequirement( item.reqs, "coin", "", "Coins", cost );
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu( CBlob@ trader )
{
	//load config YEAH RIGHT IMMA JUST DO IT IN FILE

	s32 cost_bombs = 25;
	s32 cost_waterbombs = 30;
	s32 cost_keg = 150;
	s32 cost_mine = 75;

	s32 cost_arrows = 15;
	s32 cost_waterarrows = 40;
	s32 cost_firearrows = 60;
	s32 cost_bombarrows = 50;

	s32 cost_mountedbow = 100;
	s32 cost_drill = 250;
	s32 cost_boulder = 150;
	//s32 cost_burger = cfg.read_s32("cost_burger", 40);

	s32 cost_catapult = -1;//cfg.read_s32("cost_catapult", -1);
	s32 cost_ballista = -1;// cfg.read_s32("cost_ballista", -1);

	s32 menu_width = 4;//cfg.read_s32("trade_menu_width", 4);
	s32 menu_height = 4;//cfg.read_s32("trade_menu_height", 5);
	s32 cost_scroll_carnage = 180;
	s32 cost_scroll_hall = 25;
	s32 cost_scroll_home = 25;
	s32 cost_scroll_heal = 50;
	s32 cost_scroll_orb = 45;
	s32 cost_scroll_retinue = 125;

	// build menu
	
	addTradeEmptyItem( trader );
	if(trader.hasTag("magic")){
		CreateTradeMenu( trader, Vec2f(menu_width,menu_height), "\"Magikal items and scrolls, sirrah!\"" );
		addTradeSeparatorItem( trader, "$MENU_GENERIC$", Vec2f(3,1) );
		
		heroesAddTradeScroll( trader, "carnage", cost_scroll_carnage, "Use this to make all enemies in a 8 tile radius instantly turn into a pile of gibs.", 0 );	 
		
		heroesAddTradeScroll( trader, "telehall", cost_scroll_hall, "Teleport to your team's furthest owned hall in your current lane.", 0 );	 
		
		heroesAddTradeScroll( trader, "telehome", cost_scroll_home, "Teleport back to your team's portal in your current lane.", 0 );	 
		
		heroesAddTradeScroll( trader, "healteam", cost_scroll_heal, "Use this to heal all allies in a 5 tile radius.", 0 );	 
		
		heroesAddTradeScroll( trader, "orbsummon", cost_scroll_orb, "Use this to summon an orb which will seek out enemies, prioritizing other players.", 0 );

		heroesAddTradeScroll( trader, "retinueme", cost_scroll_retinue,  "Gain an enhanced version of the sapper's command powers for the next 30 seconds.", 0 );
	}
	else if(trader.hasTag("weapons")){
		CreateTradeMenu( trader, Vec2f(menu_width,menu_height), "\"Hurry up, I've got bison to kill\"" );
		addTradeSeparatorItem( trader, "$MENU_GENERIC$", Vec2f(3,1) );

		if(cost_bombs > 0)
			addItemForCoin( trader, "Bomb", cost_bombs, true, "$mat_bombs$", "mat_bombs", descriptions[1] );

		if(cost_waterbombs > 0)
			addItemForCoin( trader, "Water Bomb", cost_waterbombs, true, "$mat_waterbombs$", "mat_waterbombs", descriptions[50] );

		if(cost_arrows > 0)
			addItemForCoin( trader, "Arrows", cost_arrows, true, "$mat_arrows$", "mat_arrows", descriptions[2] );	 

		if(cost_waterarrows > 0)
			addItemForCoin( trader, "Water Arrows", cost_waterarrows, true, "$mat_waterarrows$", "mat_waterarrows", descriptions[50] );	 

		if(cost_firearrows > 0)
			addItemForCoin( trader, "Fire Arrows", cost_firearrows, true, "$mat_firearrows$", "mat_firearrows", descriptions[32] );	 

		if(cost_bombarrows > 0)
			addItemForCoin( trader, "Bomb Arrow", cost_bombarrows, true, "$mat_bombarrows$", "mat_bombarrows", descriptions[51] );
	}
	else if(trader.hasTag("armor")){
		CreateTradeMenu( trader, Vec2f(menu_width,menu_height), "\"My Armor is the toughest in the land, I swear on it\"" );
		addTradeSeparatorItem( trader, "$MENU_GENERIC$", Vec2f(3,1) );
		
	}
	else if(!trader.hasTag("wandering")){
		CreateTradeMenu( trader, Vec2f(menu_width,menu_height), "\"Give my regards if you see my husband on the road.\"" );

		//
		addTradeSeparatorItem( trader, "$MENU_GENERIC$", Vec2f(3,1) );


		if(cost_mine > 0)
			addItemForCoin( trader, "Mine", cost_mine, true, "$mine$", "mine", descriptions[20] );
		
		if(cost_keg > 0)
			addItemForCoin( trader, "Keg", cost_keg, true, "$keg$", "keg", descriptions[19] );

		if(cost_mountedbow > 0)
			addItemForCoin( trader, "Mounted Bow", cost_mountedbow, true, "$mounted_bow$", "mounted_bow", descriptions[31] );	 

		if(cost_drill > 0)
			addItemForCoin( trader, "Drill", cost_drill, true, "$drill$", "drill", descriptions[43] );	 

		if(cost_boulder > 0)
			addItemForCoin( trader, "Boulder", cost_boulder, true, "$boulder$", "boulder", descriptions[17] );	 

		/*if(cost_burger > 0)
			addItemForCoin( trader, "Burger", cost_burger, true, "$food$", "food", "Food for healing. Don't think about this too much." );*/	 	

		
		if(cost_catapult > 0)
			addItemForCoin( trader, "Catapult", cost_catapult, true, "$catapult$", "catapult", descriptions[5] );	 

		if(cost_ballista > 0)
			addItemForCoin( trader, "Ballista", cost_ballista, true, "$ballista$", "ballista", descriptions[6] );	 

	}
	else if(trader.hasTag("wandering")){

		CreateTradeMenu( trader, Vec2f(menu_width,menu_height), "I rest from my travels for you" );

		//
		addTradeSeparatorItem( trader, "$MENU_GENERIC$", Vec2f(3,1) );
		if(cost_bombs > 0)
			addItemForCoin( trader, "Bomb", cost_bombs, true, "$mat_bombs$", "mat_bombs", descriptions[1] );
		if(cost_arrows > 0)
			addItemForCoin( trader, "Arrows", cost_arrows, true, "$mat_arrows$", "mat_arrows", descriptions[2] );	 
		if(cost_bombarrows > 0)
			addItemForCoin( trader, "Bomb Arrow", cost_bombarrows, true, "$mat_bombarrows$", "mat_bombarrows", descriptions[51] );
		if(cost_keg > 0)
			addItemForCoin( trader, "Keg", cost_keg, true, "$keg$", "keg", descriptions[19] );
		heroesAddTradeScroll( trader, "telehall", cost_scroll_hall, "Teleport to your team's furthest owned hall in your current lane.", 0 );	 
		heroesAddTradeScroll( trader, "telehome", cost_scroll_home, "Teleport back to your team's portal in your current lane.", 0 );	 
	}
}

// load coins amount


