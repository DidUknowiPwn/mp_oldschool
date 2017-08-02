#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\persistence_shared;
#using scripts\shared\rank_shared;
#using scripts\shared\system_shared;

#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_loadout;

#using scripts\mp\_pickup_items; // TODO

#using scripts\mp\gametypes\_oldschool_points;

#insert scripts\shared\shared.gsh;
#insert scripts\mp\gametypes\oldschool.gsh;

function autoexec init()
{
	if ( !IsInArray( StrTok("tdm dm", " "), ToLower( GetDvarString( "g_gametype" ) ) ) )
		return;

	MAKE_ARRAY( level.dev_points );
	level.giveCustomLoadout = &give_custom_loadout;

	callback::on_connect( &on_player_connect ); // force teams on connecting
	callback::on_spawned( &on_player_spawned ); // extra code on spawning
	callback::on_start_gametype( &start_gametype );
}

function start_gametype()
{
	a_spawn_points = [];
	a_spawn_points = oldschool_points::get_spawn_points();
	foreach( point in a_spawn_points )
	{
		IPrintLnBold( "Position: " + point );
	}
}

function on_player_connect()
{
	// pre-set the persistence to something so we prevent some errors related to menuTeam();
	// --- WARNING: Setting this will break ESC menu
	// --- ERROR: By disabling this healing will not work anymore.
	self.pers["team"] = "axis";
	// moving to a built-in, still setting a team just in case.
	self SetTeam( "axis" );
	// set this before to satisfy the spawnClient, need to fill in broken statement _globalloigc_spawn::836 
	self.waitingToSpawn = true;
	// something to satisfy matchRecordLogAdditionalDeathInfo 5th parameter (_globallogic_player)
	self.class_num = 0;
	// satisfy _loadout
	self.class_num_for_global_weapons = 0;
	// autoassign the player
	self [[level.autoassign]]( true );
	// notify class selection
	self notify( "menuresponse", MENU_CHANGE_CLASS, "class_assault" );
	// close the "Choose Class" menu
	self CloseMenu( game["menu_changeclass"] );	
}

function on_player_spawned()
{
	self thread debug_commands();
}

function give_custom_loadout()
{
	self TakeAllWeapons();
	self ClearPerks();

	primary_weapon = GetWeapon( "smg_mp40" ); // TODO
	secondary_weapon = GetWeapon( "pistol_m1911" ); // TODO

	self GiveWeapon( primary_weapon );
	self GiveWeapon( secondary_weapon );
	self SetSpawnWeapon( primary_weapon );

	return primary_weapon;
}

//	******************************
//	DEBUG
//	******************************
// TODO - Add to HUD
function debug_commands()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( !self IsHost() )
		return;

	while ( true )
	{
		// +activate -- ADD POINT
		if ( self UseButtonPressed() )
		{
			self add_point();
			while ( self UseButtonPressed() )
				WAIT_SERVER_FRAME;
		}
		// +actionslot 1 -- REMOVE POINT
		if ( self ActionSlotOneButtonPressed() )
		{
			self remove_point();
			while ( self ActionSlotOneButtonPressed() )
				WAIT_SERVER_FRAME;
		}
		// +actionslot 3 -- PRINT POINTS
		if ( self ActionSlotOneButtonPressed() )
		{
			self print_points();
			while ( self ActionSlotOneButtonPressed() )
				WAIT_SERVER_FRAME;
		}
		WAIT_SERVER_FRAME;
	}
}

function add_point()
{
	IPrintLn( "Placing Point: " + self.origin );
	array::push( level.dev_points, self.origin );
}

function remove_point()
{
	IPrintLn( "Removing Point: " + self.origin );
	array::pop( level.dev_points );
}

function print_points()
{
	foreach( point in level.dev_points )
	{
		IPrintLn( "ARRAY_ADD( a_spawn_points[ \"" + level.script + "\" ], " + point + " )");
	}
}