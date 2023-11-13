--- metadata-format-in-text.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/credit-before-bib.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local RawBlock = pandoc.RawBlock
local app = nil

function Div(div)

    if(div.classes[1] == "Paratext") then
        
        if FORMAT:match 'jats' then
            if(div.identifier == "app") then
                app = div.content
                div = pandoc.Header(1, '')
            else
                div = RawBlock('jats', '')
            end

            
        elseif FORMAT:match 'latex' or FORMAT:match 'pdf' then

            div = {RawBlock('latex', '\\begin{'.. div.identifier .. '}'),
                   div, 
                   RawBlock('latex', '\\end{' .. div.identifier .. '}')}
        end
    
    end

    return div

end

function Meta(m)

    if(app) then
        m.app = app
    end
    return(m)
end