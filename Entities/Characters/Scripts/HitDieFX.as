void onDie(CBlob@ this){
	if(this.hasTag("retinue")){
		CBlob@ sergeant = getBlobByNetworkID(this.get_u16("sergeant"));
		if(sergeant !is null){
			sergeant.set_u8("retinuesize", sergeant.get_u8("retinuesize") - 1);
		}
	}
}
