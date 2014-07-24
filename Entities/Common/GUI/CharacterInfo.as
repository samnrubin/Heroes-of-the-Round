#define CLIENT_ONLY

void onInit(CSprite@ this){
	CBlob@ blob = this.getBlob();
	if(blob.getPlayer() !is getLocalPlayer() ){
		CSpriteLayer @arrow = this.addSpriteLayer( "team_arrow", "../Mods/KagMoba/Entities/Effects/Sprites/PointerArrow.png", 8, 16, this.getBlob().getTeamNum(), -1 );

		if (arrow !is null)
		{
			{
				Animation@ anim = arrow.addAnimation( "reg", 3, true );
				anim.AddFrame(0);
				/*anim.AddFrame(1);
				anim.AddFrame(2);
				anim.AddFrame(3);
				anim.AddFrame(4);
				anim.AddFrame(5);
				anim.AddFrame(6);
				anim.AddFrame(5);
				anim.AddFrame(4);
				anim.AddFrame(3);
				anim.AddFrame(2);
				anim.AddFrame(1);*/        }
			arrow.SetVisible( false );
			arrow.SetRelativeZ( 10 );
			arrow.SetAnimation("reg");
		}
	}

}

void onTick(CSprite@ this){
	CBlob@ blob = this.getBlob();
	CSpriteLayer @arrow = this.getSpriteLayer("team_arrow");
	if(blob.getPlayer() !is getLocalPlayer() && !blob.hasTag("dead") &&
	   !(blob.hasTag("cloaked") && blob.getTeamNum() != getLocalPlayer().getTeamNum())){

		int bounce = 4*Maths::Sin((getGameTime()/4.5f));
		arrow.SetVisible( true );
		arrow.SetOffset(Vec2f(0.0f, -16 + bounce));
	}
	if(blob.hasTag("dead")){
		arrow.SetVisible(false);
	}

}
