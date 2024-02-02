--- author-to-canonical – lua Change authors metadata to "canonical form", as achieved with the scholarly-metadata.lua filter.
--- Cambia autores a "forma canónica", como se consigue con el filtro scholarly-metadata.lua (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata)
--- https://github.com/estedeahora/guri/tree/main/files/filters/author-to-canonical.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

-- Tabla con listado de paises (y código como clave)
-- data from: https://gist.github.com/brenes/1095110#file-paises-csv
local function get_country()
    local csv = dofile("../../../files/filters/CSV.lua")
    
    
    local datos, header = csv.load('../../../files/filters/paises.csv', ',', true)

    local paises = {}
    for _, v in pairs(datos) do
        paises[v[4]] = v[1]
    end
    
    return paises
end

function Meta(m)

    if(m.affiliation) then
        local paises = get_country()
        
        -- * Afiliaciones --> Institute
        local inst = m.affiliation

        local inst_dict = {}
        for i = 1, #inst do
            inst[i].index = i
            inst[i].name = inst[i].organization
            
            local country = pandoc.text.upper(stringify(inst[i]["country-code"]))
            inst[i].country =  paises[country]
            
            if inst[i].country == nill then
                io.stderr:write("Código de país (".. country .. ") no válido. Debe ingresar código según ISO 3166-1 alpha-2. " ..
                                "Ver https://www.nationsonline.org/oneworld/country_code_list.htm")
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