--- metadata-format-in-text.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/credit-before-bib.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local RawBlock = pandoc.RawBlock

function Div(div)

    if(div.classes[1] == "Paratext") then
        
        if FORMAT:match 'jats' then
            div = RawBlock('jats', '')
        elseif FORMAT:match 'latex' or FORMAT:match 'pdf' then

            div = {RawBlock('latex', '\\begin{'.. div.identifier .. '}'),
                   div, 
                   RawBlock('latex', '\\end{' .. div.identifier .. '}')}
        end
    
    end

    return div

end