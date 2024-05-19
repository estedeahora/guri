--- include-float.lua – filter to include float elements (pandoc.CodeBlock) from float flags
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/include-float.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
-- The include-float.lua is a Pandoc Lua filter that includes float elements (pandoc.CodeBlock)
-- from float flags. The filter detects floating element markers in blocks ("^~!include=FIG..." |
-- "^~!include=TAB...") and replaces these markers by 'pandoc.CodeBlock' type blocks with the 
-- elements that define a floating element. The filter also adds float counters ('n_figs' and
-- 'n_tabs') and elements quoted within float element paratexts ('nocite') in the metadata.

local contador_tab = 0        --Initialise table counters
local contador_fig = 0        --Initialise figure counters
local root = "./float/"
local nocite = {}

local stringify = pandoc.utils.stringify
local text = pandoc.text
local CodeBlock = pandoc.CodeBlock
local concat = table.concat

-- exists(path) ----------------------------------
-- Description: [en]  Identifies if the directory 'path' exists (must be entered as './path/')
--              [es] Identifica si existe el directorio 'path' (debe ingresarse como './path/')
-- Return: true / nill

local function exists(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
     if code == 13 then
        -- Permission denied, but it exists
        return true
     end
  end
  return ok, err
end

-- is_float_element(el) -------------------------------------------------
-- Description: [en] Detects floating element markers in blocks ("^~!include=FIG..." | "^~!include=TAB...")
--              [es] Detecta marcadores de elementos flotantes en bloques ("^~!include=FIG..." | "^~!include=TAB...")
-- Return: 'FIG' / 'TAB' / nill

local function is_float_element(el)

  local res = ''

  if el:match('^~!include=' .. 'FIG' .. '_[0-9][0-9].*') then
      res = 'FIG'
  elseif el:match('^~!include=' .. 'TAB' .. '_[0-9][0-9].*') then
      res = 'TAB'
  else
      res = nil
  end

  return res
end

-- mark_cite(inline) -----------------------------------------------------------------
-- Description: [en] Identifies Inline of type 'Cite' and obtains markup formatting for citations  
--                     within floats

--              [es] Identifica Inline de tipo 'Cite' y obtiene formato de marcado para citas dentro 
--                     de flotantes.
-- Return: [en] Original inline element modified to contain citation marker in place of pandoc.Cite element. 
--                 The citation marker has the form "[{prefix}{@id}{suffix}]{cita textual}". Cited elements 
--                 within the floating element paratext are added to 'nocite'.
--         [es] Elemento inline original modificado para contener marcador de cita en lugar de elemento 
--                 pandoc.Cite. El marcador de cita tiene la forma: "[{prefix}{@id}{suffix}]{cita textual}".
--                 Se agregan elementos citados dentro del paratexto del elemento flotante a 'nocite'.

local function mark_cite(inline)
  if inline.t == 'Cite' then

    local cita = {}
    local textual = stringify(inline)
    
    for i = 1, #inline.citations, 1 do

      local cita_i = inline.citations[i]

      if #inline.citations == 1 or i == #inline.citations then
        cita_textual = textual
        concatenador = ""
      elseif i ~= #inline.citations then
        cita_textual = textual:match(".-;"):gsub(";", "")
        textual = textual:gsub(".-;", "")
        concatenador = "; "
      end

      cita[i] = '[{' .. stringify(cita_i.prefix) .. 
                                '}{@' .. cita_i.id .. 
                                '}{' .. stringify(cita_i.suffix) .. '}]{' .. 
                                cita_textual ..'}' .. concatenador

      -- Add element id to the nocite list (to include it in references)
      table.insert(nocite, '@' ..  cita_i.id) 

    end
    inline = concat(cita, "")
  end
  return(inline)
end

-- detect_meta(marcador, detect, detect_post) ---------------------------------------------------
-- Description: [en] Takes a Str with a float flag and identifies the requested content type ('detect'), 
--                     without the subsequent content.
--              [es] Toma un Str con un marcador de float e identifica el tipo de contenido solicitado 
--                     ('detect'), sin el contenido posterior.
-- Return: [en] String with the searched content ('detect') without markers
--         [es] Cadena de texto con el contenido buscado ('detect') sin marcadores.
-- @example: 
--    marcador:     '~!include=FIG_01 ~!=title=Este es el título ~!source=Elaboración propia ~!note=Esta es una nota'
--    detect:       'title'
--    post_detect:  'post_detect'
--    --> Este es el título

local function detect_meta(marcador, detect, detect_post)
  local res = marcador:match('~!' .. detect .. '=.*')

  if res == nil then 
    res = ""
  else
    res = res:gsub('~!' .. detect .. '=', ''):gsub('~!' .. detect_post .. '=.*', ''):gsub('%s*$', '')
  end

  return res
end

-- meta_float(marcador) ---------------------------------------------
-- Description: [en] Take a Str with figure marker and identify its meta-elements (title, source and notes).
--              [es] Toma un Str con marcador de figuras e identifica sus meta-elementos (título, fuente y notas).
-- Return: [en] List with three pandoc.String {title, source, note}.
--         [es] Lista con tres pandoc.String {title, source, note}.
-- @example: 
--    marcador: '~!include=FIG_01 ~!=title=Este es el título ~!source=Elaboración propia ~!note=Esta es una nota'
--    --> {title = "Este es el título", source = "Elaboración propia", note = ""}

local function meta_float(marcador)

  local title = detect_meta(marcador, "title", "source")
  local source = detect_meta(marcador, "source", "note")
  local note = detect_meta(marcador, "note", "")

  return {title = title, source = source, note = note}
end

-- Pandoc(p) ----------------------------------------------------------------------
-- Description: [en] Walk through the Blocks looking for floating element markers, to replace
--                     these markers by 'pandoc.CodeBlock' type blocks with the elements that
--                     define a floating element.
--              [es] Recorre los Blocks buscando marcadores de elementos flotantes, para 
--                     reemplazar estos marcadores por bloques de tipo 'pandoc.CodeBlock' 
--                     con los elementos que definen un elemento flotante.
-- Return: [en] 'pandoc' document modified. In blocks, float element markers are replaced by 
--                'pandoc.CodeBlock' elements with attributes defining floats. In addition, 
--                float counters ('n_figs' and 'n_tabs') and elements quoted within float element 
--                paratexts ('nocite') are added in the metadata. 
--         [es] 'pandoc' document modificado. En bloques se reemplazan marcadores de elementos 
--                flotantes por elementos 'pandoc.CodeBlock' con los atributos que definen a 
--                los floats. Además se agrega en los metadatos contadores de floats ('n_figs'
--                y 'n_tabs') y elementos citados dentro de los paratextos de elementos 
--                flotantes ('nocite'). 

function Pandoc(p)
  
  -- If floats exist in float './float/', then map blocks. See 'exists(path)' definition above.
  if exists(root) then
    
    -- Get set of blocks ('blocks')
    local blocks = p.blocks
    -- Get list of files in './float/' ('archivos')
    local archivos = pandoc.system.list_directory(root)

    for i = 1, #blocks, 1 do
      
      local bloque = blocks[i]
    
      -- Get textual content from the block ('contenido')
      local contenido = stringify(bloque)

      -- Detects floating element flags in blocks ('bloque_float'). Then  Filter blocks with floats flags.
      -- See 'is_float_element(el)' definition above.
      local bloque_float = is_float_element(contenido)

      if bloque_float then    

        -- Define 'label' (e.g. FIG_01) 
        local label = contenido:match('^~!include=' .. bloque_float .. '_[0-9][0-9]'):gsub("^~!include=", "")

        -- [en] Modifies content of blocks to change citation elements (.t == Cite) to citation in the form marckdown ("[@key]")
        -- [es] Modifica contenido de los bloques para cambiar los elementos de citas (.t == Cite) por citas en la forma marckdown ("[@clave]")
        local contenido = stringify(bloque.content:map(mark_cite))    -- See 'mark_cite(inline)' definition above.
        
        -- Gets figure metadata (title, source and notes). See 'meta_float(marcador)' definition above.
        local float_meta = meta_float(contenido)             

        -- Creates code block (pandoc.CodeBlock) with float element attributes.
        blocks[i] = CodeBlock("", 
                              {id = label, 
                                class = bloque_float, 
                                title = float_meta.title, 
                                source = float_meta.source, 
                                note = float_meta.note}
                              )

        if bloque_float == "FIG" then           -- Modify blocks with figures
          
          contador_fig = contador_fig + 1
          
          blocks[i].attributes.fignum = contador_fig

          -- Identifies "path" to the figure
          local path_fig = ''
          for i = 1, #archivos, 1 do
            local float_file = archivos[i]:match(label .. '.[a-z]+')
            if float_file then
              path_fig = root .. float_file
            end
          end

          blocks[i].attributes.path = path_fig


        elseif bloque_float == "TAB" then       -- Modify blocks with tables

          contador_tab = contador_tab + 1

          blocks[i].attributes.tabnum = contador_tab
          
        end
      end
    end
  else
    print("The folder './float/' does not exist.\n")
  end

  p.meta.n_figs = contador_fig
  p.meta.n_tabs = contador_tab

  -- Adds nocite elements
  if nocite ~= nil then
    p.meta.nocite = CodeBlock(concat(nocite, ", "))
  end
  
  return p  
end
