--- author-to-canonical – lua Change authors metadata to "canonical form", as achieved with the scholarly-metadata.lua filter.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/author-to-canonical.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Changes authors and organization information to "canonical form", as achieved 
--                     with the 'scholarly-metadata.lua' filter (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata).
--                     This allows the use of 'author-info-blocks.lua' (https://github.com/pandoc/lua-filters/tree/master/author-info-blocks).
--				[es] Cambia autores y organizaciones a "forma canónica", como se consigue con el 
--                     filtro 'scholarly-metadata.lua' (https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata).
--                     Esto permite utilizar 'author-info-blocks.lua' (https://github.com/pandoc/lua-filters/tree/master/author-info-blocks).
-- Return: [en] Metadata modified. See <https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata>
--		   [es] Metadata modificado. Ver <https://github.com/pandoc/lua-filters/tree/master/scholarly-metadata>

function Meta(meta)

    if(meta.affiliation) then
        
        -- meta.affiliation --> to meta.institute (con sólo 'index' y 'name')
        local inst = {}
        local inst_dict = {}

        for k, v in ipairs(meta.affiliation) do
            inst[k] = {}
            inst[k].index = k
            inst[k].name = v.organization

            -- Add meta.affiliation[i].id and meta.affiliation[i].name
            v.index = k
            v.name = v.organization

            inst_dict[stringify(v.id)] = k
        end

        -- Modifies meta.author
        local aut = meta.author
        for i = 1, #aut do

            -- Add meta.aut[i].id and meta.aut[i].name
            aut[i].name = stringify(aut[i]["given-names"]) .. " " .. stringify(aut[i]["surname"]) 
            aut[i].name = pandoc.MetaInlines{pandoc.Str(aut[i].name)}
            aut[i].id = aut[i].name

            -- Add to meta.author[i].institute a table with 'institute indexes' 
            aut[i].institute = {}
            for j, aff in ipairs(aut[i].affiliation)  do
                aut[i].institute[j] = inst_dict[stringify(aff)]
            end

        end

        meta.author = aut
        meta.institute = inst
        
        return meta
    end
end