--- translate-zotero.lua – filter to translate elements
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-zotero.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

function Cite(cite)

    local cite_text = stringify(cite)
    
    for k, citation in ipairs(cite.citations) do
        prefix = stringify(citation.prefix)
        if #prefix > 0 then 
            prefix = stringify(citation.prefix) .. " "
        end
        if cite_text:match('^%(' .. prefix .. '[0-9][0-9][0-9]') then
            citation.mode = "SuppressAuthor"
        end
    end
   
    return cite
end