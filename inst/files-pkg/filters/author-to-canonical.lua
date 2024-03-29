--- author-to-canonical – lua Change authors metadata to "canonical form", as achieved with the scholarly-metadata.lua filter.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/author-to-canonical.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

-- get_country() --------------------------------------------------------------------------------
-- Description: [en] 
--				[es] 
-- Return: [en] 
--		   [es] Tabla con listado de paises (y código como clave)
-- 

local function get_country(config_path)

    local csv = pandoc.system.with_working_directory(config_path, function() return dofile("CSV.lua") end)
    
    -- data from: https://gist.github.com/brenes/1095110#file-paises-csv
    local datos, header = pandoc.system.with_working_directory(config_path, function() return csv.load("paises.csv",  ',', true) end)

    local paises = {}
    for _, v in pairs(datos) do
        paises[v[4]] = v[1]
    end
    
    return paises
end


-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] 
--				[es] Cambia autores a "forma canónica", como se consigue con el filtro scholarly-metadata.lua (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata)
-- Return: [en] 
--		   [es] 

function Meta(m)

    if(m.affiliation) then
        local paises = get_country(m.config_path)
        
        -- * Afiliaciones --> Institute
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

        -- * Autores
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