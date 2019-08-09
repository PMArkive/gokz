/*
	Inserts the map information into the database.
	Retrieves the MapID of the map and stores it in a global variable.
*/



void DB_SetupMap()
{
	gB_MapSetUp = false;
	
	char query[1024];
	
	char map[PLATFORM_MAX_PATH];
	GetCurrentMapDisplayName(map, sizeof(map));
	
	Transaction txn = SQL_CreateTransaction();
	
	// Insert/Update map into database
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			// UPDATE OR IGNORE
			FormatEx(query, sizeof(query), sqlite_maps_update, map);
			txn.AddQuery(query);
			// INSERT OR IGNORE
			FormatEx(query, sizeof(query), sqlite_maps_insert, map);
			txn.AddQuery(query);
		}
		case DatabaseType_MySQL:
		{
			// INSERT ... ON DUPLICATE KEY ...
			FormatEx(query, sizeof(query), mysql_maps_upsert, map);
			txn.AddQuery(query);
		}
	}
	// Retrieve mapID of map name
	FormatEx(query, sizeof(query), sql_maps_findid, map, map);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SetupMap, DB_TxnFailure_Generic, 0, DBPrio_High);
}

public void DB_TxnSuccess_SetupMap(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			if (SQL_FetchRow(results[2]))
			{
				gI_DBCurrentMapID = SQL_FetchInt(results[2], 0);
				gB_MapSetUp = true;
				Call_OnMapSetup();
			}
		}
		case DatabaseType_MySQL:
		{
			if (SQL_FetchRow(results[1]))
			{
				gI_DBCurrentMapID = SQL_FetchInt(results[1], 0);
				gB_MapSetUp = true;
				Call_OnMapSetup();
			}
		}
	}
} 