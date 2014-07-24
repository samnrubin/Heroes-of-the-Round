void onDie(CBlob@ this){
	if(this.hasTag("personalGuard")){
		/*CBlob@ sergeant = getBlobByNetworkID(this.get_u16("sergeant"));
		if(sergeant !is null){
			sergeant.set_u8("guardsize", sergeant.get_u8("guardsize") - 1);
		}*/
	}
	else if(this.hasTag("retinue")){
		CBlob@ sergeant = getBlobByNetworkID(this.get_u16("sergeant"));
		if(sergeant !is null){
			sergeant.set_u8("retinuesize", sergeant.get_u8("retinuesize") - 1);
		}
	}

}
