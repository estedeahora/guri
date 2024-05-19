--- crossref-citation - Generates each reference in CrossRef format.
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/crossref-citation.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The crossref-citation.lua is a Pandoc Lua filter that generates each reference in CrossRef 
-- format. The references are placed inside <citation> elements.


local RawBlock = pandoc.RawBlock
local stringify = pandoc.utils.stringify
local citeproc = pandoc.utils.citeproc

-- plain_citation(document) ------------------------------------------------------------------------
-- Description: [en] Generates a table with formatted citations according to the csl.
--				[es] Genera una tabla con las citas formateadas según el csl.
-- Return: [en] A table with formatted citations (in the form id = formatted citation).
--		   [es] Una tabla con las citas formateadas (de la forma id = cita formateada).

function plain_citation(document)

    local doc_copy = citeproc(document)
    local table_citation = {}

    for _, b in ipairs(doc_copy.blocks) do
        -- identify the reference div
        if b.t == "Div" and b.identifier == "refs" then
            -- get the content of the reference div 
            for _, cite in ipairs(b.content) do
                table_citation[cite.identifier] = stringify(cite):gsub('&', '&amp;')
            end
        end
    end

    return table_citation
end

-- Meta(m) --------------------------------------------------------------------------------------
-- Description: [en] Generates each reference in CrossRef format (inside <citation>).
--				[es] Genera cada referencia en el formato de CrossRef (dentro de <citation>). 
-- Return: [en] The document encoded with a table (inside doc.meta.ref) containing a pandoc.RawBlock
--               with each reference in CrossRef format.
--		   [es] El documento codificado con una tabla (dentro de doc.meta.ref) que contiene un 
--               un pandoc.RawBlock con cada referencia en el formato de CrossRef.

function Pandoc(doc)

    local refs = doc.meta.references
    
    if not refs then
        return doc
    end

    -- make a table with formatted citations (key = id; value = formatted citation)
    local formated_citation = plain_citation(doc)
    
    -- Convert references into crossref citation format (inside <citation>)
    local refs4crossref = {}
    local citation = ''

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

        -- add <unstructured-citation> (from block)
        if formated_citation['ref-' .. id] then
            citation = citation .. '<unstructured_citation>' .. formated_citation['ref-' .. id] .. '</unstructured_citation>\n'
        end
        citation = citation .. '</citation>'
        
        refs4crossref[k] = RawBlock('jats', citation)      

    end
    
    doc.meta.refs4crossref = refs4crossref

    return doc
end