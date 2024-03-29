--- title.lua – filter to check content of titles
--- https://github.com/estedeahora/guri/tree/main/files/filters/title.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- fig_latex(label, float_attr) ----------------------------------------
-- Borra el campo de título y subtítulo tal como vienen de word (lo guarda en title_word/subtitle_word) y los reemplaza por title_es / subtitle_es.
-- Return: Metadata modificado

local stringify = pandoc.utils.stringify

function Meta(m)
    if m.title then
        m.title_word = m.title
    end

    m.title = m.title_es
    
    if m.subtitle_es then
        m.subtitle = m.subtitle_es
    end

    if stringify(m.title_word) ~= stringify(m.title_es) then
        io.stderr:write("\nNo coincide título en word y en yaml.\n")

        print('Título en Word:', '"' .. stringify(m.title_word) .. "'") 
        print('Título en YAML:', '"' .. stringify(m.title_es) .. "'") 

    end

    return m
end
