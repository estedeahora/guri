--- include-float.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/include-float.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local stringify = pandoc.utils.stringify
local text = pandoc.text
local root = "./float/"
local nocite = {}

--Inicializar contadores de tablas y figuras
local contador_tab = 0
local contador_fig = 0

-- exists(path) ----------------------------------
-- Identifica si existe el directorio 'path' (debe ingresarse como './path/')
-- Return: true o nill

function exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
     if code == 13 then
        -- Permission denied, but it exists
        return true
     end
  end
  return ok, err
end

-- is_float_element(el) -------------------------------------------------
-- Detecta marcadores de elementos flotantes en bloques ("^~!include=FIG" | "^~!include=TAB")
-- Return: 'FIG' / 'TAB' / nill

function is_float_element(el)
    if el:match('^~!include=' .. 'FIG' .. '_[0-9][0-9].*') then
        res = 'FIG'
    elseif el:match('^~!include=' .. 'TAB' .. '_[0-9][0-9].*') then
        res = 'TAB'
    else
        res = nil
    end
    return res
end

-- mark_cite(path) ----------------------------------
-- Identifica Inline de tipo "Cite" y obtiene formato de marcado para citas de la forma: "[{prefix}{@id}{suffix}]{cita textual}"
-- Return: inline

function mark_cite(inline)
  if inline.t == 'Cite' then
    
    local cite = inline.citations[1]
    local inline = pandoc.Str('[{' .. stringify(cite.prefix) .. 
                              '}{@' .. cite.id .. 
                              '}{' .. stringify(cite.suffix) .. '}]{' .. 
                              stringify(inline) ..'}')

    -- Agrega id del elemento a la lista nocite (para incluirlo en referencias)
    table.insert(nocite, '@' ..  cite.id) 

  end
  return(inline)
end

-- meta_float(marcador) ---------------------------------------------
-- Toma un Str con marcador de figuras e identifica sus meta-elemtnos (título, fuente y notas).
-- Return: lista con tres Str {title, source, note}
-- Ejemplo: 
--    marcador:      '~!include=FIG_01 ~!=title=Este es el título ~!source=Elaboración propia ~!note=Esta es una nota'
--    -> {Este es el título, Elaboración propia, ""}

function meta_float(marcador)

  title = detect_meta(marcador, "title", "source")
  source = detect_meta(marcador, "source", "note")
  note = detect_meta(marcador, "note", "")

  return {title = title, source = source, note = note}
end

-- detect_meta(marcador) ---------------------------------------------
-- Toma un Str con marcador de figuras e identifica el contenido (detect)
-- Return: Str con el contenido buscado (detect) sin marcadores
-- Ejemplo: 
--    marcador:      '~!include=FIG_01 ~!=title=Este es el título ~!source=Elaboración propia ~!note=Esta es una nota'
--    detect:        'title'
--    post_detect:   'post_detect'
--    -> Este es el título

function detect_meta(marcador, detect, detect_post)
  res = marcador:match('~!' .. detect .. '=.*')

  if res == nil then 
    res = ""
  else
    res = res:gsub('~!' .. detect .. '=', ''):gsub('~!' .. detect_post .. '=.*', ''):gsub('%s*$', '')
  end

  return res
end


-- Recorrido de bloques para buscar figuras y tablas.  
-----------------------------------------------------
-- Recorre los Blocks buscando marcadores de elementos flotantes, para reemplazar estos marcadores por
--    bloques de tipo "CodeBlock" con los elementos que definen un elemento flotante.
-- Cuenta la cantidad de figuras y tablas (para pasarlo a los metadatos)

function Blocks(blocks)
  
  if exists(root) then

    -- print("Existe ./float/")
    -- Listar archivos con elementos flotantes
    local archivos = pandoc.system.list_directory(root)     

    for i = 1, #blocks, 1 do
      
      local bloque = blocks[i]
    
      -- Obtener contenido textual del bloque
      local contenido = stringify(bloque)

      -- Detecta marcadores de elementos flotantes en bloques    
      local bloque_float = is_float_element(contenido)

      -- -- Filtra bloques con marcador de figura
      if bloque_float then    

        -- Define label (ej: FIG_01) 
        label = contenido:match('^~!include=' .. bloque_float .. '_[0-9][0-9]'):gsub("^~!include=", "")

        -- Modifica contenido de los bloques para cambiar los elementos de citas (.t == Cite) por citas en la forma marckdown ("[@clave]")
        contenido = stringify(bloque.content:map(mark_cite))
        
        -- Obtiene metadatos de la figura (título, fuente y notas)
        float_meta = meta_float(contenido)             

        -- Crea bloque de código (CodeBlock) con elementos 
        blocks[i] = pandoc.CodeBlock("", 
                                      {id = label, 
                                       class = bloque_float, 
                                       title = float_meta.title, 
                                       source = float_meta.source, 
                                       note = float_meta.note}
                                    )

        if bloque_float == "FIG" then           -- Modifica bloques con figuras
          
          contador_fig = contador_fig + 1
          
          blocks[i].attributes.fignum = contador_fig

          -- Identiica path a la figura
          for i = 1, #archivos, 1 do
            float_file = archivos[i]:match(label .. '.[a-z]+')
            if float_file then
              path_fig = root .. float_file
            end
          end

          blocks[i].attributes.path = path_fig

          -- blocks[i] = pandoc.Image({float_meta.title}, path_fig, "",
          --                           {id = label, source = float_meta.source, note = float_meta.note} )

        elseif bloque_float == "TAB" then       -- Modifica bloques con tablas

          contador_tab = contador_tab + 1

          blocks[i].attributes.tabnum = contador_tab
          
          -- blocks[i] = pandoc.CodeBlock("", {id = label, class = bloque_float, path = path_fig, 
          --                                 title = float_meta.title, source = float_meta.source, note = float_meta.note})
        end
      end
    end
  else
    print("No existe ./float/\n")
  end
  return blocks
end


function Meta(m)
  -- Guardar número de figuras / tablas (para xml-jats)
  m.n_figs = contador_fig
  m.n_tabs = contador_tab

  -- Agrega elementos nocite
  if nocite ~= nil then
    m.nocite = pandoc.CodeBlock(table.concat(nocite, ", "))
    print( m.nocite)
  end

  
  return m
end