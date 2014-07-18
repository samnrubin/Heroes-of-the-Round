
//names of stuff which should be able to be hit by
//team builders, drills etc

const string[] builder_alwayshit = {
	//handmade
	"workbench",
	//"fireplace",
	"ladder",
	
	//faketiles
	"spikes",
	"trapblock",
	
	//buildings
	"factory",
	"building",
	"quarters",
	"storage",
	
	//heroes items

};

//fragments of names, for semi-tolerant matching
// (so we don't have to do heaps of comparisions
//  for all the shops)
const string[] builder_alwayshit_fragment = {
	"shop"
};

bool BuilderAlwaysHit(CBlob@ blob)
{
	string name = blob.getName();
	for (uint i = 0; i < builder_alwayshit.length; ++i)
	{
		if (builder_alwayshit[i] == name)
			return true;
	}
	for (uint i = 0; i < builder_alwayshit_fragment.length; ++i)
	{
		if(name.find(builder_alwayshit_fragment[i]) != -1)
			return true;
	}
	return false;
}
