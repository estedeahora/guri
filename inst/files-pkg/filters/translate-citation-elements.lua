--- translate-citation-elements.lua – filter to translate citation elements (in zotero reference)
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-citation-elements.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

function Cite(cite)

    for i = 1, #cite.citations, 1 do

        local c = cite.citations[i].suffix

        if c ~= nil then
            c = stringify(c):gsub("page", "p."):gsub("pages", "pp."):gsub("chapter", "capítulo"):gsub("paragraph", "párrafo")
            cite.citations[i].suffix = c
        end

    end

    return cite
end