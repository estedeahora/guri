--- metadata-div-before-bib.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/credit-before-bib.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
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
-- Toma un objeto del tipo Meta.author y devuelve  los datos de credit dentro de un Div con 
--     ID "credit" y class "paratext". El contenido de este Div está formateados de la forma:
--     "**Apellido:** Rol1 (rol_english); Rol2 (rol_english). **Apellido:** Rol1 (rol_english); Rol2 (rol_english)."

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
-- Obtiene la metadata necesaria para incorporar como Div al final (antes de las referencias)

local function get_metadata(meta)
  
    if(meta.credit) then        
        cont_credit = credit_Div(meta.author)
    else
        io.stderr:write("\nSin datos de credit.\n")
    end

    if(meta.ack) then
        cont_ack = Div(Para(meta.ack), {id = "Ack", class = "Paratext"})
    end

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

-- Agrega credit antes de referencias
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

-- Agrega credit al final para artículos sin referencias
function add_metadata2(doc) 

  if(with_ref == nil and cont_credit) then

    io.stderr:write("\nSin referencias bibliográficas.\n")

    doc.blocks:extend({cont_credit, cont_ack, cont_app})
  
  end

  return doc

end

return {{Meta = get_metadata}, {Header = add_metadata1}, {Pandoc = add_metadata2}}