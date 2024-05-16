--- crossref_autaff – Prepare authors and affiliations for Crossref.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref_autaff.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Add the field 'author[i].sequence' and place, for each author,
--                     'meta.affiliation' within 'author[i].insitution'. For each
--                     'author[i].afiliation' search within each element in
--                     'meta.affiliation' until matching 'id' and copy the element
--                     from 'meta.affiliation' to 'author[i].institution[j]'.
--				[es] Agrega el campo 'author[i].sequence' y coloca, para cada autor,
--                     'meta.affiliation' dentro de 'author[i].insitution'. Para cada 
--                     'author[i].afiliation' busca dentro de cada elemento en 
--                     'meta.affiliation' hasta coincidir 'id' y copia el elemento 
--                     de 'meta.affiliation' a 'author[i].institution[j]'.
-- Return: [en] Modified metadata adding for each 'author[i]' the fields
--                (a) 'author[i].sequence'; and (b) 'author[i].insitution'.
--		   [es] Metadata modificado agregando para cada 'author[i]' los campos
--                (a) 'author[i].sequence'; y (b) 'author[i].insitution'.

function Meta(meta)

    if not meta.author then
        return meta
    end

    local author = meta.author
    local aff = meta.affiliation

    for i, aut_i in ipairs(author) do

        -- (a) author[i].sequence --> "first" or "additional"
        aut_i.sequence = (i == 1) and "first" or "additional"

        -- (b) author[i].insitution
        if not aut_i.affiliation then
            return meta
        end

        aut_i.institution = {}

        for j, aut_i_aff_j in ipairs(aut_i.affiliation) do    
            
            for _, aff_k in ipairs(aff) do

                if aff_k.id == aut_i_aff_j then
                    aut_i.institution[j] = aff_k
                end

            end
        end
    end

    return(meta)
end