--- translate-elements.lua – filter to translate elements
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-elements.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local lang

-- get_metatitle(lang_metadata) -----------------------------------------------------------------------

function get_metatitle(lang_metadata)
    
    local tit_abstract
    local tit_kws
    if lang_metadata:match('en') then
        tit_abstract = 'Abstract'
        tit_kws = 'Keywords'
    elseif  lang_metadata:match('es') then
        tit_abstract = 'Resumen'
        tit_kws = 'Palabras claves'
    elseif  lang_metadata:match('pt') then
        tit_abstract = 'Resumo'
        tit_kws = 'Palavras chave'
    else
        io.stderr:write('WARNING: The language provided ("' .. lang_metadata .. 
                        '") does not have a predefined translation for metadata titles.\n')
    end

    return tit_abstract, tit_kws
end

-- add_metatitle(other_langs_metadata) -----------------------------------------------------------------------

function add_metatitle(other_langs_metadata)

    for k = 1, #other_langs_metadata do
        local meta_i
        local lang_i
        
        meta_i = other_langs_metadata[k]

        if not meta_i.abstract_title or not meta_i.keyword_title then

            lang_i = stringify(meta_i.lang)

            if meta_i.abstract_title or meta_i.keyword_title then
                error('ERROR:  Title for the abstract and keywords must be provided. '.. 
                      'Only one is present (language: ' .. lang_i .. ')\n')
            end

            meta_i.abstract_title, meta_i.keyword_title = get_metatitle(lang_i)

            other_langs_metadata[k] = meta_i
        end
    end
    return(other_langs_metadata)
end

-- Meta(meta) --------------------------------------------------------------------------------------

function Meta(meta)

    lang = stringify(meta.lang)

    -- Abstract / kw main language
    if not meta.abstract_title then
        meta.abstract_title, _ = get_metatitle(lang)
    end

    if not meta.keyword_title then
        _, meta.keyword_title = get_metatitle(lang)
    end

    if not meta.abstract_title or not meta.keyword_title then

            error('ERROR: The title of the "abstract" and "keywords" section must be provided' ..
                            'for the language en ' .. lang .. '\n')
    end

    -- Abstract / kw secondary languages 
    if(meta.metadata_lang) then
        meta.metadata_lang = add_metatitle(meta.metadata_lang)
    end

    return meta

end

-- Cite(cite) --------------------------------------------------------------------------------------
-- Description: [en] Translate citation elements (coming from zotero plug-in for word in 'fields').
--				[es] Traducir elementos de cita (provenientes de complemento de zotero para word en 'campos').
-- Return: [en] An element of type pandoc.cite with suffixes translated into Spanish.
--		   [es] Un elemento de tipo pandoc.cite con sufijos traducidos al español.

function Cite(cite)

    if not lang:match('^en') then

        for i = 1, #cite.citations, 1 do

            local c = cite.citations[i].suffix

            if c ~= nil then
                if lang:match('^es') or lang:match('^pt')  then
                    c = stringify(c):gsub("page", "p."):gsub("pages", "pp."):gsub("chapter", "capítulo"):gsub("paragraph", "párrafo")
                end

                cite.citations[i].suffix = c
            end

        end

    end

    return cite
end

return {
    { Meta = Meta },
    { Cite = Cite }
  }