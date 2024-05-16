--- crossref-citation - 
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref-citation.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] 
--				[es] 
-- Return: [en] 
--		   [es] 

local stringify = pandoc.utils.stringify
local RawBlock = pandoc.RawBlock
local citeproc = pandoc.utils.citeproc

local format_citation = {}
local citation = ''

function Pandoc(doc)

    local refs = doc.meta.references
    
    if not refs then
        return doc
    end

    -- make a table with formatted citations
    local doc2 = citeproc(doc)

    for _, b in ipairs(doc2.blocks) do
        if b.t == "Div" and b.identifier == "refs" then
            
            format_citation = {}
            for k, cite in ipairs(b.content) do
                format_citation[cite.identifier] = stringify(cite)
            end
        end
    end
    
    -- Convert references into crossref citation format
    local refs2 = {}

    for k, ref in ipairs(refs) do
        local id = stringify(ref.id)

        local jrn  = stringify(ref.type) == 'article-journal'
        local conf = stringify(ref.type) == 'paper-conference'
        local chp  = stringify(ref.type) == 'chapter'
        local book = stringify(ref.type) == 'book'
        local phd  = stringify(ref.type) == 'thesis'
        local doc  = stringify(ref.type) == 'document'
        local rep  = stringify(ref.type) == 'report'

        citation = '<citation key="ref=' .. id .. '">\n'

        if jrn and ref['container-title'] then
            citation = citation .. '<journal_title>' .. stringify(ref['container-title']) .. '</journal_title>\n'
        end
        if ref['author'] then
            if ref.author[1].family then
                citation = citation .. '<author>' .. stringify(ref['author'][1].family) .. '</author>\n'    
            elseif ref.author[1].literal then
                citation = citation .. '<author>' .. stringify(ref['author'][1].literal) .. '</author>\n'    
            end
        elseif ref['editor'] then
            if ref.editor[1].family then
                citation = citation .. '<author>' .. stringify(ref['editor'][1].family) .. '</author>\n'    
            elseif ref.editor[1].literal then
                citation = citation .. '<author>' .. stringify(ref['editor'][1].literal) .. '</author>\n'    
            end
        end
        if ref['volume'] then
            citation = citation .. '<volume>' .. stringify(ref['volume']) .. '</volume>\n'
        end
        if ref['issue'] then
            citation = citation .. '<issue>' .. stringify(ref['issue']) .. '</issue>\n'
        end
        if ref['page'] then
            local pages = stringify(ref['page'])
            citation = citation .. '<first_page>' .. pages:match('[0-9]*') .. '</first_page>\n'
        end
        if ref['issued'] then
            citation = citation .. '<cYear>' .. stringify(ref['issued']) .. '</cYear>\n'
        end
        if ref['DOI'] then
            citation = citation .. '<doi>' .. stringify(ref['DOI']) .. '</doi>\n'
        end
        if (conf or chp or jrn) and ref['title'] then
            citation = citation .. '<article_title>' .. stringify(ref['title']) .. '</article_title>\n'
            if ref['container-title'] then 
                citation = citation .. '<volume_title>' .. stringify(ref['container-title']) .. '</volume_title>\n'
            end        
        elseif (book or phd or doc or rep) and ref['title'] then
            citation = citation .. '<volume_title>' .. stringify(ref['title']) .. '</volume_title>\n'
        end

        if format_citation['ref-' .. id] then
            citation = citation .. '<unstructured_citation>' .. format_citation['ref-' .. id] .. '</unstructured_citation>\n'
        end
        citation = citation .. '</citation>'
        citation = citation:gsub('&', '&amp;')
        
        refs2[k] = RawBlock('jats', citation)      

    end
    doc.meta.refs2 = refs2

    return doc
end