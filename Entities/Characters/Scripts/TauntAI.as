/** 
 * Common bot "taunt engine"
 * 
 * Attach to blob
 */


#include "EmotesCommon.as"

/**
 * Defines the possible taunt actions
 */
enum TauntActionIndex {
	
	no_action = 0,
	
	hurt_enemy,
	kill_enemy,
	get_hurt,
	
	chat,
	dead
}

/**
 * A struct holding information about a bot's personality
 */
class BotPersonality {
	
	/**
	 * name of the personality
	 */
	string name;
	
	/**
	 * chance of a taunt every event
	 */
	f32 tauntchance;
	
	/**
	 * the emote "strings" that the bot will use
	 * for certain events
	 */
	u8[] hurt_enemy_emotes;
	u8[] kill_enemy_emotes;
	u8[] get_hurt_emotes;
	
	/**
	 * A list of taunts that the bot will use
	 * when it's winning or camping
	 */
	string[] taunts;
	
	/**
	 * A list of whines that the bot will use
	 * when its dead
	 */
	string[] whines;
	
	/**
	 * The number of ticks taken per character of 
	 * taunt - used to emulate type lag
	 */
	u8 typespeed;
	
	/**
	 * Used to tune how talkative each personality is
	 */
	f32 talkchance;
	
	BotPersonality() {}
	
};

void onInit( CBlob@ this )
{
	//this.getCurrentScript().removeIfTag = "dead";
	
	this.set_u8("taunt action", no_action);
	this.set_u8("taunt delay", 0);
	
	/*BotPersonality[] personalities = {
		
	};*/
	
	//default personality
	BotPersonality b;
	b.name = "default";
	
	//emotes
	b.hurt_enemy_emotes.push_back(Emotes::smile);
	b.hurt_enemy_emotes.push_back(Emotes::mad);
	b.hurt_enemy_emotes.push_back(Emotes::laugh);
	
	b.kill_enemy_emotes.push_back(Emotes::laugh);
	
	b.get_hurt_emotes.push_back(Emotes::frown);
	b.get_hurt_emotes.push_back(Emotes::mad);
	b.get_hurt_emotes.push_back(Emotes::attn);
	b.get_hurt_emotes.push_back(Emotes::cry);
	
	//chats
	{ string[] temp = { "Looks like you're under SIEGE!",
						"fuck tha po-lice",
						"noob!",
						"top kek",
						"Daedric might!",
						"r u mad bro?",
						"I've finally reached a state of Zen",
						"Here comes my swing, you better DUCKS",
						"Once You Pop, You Can't Stop. Pringles TM",
						"15 minutes can save you 15% or more on car insurance!",
						"Fiendishly weak!",
						"Bringing the STORM!"
						
						};
	  b.taunts = temp; }
	{ string[] temp = { ":''''(",
						"D:",
						"If only I'd had the POWER",
						"dangit!",
						"Like *coughs* tears...in the rain",
						"...",
						"Time... to die...",
						"I wish the Black Death upon you",
						"I'll be back",
						"Kag Heroes was designed and coded by Nand!",
						"I've fallen and I can't get up",
						"Sang pls go.",
						"So much for my Young Blood" };
	  b.whines = temp; }
	
	//meta
	b.tauntchance = 0.10f;
	
	b.typespeed = 10;
	b.talkchance = 0.10f;
	
	this.set( "taunt personality", b );//personalities[(this.getNetworkID() % personalities.length)] );
}

void onTick( CBlob@ this )
{
	if(this.getPlayer() is null)
		UpdateAction(this);
	else
		this.getCurrentScript().runFlags |= Script::remove_after_this; //not needed
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if(hitterBlob.hasTag("human") && !this.hasTag("dead"))
		PromptAction(this, get_hurt, 5+XORRandom(5) );
	
	return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if(hitBlob.hasTag("human") && !hitBlob.hasTag("dead"))
		PromptAction(this, hurt_enemy, 5+XORRandom(5) );
}

void PromptAction(CBlob@ this, u8 action, u8 delay)
{
	this.set_u8("taunt action", action);
	this.Sync("taunt action", true);
	
	this.set_u8("taunt delay", delay);
	this.Sync("taunt delay", true);
}

void UpdateAction(CBlob@ this)
{
	bool isdead = this.hasTag("dead");
	
	u8 action = this.get_u8("taunt action");
	if(action == no_action)
	{
		if(isdead)
		{
			DoAction(this, dead);
		}
		
		return;
	}
	
	u8 delay = this.get_u8("taunt delay");
	if(delay > 0)
	{
		delay--;
		this.set_u8("taunt delay", delay);
	}
	else
	{
		this.set_u8("taunt action", no_action);
		DoAction(this, action);
		
		if(this.get_u8("taunt action") == no_action && isdead)
			this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

void DoAction(CBlob@ this, u8 action)
{
	BotPersonality@ b;
	if(!this.get( "taunt personality", @b )) return;
	
	bool taunt = (XORRandom(1000)/1000.0f) < b.tauntchance;
	bool chatter = (XORRandom(1000)/1000.0f) < b.talkchance;
	
	switch (action)
	{
	case hurt_enemy:
		if(taunt) ChatOrEmote(this, chatter, b.hurt_enemy_emotes, b.taunts, b);
		break;
	
	case kill_enemy:
		ChatOrEmote(this, chatter, b.kill_enemy_emotes, b.taunts, b);
		break;
		
	case get_hurt:
		if(taunt) ChatOrEmote(this, chatter, b.get_hurt_emotes, b.whines, b);
		break;
		
	case dead:
		ChatOrEmote(this, true, b.get_hurt_emotes, b.whines, b);
		break;
		
	case chat:
		this.Chat( this.get_string("taunt chat") );
		set_emote(this, Emotes::off);
		break;
	}
	
}

void ChatOrEmote(CBlob@ this, bool chatter, const u8[]& emotes, const string[]& chats, BotPersonality@ b = null)
{
	if(!chatter)
	{
		set_emote(this, emotes[XORRandom(emotes.length)]);
	}
	else
	{
		if(b is null)
		{
			this.Chat( chats[XORRandom(chats.length)] );
			set_emote(this, Emotes::off);
		}
		else
		{
			set_emote(this, Emotes::dots);
			
			string chat_text = chats[XORRandom(chats.length)];
			this.set_string( "taunt chat", chat_text );
			
			u8 count = (Maths::Sqrt(chat_text.length)+1) * b.typespeed;
			
			//print("text: \""+chat_text+"\" count: "+(count));
			
			PromptAction(this, chat, count);
			
		}
	}
}


