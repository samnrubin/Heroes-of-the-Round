// ExtraNoBuild.as - via Skinney
#include "Heroes_MapFunctions.as";

void onInit(CRules@ this)
{
    addExtraNoBuild();
}
  
void onRestart(CRules@ this)
{
    addExtraNoBuild();
}
  
void addExtraNoBuild()
{
    CMap@ map = getMap();
    f32 mapWidth = map.tilemapwidth * map.tilesize;
    f32 mapHeight = map.tilemapheight * map.tilesize;
    f32 barrierWidth = 3.0f * map.tilesize;
    f32 barrierHeight = 3.0f * map.tilesize;

	Vec2f noBuildSize = t(Vec2f(44.0f, 18.0f));
  
    // Ceiling
    Vec2f tlCeiling = Vec2f(0.0f, 0.0f);
    Vec2f brCeiling = Vec2f(mapWidth, barrierHeight);
    map.server_AddSector(tlCeiling, brCeiling, "no build" );
  
    // Left
    /*Vec2f tlLeft = tlCeiling + Vec2f(0.0f, barrierHeight);
    Vec2f brLeft = Vec2f(barrierWidth, mapHeight);
    map.server_AddSector(tlLeft, brLeft, "no build" );*/
    Vec2f tlLeftTop = t(Vec2f(0, 29));
    Vec2f tlLeftBottom = t(Vec2f(0, 54));
    Vec2f brLeftTop = tlLeftTop + noBuildSize;
    Vec2f brLeftBottom = tlLeftBottom + noBuildSize;
    map.server_AddSector(tlLeftTop, brLeftTop, "no build" );
    map.server_AddSector(tlLeftBottom, brLeftBottom, "no build" );
  
    // Right
    /*Vec2f tlRight = Vec2f(mapWidth - barrierWidth, barrierHeight);
    //Vec2f tlRight = Vec2f(mapWidth - barrierWidth, barrierHeight);
    Vec2f brRight = Vec2f(mapWidth, mapHeight);
    map.server_AddSector(tlRight, brRight, "no build" );*/

    Vec2f tlRightTop = t(Vec2f(326, 29));
    Vec2f tlRightBottom = t(Vec2f(326, 54));
    Vec2f brRightTop = tlRightTop + noBuildSize;
    Vec2f brRightBottom = tlRightBottom + noBuildSize;
    map.server_AddSector(tlRightTop, brRightTop, "no build" );
    map.server_AddSector(tlRightBottom, brRightBottom, "no build" );
}
