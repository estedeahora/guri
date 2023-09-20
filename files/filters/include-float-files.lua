--- include-float.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/include-float.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- is_float_element(el) -------------------------------------------------
-- Detecta marcadores de elementos flotantes en bloques ("^~!include=FIG" | "^~!include=TAB")
-- Return: 'FIG' / 'TAB' / nill

function is_float_element(el)
  if el:match('^~!include=' .. 'FIG' .. '_[0-9][0-9].*') then
    res = 'FIG'
  elseif el:match('^~!include=' .. 'TAB' .. '_[0-9][0-9].*') then
    res = 'TAB'
  else
    res = nill
  end
  return res
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
    res = res:gsub('~!' .. detect .. '=', ''):gsub('~!' .. detect_post .. '=.*', '')
  end

  return res
end

-- fig_latex(label, elem, root) ----------------------------------------
-- Genera un texto de código plano (RawBlock) para latex que incluye figuras
-- Return: RawBlock con ambiente figure (latex)

function fig_latex(label, elem, root)
  if elem.source ~= "" then
    source = '\\source{' ..  elem.source .. '}\n'
  else
    source = elem.source
  end

  if elem.note ~= "" then
    note = '\\notes{' ..  elem.note .. '}\n'
  else
    note = elem.note
  end

  raw_elem = '\\begin{figure}\n' ..
              '\\centering\n' .. 
              '\\includegraphics[width=0.9\\textwidth]{' .. root .. label .. '}\n' .. 
              '\\caption{' .. elem.title .. '}\n' .. 
              source .. note ..
              '\\label{' .. label .. '}\n' ..
              '\\end{figure}'
  return pandoc.RawBlock('latex', raw_elem)
end

-- fig_html(path, elem, label, fignum) ----------------------------------------
-- Genera un texto de código plano (RawBlock) para html que incluye figuras
-- Return: RawBlock con ambiente figure (html)

function fig_html(path, elem, label, fignum)
  if elem.source ~= "" then
    source = '<figcaption><em>Fuente: ' ..  elem.source .. '</em></figcaption>\n'
  else
    source = elem.source  
  end

  if elem.note ~= "" then
    note = '<figcaption>Nota: ' ..  elem.note .. '</figcaption>\n'
  else
    note = elem.note
  end

  raw_elem = '<figure id="' .. label .. '">\n' ..
              '<img src="' .. path .. '" alt="' .. label .. '"/>\n' .. 
              '<figcaption>Figura ' .. fignum .. ": " .. elem.title .. '</figcaption>\n' ..
              source .. note ..
              '</figure>'
  return pandoc.RawBlock('html', raw_elem)
end

-- fig_jats(path, elem, label, fignum) --------------------------------
-- Genera un texto de código plano (RawBlock) para jats que incluye figuras
-- Return: RawBlock con ambiente figure (jats)

function fig_jats(label, elem, fignum)
  if elem.source ~= "" then
    source = '<attrib>Fuente: ' ..  elem.source .. '</attrib>\n'
  else
    source = elem.source  
  end

  if elem.note ~= "" then
    note = '<attrib>Nota: ' ..  elem.note .. '</attrib>\n'
  else
    note = elem.note
  end

  raw_elem = '<fig id="' .. label .. '">\n' ..
              '<label>Figura ' ..  fignum .. '.</label>\n' ..
              '<caption>\n' ..
              '<p>' .. elem.title .. '</p>' .. 
              '</caption>\n' ..
              '<graphic xlink:href="'.. label .. '"/>\n' ..
              source .. note ..
              '</fig>'
  return pandoc.RawBlock('jats', raw_elem)
end

-- tab_float(tab_path, label, float_meta, fignum, format) ----------------------------------
-- Genera un texto de código plano (RawBlock) para latex/html que incluye tablas
-- Return: RawBlock con ambiente table
to_header = ''

local function tab_float(tab_path, label, float_meta, fignum, format)
  -- https://tex.stackexchange.com/questions/27097/changing-the-font-size-in-a-table
  -- Variables de formato (format_out, format_ext) y específicas de formato (tabla, to_header)
  if format:match 'latex' or format:match 'pdf' then
    format_out = 'latex'
    format_ext = '.tex'
    tabla = false
  elseif format:match 'html' or format:match 'json' then
    format_out = 'html'
    format_ext = '.' .. format_out
  elseif format:match 'jats' then
    format_out = 'jats'
    format_ext = '.html'
  else
    io.stderr:write('WARNING: "' .. format .. 
                    '" no es un formato de salida válido.' ..
                    '| Se generan tablas en formato "html".\n')
    format_out = 'html'
    format_ext = '.' .. format_out
                
  end
  
  --  Definir (a) title; (b) source y note
  local title, source, note = float_meta.title, float_meta.source, float_meta.note

  if source ~= "" then
    source = '\\source{' ..  source .. '}\n'
  end
  if note ~= "" then
    note = '\\notes{' ..  note .. '}\n'
  end

  -- Abrir conexión interna
  local raw_content = ''
  local fh = io.open(tab_path .. format_ext)

  if not fh then
    io.stderr:write('Cannot open file ' .. fh .. ' | Skipping includes\n')
  else
    for line in fh:lines('L') do
      -- Salida latex
      if format_out == 'latex'then
        -- (a) Inicio de entorno 'table' (agregar 'caption' y 'label')
        if line:match "\\begin{table}" then
          tabla = true
          raw_content = raw_content .. line .. 
                        --'\\centering\n' ..
                        '\\caption{' .. title .. '}\n' ..
                        '\\label{' .. label .. '}\n'
        -- (b) Final de entorno 'table' (agregar source y note )
        elseif line:match "\\end{table}" then
          tabla = false
          raw_content = raw_content .. source .. note .. line  
        -- (c) Contenido de entorno 'table'        
        elseif tabla then
          raw_content = raw_content .. line
        -- (d) Incluir en header
        else
          line = line:gsub('%%.*', ''):gsub('\\documentclass{.*', ''):gsub('\\begin{document}.*', ''):gsub('\\end{document}.*', '')
          to_header = to_header .. line
        end
      -- Salida html
      elseif format_out == 'html' then -- or format == 'jats_publishing' then
        raw_content = raw_content .. line
      -- Salida jats
      elseif format_out == 'jats' then 
        raw_content = raw_content .. line:gsub('<br>', '<break/>'):gsub('<br/>', '<break/>'):gsub(
                                                '<b>', '<bold>'):gsub('</b>', '</bold>'):gsub(
                                                '<strong>', '<bold>'):gsub('</strong>', '</bold>'):gsub(
                                                '<i>', '<italic>'):gsub('</i>', '</italic>'):gsub(
                                                '<em>', '<italic>'):gsub('</em>', '</italic>')
      end
    end 
    fh:close()

    -- Salida jats
    if format_out == 'jats' then 
      raw_content = '<table-wrap id="' .. label .. '">\n' ..
                    '<label>Tabla ' .. fignum .. '.</label>\n' ..
                    '<caption>' .. 
                      '<title>' .. title .. '</title>' ..
                    '</caption>\n' .. raw_content ..
                    '</table-wrap>'
    end
  end     
  -- return final code block
  return pandoc.RawBlock(format_out, raw_content)
  
end

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

--- Check if a directory exists in this path
-- function isdir(path)
--   -- "/" works on both Unix and Windows
--   return exists(path.."/")
-- end


-- Recorrido de bloques para buscar figuras y tablas.  
-----------------------------------------------------
-- TODO   Para las tablas se lee archivo externo en función del formato de salida y se generan bloques de código (RawBlock)
--        Para los marcadores de imágenes se generan bloques de código (RawBlock) en formato de salida 
--        Se cuentan cantidad de figuras y tablas y se agregan a los metadatos

function Blocks(blocks)

  local text = pandoc.text
  local root = "./float/"                                 -- Definir directorio para elementos flotantes

  -- Si no existe ./float/ saltea el bloque 
  -- filtro = os.execute("cd " .. root) and true or false
  -- filtro = exists(root)
  -- print("\n")
  -- print(filtro)
  if exists(root) then

    -- print("Existe ./float/")
    -- Listar archivos con elementos flotantes
    local archivos = pandoc.system.list_directory(root)     

    --Inicializar contadores de tablas y figuras
    contador_tab = 0
    contador_fig = 0

    for i = 1, #blocks, 1 do
      -- print("ingresa a bloque " .. i)
      local bloque = blocks[i]
    
      -- Obtener contenido textual del bloque
      local content = pandoc.utils.stringify(bloque)
      -- Detecta marcadores de elementos flotantes en bloques    
      local bloque_float = is_float_element(content)

      -- -- Filtra bloques con marcador de figura
      if bloque_float then    

        -- print("- Contiene un float")

        -- Define label y path a la imagen
        label = content:match('^~!include=' .. bloque_float .. '_[0-9][0-9]'):gsub("^~!include=", "")
        for i = 1, #archivos, 1 do
          float_file = archivos[i]:match(label .. '.[a-z]+')
          if float_file then
            path = root .. float_file
          end
        end 

        -- Obtiene metadatos de la figura (título, fuente y notas)
        float_meta = meta_float(content)

        if bloque_float == "FIG" then
          -- Modifica bloques con figuras
          contador_fig = contador_fig + 1

          if FORMAT:match 'latex' or FORMAT:match 'pdf' then
            blocks[i] = fig_latex(label, float_meta, root)
          elseif FORMAT:match 'html' or FORMAT:match 'json' then
            blocks[i] = fig_html(root, float_meta, label, contador_fig)
          elseif FORMAT:match 'jats'  then
            blocks[i] = fig_jats(label, float_meta, contador_fig)
          end
        end

        if bloque_float == "TAB" then
          -- Modifica bloques con tablas
          contador_tab = contador_tab + 1

          blocks[i] = tab_float(root .. label, label, float_meta, contador_fig, FORMAT)
        end
      end
      
    end
  else
    print("No existe ./float/")
  end
  return blocks
end

-- Contar figuras y tablas (para xml-jats)
function Meta(m)
  m.n_figs = contador_fig
  m.n_tabs = contador_tab
  if to_header then
    m.to_header = pandoc.RawBlock('latex', to_header)
  end
  return m
end