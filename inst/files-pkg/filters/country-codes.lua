--- country-codes – lua Change authors metadata to "canonical form", as achieved with the scholarly-metadata.lua filter.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/country-codes.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local with_working_directory = pandoc.system.with_working_directory
local upper = pandoc.text.upper

-- get_country() --------------------------------------------------------------------------------
-- Description: [en] Generates a table with the list of countries and the country code as a key.
--				[es] Genera una tabla con el listado de paises y el código como clave.
-- Return: [en] Una tabla de la forma codigo:país (key:value)
--		   [es] A table of the form code:country (key:value).
-- 

local function get_country(config_path, lang)

	-- require csv library and read countries file
    local csv = with_working_directory(config_path, function() return dofile("CSV.lua") end)
    
    -- data from: https://gist.github.com/brenes/1095110#file-paises-csv
    local datos, header = with_working_directory(config_path, function() return csv.load("paises.csv",  ',', true) end)

    local lang_index
    -- English or spanish country name?
    if lang:match('^es') then
        lang_index = 1
    elseif lang:match('^en') then
        lang_index = 2
    else
        warn('WARNING: The language provided ("' .. lang .. '") is not supported. International countries names are used".\n')
        lang_index = 3
    end

    local paises = {}
    for _, row in pairs(datos) do
        paises[row[4]] = row[lang_index]
    end

    return paises
end


-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Add the name of the countries for affiliations.
--				[es] Agrega el nombre de los países para las afiliaciones.
-- Return: [en] Modified meta. Country names are added inside meta.affiliation[i].country.
--		   [es] Meta modificado. Se agrega el nombre de los países dentro de meta.affiliation[i].country.

function Meta(meta)

    local paises = get_country(meta.config_path, stringify(meta.lang))

    if meta.affiliation then
        for _, aff in ipairs(meta.affiliation) do

            local country = upper(stringify(aff["country-code"]))
            aff.country =  paises[country]
            
            if aff.country == nill then
                error("ERROR: Invalid country code (".. country .. "). You must enter code according to ISO 3166-1 alpha-2. " ..
                                "See https://www.nationsonline.org/oneworld/country_code_list.htm")
            end
        end
    end
    return meta

end
