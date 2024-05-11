--- metadata-div-before-bib.lua – filter to include credit, acknowledgements and appendices as div blocks before references (or at the end)
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/metadata-div-before-bib.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local Str = pandoc.Str
local Strong = pandoc.Strong

local Para = pandoc.Para
local Div = pandoc.Div
local Header = pandoc.Header
local RawBlock = pandoc.RawBlock
local CodeBlock = pandoc.CodeBlock

local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower
local concat = table.concat

local n_refs = 0

local references_title

local cont_credit = ''
local cont_funding = ''
local cont_data = ''
local cont_coi = ''
local cont_ack = ''
local cont_app = ''


--  credit_Div(aut, lang) ------------------------------------------------------------------------------------------
-- Description: [en] Takes a Meta.author and returns a string with the credit data information inside a pandoc.Div.
--              [es] Toma un Meta.author y devuelve una cadena de texto con los datos de credit dentro de un pandoc.Div.
-- Return: [en] A string inside a pandoc.Div with ID="credit" and class="paratext", formated as:
--         [es] Una cadena de texto dentro de un pandoc.Div con ID="credit" y class="paratext", formateado de la forma:
-- 
-- div{ID = "credit", class = "paratext"}
-- **Surname:** rol1_main_lang (rol1_english); rol2_main_lang (rol2_english). **Surname:** rol1_main_lang (rol_english); rol2_main_lang (rol2_english).
--
-- Note: [en] If main_lang = 'en' → **Surname:** rol1_english; rol2_english. **Surname:** rol_english; rol2_english.
--       [es] Si main_lang = 'en' → **Surname:** rol1_english; rol2_english. **Surname:** rol_english; rol2_english.

local function credit_Div(aut, lang)

    local credit_text = {}

    for i, aut_i in pairs(aut) do

        local aux_rol = ''

        for k, rol_i in pairs(aut_i.credit) do
            
            if lang:match('^en') then
                aux_rol = aux_rol .. stringify(rol_i.elem)
            else
                aux_rol = aux_rol .. stringify(rol_i.cont) ..  " (" .. stringify(rol_i.elem) .. ")"
            end

            if k ~= #aut_i.credit then 
                aux_rol = aux_rol .. "; "
            else
                aux_rol = aux_rol .. ". "
            end
        end

        credit_text[#credit_text + 1] = Strong(stringify(aut_i.surname) .. ":")
        credit_text[#credit_text + 1] = Str(" " .. aux_rol)   

    end

    local res = Div(Para(credit_text), {id = "Credit", class = "Paratext"})

    return(res)

end

-- get_metadata(meta) --------------------------------------------------------------------------------------
-- Description: [en] Gets the metadata about (a) credit, (b) acknowledgements and (c) appendices, adding each of these 
--                      elements as a text string inside a pandoc.Div at the end of the text (before references).
--              [es] Obtiene la metadata de (a) credit, (b) agradecimientos y (c) anexos, agregando cada uno de estos 
--                      elementos como una cadena de texto dentro de un pandoc.Div al final del texto (antes de las referencias)
-- Return: [en]  Modified meta, adding credit, ack and appendix elements (depending on which are present in meta). The credit
--                  and ack elements are a text string inside a pandoc.Div with ID="credit"/"ack" and class="paratext". The 
--                  appendix elements (as a whole) are placed inside a pandoc.Div (ID="apps" and class="paratext"), 
--                  containing in turn a pandoc.Div (ID="app" and class="paratext") containing a pandoc.CodeBlock with
--                  the path to the md-file containing the appendix (class = "include", format = "markdown", "shift-heading-level-by" = 0).
--         [es] Meta Modificado, agregando  elementos credit, ack y appendix (dependiendo de cuáles  están presentes en meta).
--                  Los elemento credit y ack son una cadena de texto dentro de un pandoc.Div con ID="credit"/"ack" y 
--                  class="paratext". Los elementos de appendix (en conjunto) se colocan dentro de un pandoc.Div (ID="apps" 
--                  y class="paratext"), conteniendo a su vez un pandoc.Div (ID="app" y class="paratext") que contiene un 
--                  pandoc.CodeBlock con el path al archivo md que tiene el apéndice (class = "include", format = "markdown",
--                  "shift-heading-level-by" = 0).


local function get_metadata(meta)
  
    -- Credit info
    if meta.credit then        
        cont_credit = credit_Div(meta.author, stringify(meta.lang))
    end

    if meta.statements then
       --- funding info
        if meta.statements.funding and meta.statements.funding.text then
            cont_funding = Div(Para(meta.statements.funding.text), {id = "Funding", class = "Paratext", title = meta.statements["funding-title"]})
        end

        -- data availability info
        if meta.statements.data and meta.statements.data.text then
            cont_data = Div(Para(meta.statements.data.text), {id = "Data", class = "Paratext", title = meta.statements["data-title"]})

            cont_data.attributes["url"] = meta.statements.data.url and stringify(meta.statements.data.url)
            cont_data.attributes["doi"] = meta.statements.data.doi and stringify(meta.statements.data.doi)

        end

        -- COI info
        if meta.statements.coi then
            cont_coi = Div(meta.statements.coi, {id = "COI", class = "Paratext", title = meta.statements["coi-title"]})
        end

        --- Acknowledgements info
        if meta.statements.ack then
            cont_ack = Div(meta.statements.ack, {id = "Ack", class = "Paratext", title = meta.statements["ack-title"]})
        end
        -- meta.statements = pandoc.utils.from_simple_table(meta.statements)
    end
    

    -- Appendices info
    if meta.appendix then

        local app_file

        if(type(meta.appendix) == "string") then
            app_file = {meta.appendix}
        else
            app_file = meta.appendix
        end
        
        local all_app = {}

        for i = 1, #app_file, 1 do

            local single_app

            single_app = CodeBlock(app_file[i], {class = "include", format = "markdown"})
            single_app.attributes["shift-heading-level-by"] = 0

            all_app[i] = Div(single_app, {class = "app"})
        end

        meta.appendix = app_file
        cont_app = Div(all_app, {id = "apps", class = "Paratext"})

    end

    -- References info
    if meta.references then
        -- References count
        n_refs = #meta.references

        -- Reference title
        if meta['references-title'] then
            references_title = stringify(meta['references-title']) 
        end
    end

    meta.n_refs = n_refs
    
    return meta

end

-- add_metadata(block) ------------------------------------------------------------------
-- Description: [en] Add multiple pandoc.divs with credit metadata and acknowledgements (if any)  before references
--                      or at the end (for articles without references). Also, add annexes (if any) in a pandoc.div 
--                      at the end of the text.
--                     Also, add the appendices (if any) in a pandoc.div at the end of the text.
--              [es] Agrega múltiples pandoc.div con metadata de credit y agradecimientos (si la hubiera) antes
--                     de las referencias o al final (para artículos sin referencias). Además, agrega los anexos
--                     (si los hubiera) en un pandoc.div al final del texto.
-- Return: [en] A modified pandoc document, adding the contents of the pandoc.div class blocks for credit, 
--                acknowledgements, title references, references and appendices (if present).
--         [es] Un documento de pandoc modificado, agregando el contenido de los bloques de clase pandoc.div 
--                para credit, agradecimientos, título de referencias, referencias y apéndices (los que 
--                estubieran presentes).

function add_metadata(doc)

    local blocks = doc.blocks
    local last_block = blocks[#blocks]

    if last_block.t == "Header" then

        if n_refs > 0 then    
            
            local lang = stringify(doc.meta.lang)

            references_title = stringify(last_block):gsub("%s*$", "")
            blocks[#blocks] = nil

            if references_title then
                warn('WARNING: The article language ("' .. lang .. '") has a defined title ' .. 
                        'for references, but the last element is a Header#1: this header is ' .. 
                        'used instaed of the predefined title for the references (content: "' .. 
                        references_title .. '").\n')
            else
                warn('WARNING: The article language ("' .. lang .. '") has no predefined title' .. 
                                'for references and no customized.reference_title is provided,' .. 
                                'but the last element is a Header#1: this header is used as the ' .. 
                                'title of references (content: "' .. references_title .. '").\n')
            end
        
        else
            error('ERROR: There is zero references, but there is a Header#1 in the last Block.')
        end
    end

    if n_refs == 0 then

        warn('NOTE: Article without references.\n')

        doc.blocks:extend({cont_credit, cont_data, cont_funding, cont_coi, cont_ack, cont_app})
    
    else

        if not references_title then
            error('ERROR: No predefined title for "references".')
        elseif references_title == "" then
            error('ERROR: References title is empty.')
        end

        blocks:extend({cont_credit, cont_data, cont_funding, cont_coi, cont_ack,
                        Header(1, references_title),
                        RawBlock('markdown', '::: {#refs}\n:::'),
                        cont_app})
    end

    return doc

end

return {
    {Meta = get_metadata}, 
    {Pandoc = add_metadata}
}
