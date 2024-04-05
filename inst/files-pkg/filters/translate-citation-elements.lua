--- translate-citation-elements.lua – filter to translate citation elements (in zotero reference)
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-citation-elements.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local lang

function Meta(meta)

    lang = stringify(meta.lang)

end

-- Cite(cite) --------------------------------------------------------------------------------------
-- Description: [en] Translate citation elements (coming from zotero plug-in for word in 'fields').
--				[es] Traducir elementos de cita (provenientes de complemento de zotero para word en 'campos').
-- Return: [en] An element of type pandoc.cite with suffixes translated into Spanish.
--		   [es] Un elemento de tipo pandoc.cite con sufijos traducidos al español.

function Cite(cite)

    if not lang:match('^en') then

        for i = 1, #cite.citations, 1 do

            local c = cite.citations[i].suffix

            if c ~= nil then
                if lang:match('^es') or lang:match('^pt')  then
                    c = stringify(c):gsub("page", "p."):gsub("pages", "pp."):gsub("chapter", "capítulo"):gsub("paragraph", "párrafo")
                end

                cite.citations[i].suffix = c
            end

        end

    end

    return cite
end

return {
    { Meta = Meta },
    { Cite = Cite }
  }