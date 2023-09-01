--- title.lua – filter to 
--- https://github.com/..
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa


-- Borrar campo de título y subtítulo originales en word
--------------------------------------------------------

function Meta(m)
    if m.title then
        m.title_word = m.title
    end

    if m.title_word ~= m.title_es then
        io.stderr:write("No coincide título en word y en yaml. ")

        m.title = m.title_es
    end
   
    if m.subtitle then
        m.subtitle_word = m.subtitle
    end

    if m.title_word ~= m.title_es then
        m.subtitle = m.subtitle_es
    end

    -- for k,v in pairs(m) do
    --     print(k, v)
    -- end
    return m
end
