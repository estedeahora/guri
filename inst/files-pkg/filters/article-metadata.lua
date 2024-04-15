--- article-metadata.lua – filter to check content of titles
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/article-metadata.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Meta(m) ---------------------------------------------------------------------------
-- Description: [en] Moves the fields associated with meta.metadata (title, subtitle, abstract, and kw) to meta, preventing 
--                      them from being overwritten if they are present in the docx document (store these in 'title_word'/
--                      'subtitle_word'). 
--              [es] Traslada los campos asociados a meta.metadata (title, subtitle, abstract, y kw) a meta, evitando que
--                      se sobrescriban si están presentes en el documento docx (guarda estos en 'title_word'/'subtitle_word').
-- Return: [en] Meta modified. Article metadata (m.metadata.*) is dropped to m.* 
--         [es] Meta modificado. Los metadatos del artículo (m.metadata.*) pasan a m.*. 

local stringify = pandoc.utils.stringify

function Meta(m)

    -- m.metadata.* -> to -> m.*
    if m.title then
        m.title_word = m.title
    end

    m.title = m.metadata.title
    
    if m.metadata.subtitle then
        m.subtitle = m.metadata.subtitle
    end

    if stringify(m.title_word) ~= stringify(m.metadata.title) then
        io.write("WARNING: Title does not match in docx and yaml file.\n")

        io.write('* Title in Word:', '"' .. stringify(m.title_word) .. "'\n") 
        io.write('* Title in YAML:', '"' .. stringify(m.metadata.title) .. "'\n") 
    end

    if m.metadata.abstract then
        m.abstract = m.metadata.abstract
    end

    if m.metadata.keyword then
        m.keyword = m.metadata.keyword
    end

    m.metadata = nil

    return m
end
