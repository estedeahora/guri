--- title.lua – filter to check content of titles
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/title.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- fig_latex(label, float_attr) ----------------------------------------
-- Description: [en] Remove the title and subtitle field as they come from the docx file (stored in 'title_word'/'subtitle_word') 
--                      and replace them with 'title_es' / 'subtitle_es', respectively .
--              [es] Borra el campo de título y subtítulo tal como vienen del archivo docx (lo guarda en 'title_word'/'subtitle_word')
--                       y los reemplaza por 'title_es' / 'subtitle_es', respectivamente.
-- Return: [en] Metadata modified.
--         [es] Metadata modificado.

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
        io.stderr:write("\n WARNING: Title does not match in docx and yaml file.\n")

        print('* Title in Word:', '"' .. stringify(m.title_word) .. "'\n") 
        print('* Title in YAML:', '"' .. stringify(m.title_es) .. "'\n") 

    end

    return m
end
