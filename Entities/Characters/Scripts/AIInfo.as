#define CLIENT_ONLY

//debug target info
void onRender( CSprite@ this ){
	if(!sv_test)
		return;
	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;		 
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob){
		CBlob@ target = getBlobByNetworkID(blob.get_u16("target"));
		if(target !is null){
			GUI::DrawArrow(center, target.getPosition(), color_white);
			//print(formatInt(blob.get_u8("direction"), ""));
		}

	}
}

void onInit(CSprite@ this){
	CBlob@ blob = this.getBlob();
	CSpriteLayer @indicator = this.addSpriteLayer( "retinue_indicator", "../Mods/KagMoba/Entities/Effects/Sprites/RetinueIndicator.png", 8, 8, this.getBlob().getTeamNum(), -1 );

	if (indicator !is null)
	{
		Animation@ anim = indicator.addAnimation( "reg", 0, true );
		anim.AddFrame(0);
		indicator.SetVisible( false );
		indicator.SetRelativeZ( 10 );
		indicator.SetAnimation("reg");
	}

}

void onTick(CSprite@ this){
	CBlob@ blob = this.getBlob();
	blob.Sync("retinue", true);
	CSpriteLayer @indicator = this.getSpriteLayer("retinue_indicator");
	if(!blob.hasTag("dead") && blob.hasTag("retinue")){

		//int bounce = 2*Maths::Sin((getGameTime()/4.5f));
		indicator.SetVisible( true );
		indicator.SetOffset(Vec2f(0.0f, -16));
	}
	else{
		indicator.SetVisible(false);
	}
}


