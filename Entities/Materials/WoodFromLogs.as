#include "MakeMat.as";

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	return;
    // make wood from hitting log
    if (getNet().isServer() && hitBlob !is null && hitBlob.getName() == "log" && damage > 0.0f)
    {
		//printf("damaga" + damage );
        int amount = 20.0f*damage;
        MakeMat( this, worldPoint, "mat_wood", Maths::Max(1,amount) );
    }
}
