--- metadata-div-before-bib.lua – filter to include credit, acknowledgements and appendices as div blocks before references (or at the end)
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/metadata-div-before-bib.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local lower = pandoc.text.lower
local concat = table.concat

local Str = pandoc.Str
local Strong = pandoc.Strong

local Para = pandoc.Para
local Div = pandoc.Div
local RawBlock = pandoc.RawBlock
local CodeBlock = pandoc.CodeBlock

local cont_credit = ''
local cont_ack = ''
local cont_app = ''
local with_ref = nil

--  credit_Div(aut) ------------------------------------------------------------------------------------------
-- Description: [en] Takes a Meta.author and returns a string with the credit data information inside a pandoc.Div.
--              [es] Toma un Meta.author y devuelve una cadena de texto con los datos de credit dentro de un pandoc.Div.
-- Return: [en] A string inside a pandoc.Div with ID="credit" and class="paratext", formated as:
--         [es] Una cadena de texto dentro de un pandoc.Div con ID="credit" y class="paratext", formateado de la forma:
-- 
-- div{ID = "credit", class = "paratext"}
-- **Surname:** rol1_spanish (rol1_english); rol2_spanish (rol2_english). **Surname:** rol1_spanish (rol_english); rol2_spanish (rol2_english).

local function credit_Div(aut)

    local credit_text = {}
    
    for i, aut_i in pairs(aut) do

        local aux_rol = ''

        for k, rol_i in pairs(aut_i.credit) do
            
            aux_rol = aux_rol .. stringify(rol_i.cont) ..  " (" .. stringify(rol_i.elem) .. ")"

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

-- get_metadata() --------------------------------------------------------------------------------------
-- Description: [en] Gets the metadata about (a) credit, (b) acknowledgements and (c) appendices, adding each of these 
--                      elements as a text string inside a pandoc.Div at the end of the text (before references).
--              [es] Obtiene la metadata de (a) credit, (b) agradecimientos y (c) anexos, agregando cada uno de estos 
--                      elementos como una cadena de texto dentro de un pandoc.Div al final del texto (antes de las referencias)
-- Return: [en] 
--         [es] Meta con elementos credit, ack y appendix modificados (si están presentes en meta). Los elemento credit y ack
--                  son una cadena de texto dentro de un pandoc.Div con ID="credit"/"ack" y class="paratext". Los elementos
--                  appendix formateado de la forma: 
--

local function get_metadata(meta)
  
    -- Credit info
    if(meta.credit) then        
        cont_credit = credit_Div(meta.author)
    else
        io.stderr:write("\nSin datos de credit.\n")
    end

    --- Acknowledgements
    if(meta.ack) then
        cont_ack = Div(Para(meta.ack), {id = "Ack", class = "Paratext"})
    end

    -- Appendices
    if(meta.appendix) then
        -- local app = nil
        if(type(meta.appendix) == "string") then
            cont_app = meta.appendix
        else
            cont_app = concat(meta.appendix, "\n")
        end
        
        cont_app = CodeBlock(cont_app, {class = "include", format = "markdown"})
        cont_app.attributes["shift-heading-level-by"] = 0

        meta.appendix = cont_app
        cont_app = Div(cont_app, {id = "app", class = "Paratext"})
    end
end

-- add_metadata1(h) & add_metadata2(doc) ------------------------------------------------------------------
-- Description: [en] Add multiple pandoc.div with credit metadata and acknowledgements  (if any) 
--                      before references (add_metadata1) or at the end for articles without references (add_metadata2).
--                      Also, add the appendices (if any) in a pandoc.div at the end of the text.
--              [es] Agrega múltiples pandoc.div con metadata de credit y agradecimientos (si la hubiera) 
--                      antes de las referencias (add_metadata1) o al final para artículos sin referencias (add_metadata2).
--                      Además, agrega los anexos (si los hubiera) en un pandoc.div al final del texto.
-- Return: [en]  Modify the block content of the pandoc object by adding in order blocks of the pandoc.div class for credit, acknowledgements, bibliography and appendices (if present).
--         [es] Modifica el contenido de bloques del objeto pandoc agregando en orden bloques de la clase pandoc.div para credit, agradecimientos, bibliografía y apéndices (los que están presentes).

function add_metadata1(h) 

  local s = lower(stringify(h))
  s = s:gsub("%s*$", "")

  if(s == "referencias bibliográficas") then

    local res = {cont_credit, cont_ack, h, 
                RawBlock('markdown', '::: {#refs}\n:::'),
                cont_app 
                } 
    with_ref = true

    return(res)

  end

end

function add_metadata2(doc) 

  if(with_ref == nil and (cont_credit or cont_ack or cont_app)) then

    io.stderr:write("\nArticle without references.\n")

    doc.blocks:extend({cont_credit, cont_ack, cont_app})
  
  end

  return doc

end

return {{Meta = get_metadata}, {Header = add_metadata1}, {Pandoc = add_metadata2}}