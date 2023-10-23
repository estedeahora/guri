--- translate-citation-elements.lua – filter to 
--- https://github.com/estedeahora/guri/tree/main/files/filters/credit.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

function Cite(cite)

    for i = 1, #cite.citations, 1 do

        local c = cite.citations[i].suffix

        if c ~= nil then
            c = stringify(c):gsub("page", "p."):gsub("pages", "pp."):gsub("chapter", "capítulo")
            cite.citations[i].suffix = c
        end

    end

    return cite
end