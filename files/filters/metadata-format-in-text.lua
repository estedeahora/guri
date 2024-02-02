--- metadata-format-in-text.lua – filter to include div elements (before the reference) in the output format
--- https://github.com/estedeahora/guri/tree/main/files/filters/metadata-format-in-text.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local RawBlock = pandoc.RawBlock
local app = nil

function Div(div)

    if(div.classes[1] == "Paratext") then
        
        if FORMAT:match 'jats' then
            if(div.identifier == "app") then
                app = div.content
                div = RawBlock('jats', '')
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