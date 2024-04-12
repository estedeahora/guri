--- doi-builder.lua – filter to doi construct from patterns
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/article-metadata.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify

local function Meta(meta) 

    if meta.article.doi == "none" then
        io.write("NOTE: The article has no DOI.\n")
    elseif meta.article.doi then
        meta.article.doi = journal.doi_prefix .. meta.article.doi
    else
        local doi_suffix
        print()

        doi_suffix = doi_register.doi_suffix_constructor:gsub('', '')
        meta.article.doi = journal.doi_prefix .. doi_suffix
        
    end
    

end


-- # 'doi_suffix_constructor' follows OJS conventions: 
-- #    %j journal initials (first letter of journal.title); 
-- #    %v volume nomber (volume); 
-- #    %i issue number (issue); 
-- #    %Y Year (date.year); 
-- #    %a OJS article ID (article.ojs_id); 
-- #    %p article pages (article.fpage-article.lpage).
-- # In addition, guri uses two markers that can be used more freely to customise your doi suffix: 
-- #    %n article.elocation-id; 
-- #    %x article.publisher-id. 