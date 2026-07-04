package.path = package.path .. ';./?.lua;./?/init.lua';

local function main()
    io.stderr:write('build_npc_object_zone_data.lua has been retired.\n');
    io.stderr:write('Zone files under data/npc_object_zones are now the source of truth.\n');
    io.stderr:write('Edit the zone files directly instead of rebuilding from legacy master tables.\n');
    os.exit(1);
end

main();
