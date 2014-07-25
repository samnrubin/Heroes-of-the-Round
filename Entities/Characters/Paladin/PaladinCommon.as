//common knight header
namespace KnightStates
{
enum States {
    normal = 0,
    shielding,
    shielddropping,
    shieldgliding,
    sword_drawn,
    sword_cut_mid,
    sword_cut_mid_down,
    sword_cut_up,
    sword_cut_down,
    sword_power,
    sword_power_super
}
}

namespace KnightVars
{
const ::s32 resheath_time = 5;

const ::s32 slash_charge = 15;
const ::s32 slash_charge_level2 = 38;
const ::s32 slash_charge_limit = slash_charge_level2+slash_charge+10;
const ::s32 slash_time = 13;
const ::s32 slash_move_time = 4;
const ::u32 force_ability_time = 10 * getTicksASecond();

const ::f32 slash_move_max_speed = 4.0f;
}

shared class PaladinInfo
{
	u8 swordTimer;
	u8 shieldTimer;
	bool doubleslash;
	u8 tileDestructionLimiter;
	u32 slideTime;
	u32 forceAbilityTimer;
	
	u8 state;
	Vec2f slash_direction;
	s32 shield_down;
};


namespace BombType
{
	enum type
	{
		bomb = 0,
		water,
		count
	};
}

const string[] bombNames = { "Bomb",
	"Water Bomb"
	};

const string[] bombIcons = { "$Bomb$",
	"$WaterBomb$" };

const string[] bombTypeNames = { "mat_bombs",
	"mat_waterbombs" };


//checking state stuff

bool isShieldState(u8 state)
{
    return (state >= KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSpecialShieldState(u8 state)
{
    return (state > KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSwordState(u8 state)
{
    return (state >= KnightStates::sword_drawn && state <= KnightStates::sword_power_super);
}

bool inMiddleOfAttack(u8 state)
{
    return ((state > KnightStates::sword_drawn && state <= KnightStates::sword_power_super));
}
