--- author-to-canonical – lua Change authors metadata to "canonical form", as achieved with the scholarly-metadata.lua filter.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/author-to-canonical.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

-- get_country() --------------------------------------------------------------------------------
-- Description: [en] Generates a table with the list of countries and the country code as a key.
--				[es] Genera una tabla con el listado de paises y el código como clave.
-- Return: [en] Una tabla de la forma codigo:país (key:value)
--		   [es] A table of the form code:country (key:value).
-- 

local function get_country(config_path, lang)

	-- require csv library and read countries file
    local csv = pandoc.system.with_working_directory(config_path, function() return dofile("CSV.lua") end)
    
    -- data from: https://gist.github.com/brenes/1095110#file-paises-csv
    local datos, header = pandoc.system.with_working_directory(config_path, function() return csv.load("paises.csv",  ',', true) end)

    local lang_index
    -- English or spanish country name?
    if lang:match('^es') then
        lang_index = 1
    elseif lang:match('^en') then
        lang_index = 2
    else
        io.stderr:write('WARNING: The language provided ("' .. lang .. '") is not supported. International countries names are used".\n')
        lang_index = 3
    end


    local paises = {}
    for _, v in pairs(datos) do
        paises[v[4]] = v[lang_index]
    end
    
    return paises
end

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Changes authors and organization information to "canonical form", as achieved 
--                      with the 'scholarly-metadata.lua' filter (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata).
--				[es] Cambia autores y organizaciones a "forma canónica", como se consigue con el 
--                      filtro 'scholarly-metadata.lua' (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata)
-- Return: [en] Metadata modified. See <https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata>
--		   [es] Metadata modificado. Ver <https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata>

function Meta(m)

    if(m.affiliation) then
        local paises = get_country(m.config_path, stringify(m.lang))
        
        -- * affiliation --> institute
        local inst = m.affiliation

        local inst_dict = {}
        for i = 1, #inst do
            inst[i].index = i
            inst[i].name = inst[i].organization
            
            local country = pandoc.text.upper(stringify(inst[i]["country-code"]))
            inst[i].country =  paises[country]
            
            if inst[i].country == nill then
                io.stderr:write("Invalid country code (".. country .. "). You must enter code according to ISO 3166-1 alpha-2. " ..
                                "See https://www.nationsonline.org/oneworld/country_code_list.htm")
            end

            inst_dict[stringify(inst[i].id)] = i
        end

        -- * author
        local aut = m.author
        for i = 1, #aut do
            aut[i].name = stringify(aut[i]["given-names"]) ..
                        " " .. stringify(aut[i]["surname"]) 
            aut[i].name = pandoc.MetaInlines{pandoc.Str(aut[i].name)}
            aut[i].id = aut[i].name

            aut[i].institute = {}

            for j = 1, #aut[i].affiliation do
                local v_str = stringify(aut[i].affiliation[j])
                aut[i].institute[j] = inst_dict[v_str]
            end
        end

        m.author = aut
        m.affiliation = inst
        m.institute = inst
        
        return m
    end
end