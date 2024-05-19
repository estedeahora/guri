--- crossref-resource-builder - Create resource URL and resource galleries URL for DOI registration in Crossref.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref-resource-builder.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The  crossref-resource-builder.lua is a Pandoc Lua filter that creates the resource URL and 
-- resource galleries URL for DOI registration in Crossref. The script uses the metadata fields to
-- build the URLs. 

local stringify = pandoc.utils.stringify

-- table with file properties according to the gallery type
local file_property = {
    pdf = "application/pdf",
    html = "text/html",
    xml = "application/xml",
    epub = "application/epub+zip"
}

-- pattern_match(m) --------------------------------------------------------------------------------------
-- Description: [en] Take 'meta' and generate a table with patterns and values for the construction 
--                     of the URL of the resource.
--				[es] Toma 'meta' y genera una tabla con patrones y valores para la construcción de
--                     la URL del recurso.
-- Return: [en] A table with patterns and values for the construction of the URL of the resource. 
--                The table contains the following fields:
--                p: pattern;
--                v: value to be used as replacement;
--                t: field description.
--		   [es] Una tabla con patrones y valores para la construcción de la URL del recurso. La
--                tabla contiene los siguientes campos:
--                p: patrón;
--                v: valor a ser usado como reemplazo;
--                t: descripción de campo.

local function pattern_match(m)

    return {
        {p = '%%v', v = m.volume,                                t = 'volumen'},
        {p = '%%i', v = m.issue,                                 t = 'issue'},
        {p = '%%Y', v = m.year,                                  t = 'year'},
        {p = '%%a', v = m.article.ojs_id,                        t = 'ojs id'},
        {p = '%%p', v = {m.article.fpage, "-", m.article.lpage}, t = 'pages'},
        {p = '%%e', v = m.article['elocation-id'],               t = 'elocation id'},
        {p = '%%x', v = m.article['publisher-id'],               t = 'publisher id'},
        {p = '%%D', v = m.journal.doi_prefix,                    t = 'DOI prefix'},
        {p = '%%d', v = m.doi_register.doi_suffix,               t = 'DOI suffix'}--,
            }
end

-- resource_builder(constructor, pattern) --------------------------------------------------------------------------------------
-- Description: [en] Take a string with a constructor and a table with patterns and values
--                      and return a string with the values replaced.
--				[es] Toma una cadena con un constructor y una tabla con patrones y valores
--                      y devuelve una cadena con los valores sustituidos.
-- Return: [en] A url string based on the constructor, with the values replaced.
--		   [es] Una cadena url basado en el constructor, con los valores sustituidos.

local function resource_builder(constructor, pattern)

    local res_url = constructor
    for i = 1, #pattern do
        if res_url:match(pattern[i].p) then

            if not pattern[i].v then
                error('ERROR: "' ..  
                pattern[i].t .. '" ' ..
                        'is not present in the metadata, but is indicated as a pattern' .. 
                        'in doi_suffix_constructor ("' .. pattern[i].p .. '")\n')
            end
            
            res_url = res_url:gsub(pattern[i].p, stringify(pattern[i].v))
        end
    end

    return res_url
end

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Build (a) the URL of the resource; (b) the URL of the galleries of the resource; and
--                      (c) the URL for text mining.
--				[es] Construye (a) la URL del recurso; (b) las URL de las galeradas del recurso; y 
--                      (c) las URL para minería de texto.
-- Return: [en] Modified meta. The URL of the resource and the URL of the galleries of the resource
--                are added within 'doi_register' and 'doi_register.gallery_resources'. Also, a
--                'text_mining' table is added with url and file type for text mining.
--		   [es] Meta modificado. Se agrega la URL del recurso y la URL de las galeradas del recurso 
--                dentro de 'doi_register' y 'doi_register.gallery_resources'. También se agrega
--                tabla 'text_mining' con url y tipo de archivo para minería de texto.

function Meta(meta)

    local galleries = {}
    if meta.article.resources then
        for i, res in pairs(meta.article.resources) do
            galleries[i] = res["gallery-id"]
        end
    end

    -- (a) Resource URL builder
    local resource_url
    local resource_pattern = pattern_match(meta)

    if meta.article.resource_url then
        -- use predefined resource url
        resource_url = meta.article.resource_url
        warn('NOTE: Custom resource url is used (' .. stringify(resource_url) .. '). ' ..
             'No patterns are used for its construction.\n')
    else    
        -- use resource url builder
        local resource_constructor = stringify(meta.doi_register.resource_url_constructor)
        
        resource_url = resource_builder(resource_constructor, resource_pattern)
    end

    meta.doi_register.resource_url = resource_url
    table.insert(resource_pattern, {p = "%%R", v = resource_url, t = "resource URL"})
    
    -- Gallery URL and text mining
    local gallery_constructor = stringify(meta.doi_register.gallery_url_constructor) or nil
    local tm = {}
    
    if meta.doi_register.gallery_resources then
        for _, gallery_res in ipairs(meta.doi_register.gallery_resources) do
            
            local res_type = stringify(gallery_res.type)
            local gallery_url

            -- (b) Resource galleries URL builder
            
            if meta.article.resources and
                meta.article.resources[res_type] and
                meta.article.resources[res_type].url then

                    -- use custom resource galleriy url
                    gallery_url = meta.article.resources[res_type].url

            else
                    -- use resource gallery url builder:
                    -- if not 'gallery_res.gallery_url_constructor': then use 'gallery_constructor' (common for all galleries)
                    gconstructor = stringify(gallery_res.gallery_url_constructor or gallery_constructor)
                    if not gconstructor then
                        error('ERROR: "doi_register.gallery_url_constructor" or ' .. 
                                '"doi_register.gallery_resources.' .. res_type .. 
                                '.gallery_url_constructor"' .. 
                                'may be defined in the metadata')
                    end

                    -- insert gallery id (%g) and resource type gallery (%t) in the pattern table ('resource_pattern')
                    table.insert(resource_pattern, {p = "%%g", v = galleries[res_type], t = "Gallery ID"})
                    table.insert(resource_pattern, {p = "%%t", v = gallery_res.type, t = "Resource type"})

                    gallery_url = resource_builder(gconstructor, resource_pattern)
                    
                    table.remove(resource_pattern)
                    table.remove(resource_pattern)
            end

            gallery_res.gallery_url = gallery_url
    
            -- (c) Text mining table
            if gallery_res.tm then
                table.insert(tm, {url = gallery_url, 
                                  prop = file_property[res_type]})
            end
        end

        if next(tm) then
            meta.doi_register.text_mining = tm
        end
    end
    
    return meta

end