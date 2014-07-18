#define CLIENT_ONLY

void onRender(CRules@ this){
	bool tutorial = this.get_bool("tutorialnoshow");
	if(!tutorial)
		GUI::DrawIcon("GUI/HOTRTutorial.png", Vec2f(getScreenWidth()/2 - 425, getScreenHeight()/2 - 657/2), 0.5f);

}

void onTick(CRules@ this){
	bool tutorial = this.get_bool("tutorialnoshow");
	if (getControls().isKeyJustPressed(KEY_KEY_Z)){
		if(tutorial)
			this.set_bool("tutorialnoshow", false);
		else
			this.set_bool("tutorialnoshow", true);
	}
}
