--- doi-builder.lua – filter to doi construct from patterns
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/article-metadata.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

local doi_match

local function pattern_match(m)

    return {
        {p = '%%v', v = m.volume, t = 'volumen'},
        {p = '%%i', v = m.issue, t = 'issue'},
        {p = '%%Y', v = m.year, t = 'year'},
        {p = '%%a', v = m.article.ojs_id, t = 'ojs id'},
        {p = '%%p', v = {m.article.fpage, "-", m.article.lpage}, t = 'pages'},
        {p = '%%n', v = m.article['elocation-id'], t = 'elocation id'},
        {p = '%%x', v = m.article['publisher-id'], t = 'publisher id'},
    
            }
end

function Meta(meta) 

    doi_match = pattern_match(meta)

    if not meta.journal.doi_prefix then 
        -- Revista sin DOI
    elseif meta.article.doi and stringify(meta.article.doi) == 'none' then
        io.write('NOTE: The article has no DOI.\n')
    elseif meta.article.doi then

        meta.article.doi = stringify(meta.journal.doi_prefix).. "/" .. stringify(meta.article.doi)
        io.write('NOTE: Custom DOI is used (' .. meta.article.doi .. '). ' ..
                 'No patterns are used for its construction.\n')

    else
        -- pattern doi constructor
        local doi_suffix

        doi_suffix = stringify(meta.doi_register.doi_suffix_constructor)

        for i = 1, #doi_match do
            if doi_suffix:match(doi_match[i].p ) then
                
                if not doi_match[i].v then
                    error('ERROR: "' ..  
                            doi_match[i].t .. '" ' ..
                            'is not present in the metadata, but is indicated as a pattern' .. 
                            'in doi_suffix_constructor ("' .. doi_match[i].p .. '")\n')
                end
                
                doi_suffix = doi_suffix:gsub(doi_match[i].p, stringify(doi_match[i].v))
            end
        end

        meta.article.doi = stringify(meta.journal.doi_prefix) .. '/' .. doi_suffix
        print(meta.article.doi)
    end
    
    return meta

end
