--- translate-elements.lua – filter to translate elements
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/translate-elements.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local lang

-- get_metadata_title(lang_metadata) -----------------------------------------------------------------------

function get_metadata_title(lang_metadata)
    
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

            meta_i.abstract_title, meta_i.keyword_title = get_metadata_title(lang_i)

            other_langs_metadata[k] = meta_i
        end
    end
    return(other_langs_metadata)
end

-- Meta(meta) --------------------------------------------------------------------------------------

function Meta(meta)

       -- Modify the journal's default language for the article.
    -- m.customized.* -> to -> m.*

    if m.customized then
        if m.customized['artic-lang'] then
            io.write("NOTE: The article uses a different main language than the journal.\n")
            m.lang = m.customized['artic-lang']
        end

        if m.customized['abstract_title'] then
            m.abstract_title = m.customized['abstract_title']
        end

        if m.customized['keyword_title'] then
            m.keyword_title = m.customized['keyword_title']
        end

        if m.customized['table_title'] then
            m.table_title = m.customized['table_title']
        end

        if m.customized['figure_title'] then
            m.figure_title = m.customized['figure_title']
        end

        if m.customized['references_title'] then
            m.references_title = m.customized['references_title']
        end
    end

    lang = stringify(meta.lang)

    -- Abstract / kw main language
    if not meta.abstract_title then
        meta.abstract_title, _ = get_metadata_title(lang)
    end

    if not meta.keyword_title then
        _, meta.keyword_title = get_metadata_title(lang)
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


