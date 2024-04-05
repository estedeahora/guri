--- title.lua – filter to check content of titles
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/title.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- fig_latex(label, float_attr) ----------------------------------------
-- Description: [en] Moves the fields associated with meta.metadata (title, subtitle, abstract, and kw) to meta, preventing 
--                      them from being overwritten if they are present in the docx document (store these in 'title_word'/
--                      'subtitle_word'). In addition, lang is modified if the language of the article is different from 
--                      the main article of the journal.
--              [es] Traslada los campos asociados a meta.metadata (title, subtitle, abstract, y kw) a meta, evitando que
--                      se sobrescriban si están presentes en el documento docx (guarda estos en 'title_word'/'subtitle_word').
--                      Además, se modifica lang si el lenguaje del artículo es diferente del artículo principal de la revista. 
-- Return: [en] Metadata modified.
--         [es] Metadata modificado.

local stringify = pandoc.utils.stringify

function Meta(m)

    -- m.metadata -> to -> m
    if m.title then
        m.title_word = m.title
    end

    m.title = m.metadata.title
    
    if m.metadata.subtitle then
        m.subtitle = m.metadata.subtitle
    end

    if stringify(m.title_word) ~= stringify(m.metadata.title) then
        io.stderr:write("WARNING: Title does not match in docx and yaml file.\n")

        print('* Title in Word:', '"' .. stringify(m.title_word) .. "'") 
        print('* Title in YAML:', '"' .. stringify(m.metadata.title) .. "'") 

    end

    if m.metadata.abstract then
        m.abstract = m.metadata.abstract
    end

    if m.metadata.keyword then
        m.keyword = m.metadata.keyword
    end

    -- Modify the journal's default language for the article.
    if m.metadata['artic-lang'] then
        io.stderr:write("WARNING: The article uses a different main language than the journal.\n")
        m.lang = m.metadata['artic-lang']
    end

    m.metadata = nil

    return m
end
