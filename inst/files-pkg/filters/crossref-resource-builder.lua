--- crossref-resource-builder - Create resource URL and resource file URL for DOI registration in Crossref.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref-resource-builder.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

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
        -- {p = '%%f', v = nil,                                     t = 'file id'},
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
-- Description: [en] 
--				[es] Construye la URL del recurso y la URL de los archivos del recurso.
-- Return: [en] 
--		   [es] 

function Meta(meta)
    
    
    -- print(art_res)
    -- for i, res in pairs(meta.article.resources) do

    --     print(i, res)
    --     for j, res_file in pairs(res) do
    --         print(j, res_file)
    --     end
        
    -- end

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
    
    -- (b) Resource file URL builder
    table.insert(resource_pattern, {p = "%%R", v = resource_url, t = "resource URL"})
    
    local file_constructor = nil
    if meta.doi_register.file_url_constructor then
        file_constructor = stringify(meta.doi_register.file_url_constructor)
    end
    
    -- local article_resources = meta.article.resources
    local tm = {}
    
    if meta.doi_register.resource_files then
        for i, res_file in ipairs(meta.doi_register.resource_files) do

            -- TODO:
            -- * agregar fiel_name (%f) a la tabla de patrones si esta en article.resources[tipo].file_name (deberia ser file_number)	
            -- * usar article.resources[tipo].url como url del archivo si esta presente.
            --
            -- if article_resources and article_resources[stringify(res_file.type)] then
            --     print(stringify(res_file.type), article_resources[stringify(res_file.type)])
            -- end
            
            -- if not 'res_file.file_url_constructor': then use 'file_constructor'
            file_constructor_i = stringify(res_file.file_url_constructor or file_constructor)

            table.insert(resource_pattern, {p = "%%t", v = res_file.type, t = "resource type file"})
            local file_url = resource_builder(file_constructor_i, resource_pattern)
            table.remove(resource_pattern)

            res_file.file_url = file_url
    
            -- Add text mining information
            if res_file.tm then
                tm[i] = {url = file_url, 
                         prop = file_property[stringify(res_file.type)]}
            end
        end
        if next(tm) then
            meta.doi_register.text_mining = tm
        end
    end
    
    return meta

end