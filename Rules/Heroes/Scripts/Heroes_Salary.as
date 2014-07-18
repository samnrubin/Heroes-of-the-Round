#include "HallCommon.as"
#include "Heroes_MapFunctions.as"
#include "TeamColour.as"

// Heroes Salary
// Author: Nand
// Please ask if you'd like to use this file.

const uint SALARY_PERIOD = 30 * getTicksASecond();


void onInit(CRules@ this){
	if(!this.exists("lastPaid"))
		this.set_u32("lastPaid", getGameTime());
	if(!this.exists("blueincome"))
		this.set_u16("blueincome", 10);
	if(!this.exists("redincome"))
		this.set_u16("redincome", 10);
	if(!this.exists("halltopleftmigrants"))
		this.set_u16("halltoplefmigrants",0);
	if(!this.exists("halltoprightmigrants"))
		this.set_u16("halltopright", 0);
	if(!this.exists("hallbottomleftmigrants"))
		this.set_u16("hallbottomlefmigrants", 0);
	if(!this.exists("hallbottomrightmigrants"))
		this.set_u16("hallbottomright", 0);

	/*if(getNet().isServer()){
		this.Sync("lastPaid", true);
		this.Sync("blueIncome", true);
		this.Sync("redIncome", true);
		this.Sync("halltopleftmigrants", true);
		this.Sync("halltoprightmigrants", true);
		this.Sync("hallbottomleftmigrants", true);
		this.Sync("hallbottomrightmigrants", true);
	}*/
}


void onTick(CRules@ this){
	if(this.isMatchRunning() == true){
		updateMigrants(this);
		if(getGameTime() - this.get_u32("lastPaid") > SALARY_PERIOD){
			this.set_u32("lastPaid", getGameTime());
			this.Sync("lastPaid", true);
			updateSalaries(this);
		}
	}
}

void updateSalaries(CRules@ this){
	
	CBlob@[] halls;
	getBlobsByName( "hall", @halls );

	uint count = getPlayerCount();
	for(uint p_step = 0; p_step < count; ++p_step){
		CPlayer@ p = getPlayer(p_step);
		if(p.getTeamNum() == 0)
			p.server_setCoins( p.getCoins() + this.get_u16("blueincome") );
		else if(p.getTeamNum() == 1)
			p.server_setCoins( p.getCoins() + this.get_u16("redincome") );
		if(p.getBlob() !is null)
			p.getBlob().getSprite().PlaySound("/goldsack_take.ogg");
	}
	//client_AddToChat( "Cha-ching! Blue Income: " + formatInt(this.get_u16("blueIncome"), ""));
	//" Red Income: " + formatInt(redIncome, "") );
}	

/*void onRender(CRules@ this){
	CPlayer@ player = getLocalPlayer();

	if(player == null || !p.isMyPlayer())
		return;
	
	Vec2f(getScreen

}*/

void updateMigrants(CRules@ this)
{

	u16 halltl = 0;
	u16 halltr = 0;
	u16 hallbl = 0;
	u16 hallbr = 0;


	u16 bluecount = 0;
	u16 redcount = 0;
	CBlob@[] migrants;
	getBlobsByName( "migrant", @migrants );   
	for (uint i=0; i < migrants.length; i++)
	{
		CBlob@ migrant = migrants[i];
		if (migrant.getTeamNum() == 0 && !migrant.hasTag("dead")) {
			bluecount++;
		}
		else if (migrant.getTeamNum() == 1 && !migrant.hasTag("dead")) {
			redcount++;
		}

		int migrantZone = determineZone(migrant);

		if(determineSide(migrant)){
			if(migrantZone == 0)
				halltr++;
			else if(migrantZone == 1)
				hallbr++;
		}
		else{
			if(migrantZone == 0)
				halltl++;
			else if(migrantZone == 1)
				hallbl++;
		}
	}


	this.set_u16("halltopleftmigrants", halltl);
	this.set_u16("halltoprightmigrants", halltr);
	this.set_u16("hallbottomleftmigrants", hallbl);
	this.set_u16("hallbottomrightmigrants", hallbr);
	this.set_u16("blueincome", 10 + bluecount);
	this.set_u16("redincome", 10 + redcount);
	/*if(getNet().isServer()){
		this.Sync("halltopleftmigrants", true);
		this.Sync("halltoprightmigrants", true);
		this.Sync("hallbottomleftmigrants", true);
		this.Sync("hallbottomrightmigrants", true);
	}*/

}


// Old info render moved to Heroes_Interface
/*void onRender(CRules@ this){
	// Salary display box
	Vec2f topLeft = Vec2f(10, 10);
	Vec2f boxSize = Vec2f(235, 170);
	GUI::DrawPane(topLeft, topLeft+boxSize);

	GUI::DrawText("Migrants/Income", topLeft + Vec2f(56, 8), color_white);
	
	Vec2f hallOffset = topLeft + Vec2f(90, 35);
	GUI::DrawText("Hall 1", hallOffset, color_black);
	GUI::DrawText("Hall 2", hallOffset + Vec2f(65, 0), color_black);

	Vec2f laneOffset = topLeft + Vec2f(25, 60);
	
	GUI::DrawText("Top", laneOffset, color_black);
	GUI::DrawText("Bottom", laneOffset + Vec2f(0, 35), color_black);


	
	CBlob@[] halls;
	getBlobsByName( "hall", @halls );   
	
	for (uint i=0; i < halls.length; i++)
	{
		CBlob@ hall = halls[i];

		int migrantZone = determineZone(hall);

		if(determineSide(hall)){
			if(migrantZone == 0){
				u8 halltr = hall.get_u8("migrants max");
				string tr = formatInt(this.get_u16("halltoprightmigrants"), "") +
				" (" + formatInt(halltr, "") + ")";
				GUI::DrawText(tr, Vec2f(hallOffset.x + 70, laneOffset.y), getTeamColor(hall.getTeamNum()));
			}
			else if(migrantZone == 1){
				u8 hallbr = hall.get_u8("migrants max");
				string br = formatInt(this.get_u16("hallbottomrightmigrants"), "") +
				" (" + formatInt(hallbr, "") + ")";
				GUI::DrawText(br, Vec2f(hallOffset.x + 70, laneOffset.y + 35), getTeamColor(hall.getTeamNum()));
			}
		}
		else{
			if(migrantZone == 0){
				u8 halltl = hall.get_u8("migrants max");
				string tl = formatInt(this.get_u16("halltopleftmigrants"), "") +
				" (" + formatInt(halltl, "") + ")";
				GUI::DrawText(tl, Vec2f(hallOffset.x + 5, laneOffset.y), getTeamColor(hall.getTeamNum()));
			}
			else if(migrantZone == 1){
				u8 hallbl = hall.get_u8("migrants max");
				string bl = formatInt(this.get_u16("hallbottomleftmigrants"), "") +
				" (" + formatInt(hallbl, "") + ")";
				GUI::DrawText(bl, Vec2f(hallOffset.x + 5, laneOffset.y + 35), getTeamColor(hall.getTeamNum()));
			}
		}
	}
	
	
	
	
	GUI::DrawText("Blue Total: " + formatInt(this.get_u16("blueincome"), ""), topLeft + Vec2f(25, 120), color_white);
	GUI::DrawText("Red Total: " + formatInt(this.get_u16("redincome"), ""), topLeft + Vec2f(139, 120), color_white);

	GUI::DrawText("Income in: " + formatInt(30 - ( getGameTime() - this.get_u32("lastPaid")) / getTicksASecond() , ""), topLeft + Vec2f(72, 145), color_black);
	

}*/

