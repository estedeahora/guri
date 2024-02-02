--- include-float-in-format.lua – filter to include floating element code (depending on output format)
--- https://github.com/estedeahora/guri/tree/main/files/filters/include-float-in-format.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local root = "./float/"                       
local to_header = ''
local mark_citation = '%[{.-}{@.-}{.-}]{.-}'

local RawBlock = pandoc.RawBlock 
local open = io.open

-- citation_elements(cita) ----------------------------------
-- Toma un texto con un marcador de cita con la forma: "[{prefix}{@id}{suffix}]{cita textual}". Como resultado devuelve los elementos que componen la cita.
-- Return: Table con elementos de cita.

local function citation_elements(cita)
  
  -- print(cita)                                      -- [{}{@21909}{, p. 3 }]{(Weber, 2002, p. 3)}
  
  local pre = cita:match('^%[{.-}{@'):gsub('^%[{', ''):gsub('}{@', '')
  -- print("prefix", pre)                             -- prefix	
  local id = cita:match('@.+%}'):gsub('}.+', ''):gsub('@', '')
  -- print("id", id)                                  -- id	@21909
  local suf = cita:gsub('^%[{' .. pre .. '}{@' .. id .. '}{', ''):gsub('}]{.-}', '')
  -- print("suffix", suf)                             -- suffix	, p. 3 
  local cita_comp = cita:gsub('^%[{' .. pre .. '}{@' .. id .. '}{' .. suf .. '}]{', ''):gsub('}$', '')
  
  -- Retiene delimitadores previo y posterior "()"
  local prev = cita_comp:match('^%(', 1, "")
  if(prev == nil) then prev = '' end

  local post = cita_comp:match('%)$', 1, "") 
  if(post == nil) then post = '' end

  cita_comp = cita_comp:gsub('^%(', ''):gsub('%)$', '') 
  -- print(prev, cita_comp, post)                                 -- (    Weber, 2002, p. 3   )

  
  return {id = id, 
          -- pre = pre, suf = suf, 
          cita_comp = cita_comp,
          prev = prev, 
          post = post
        }

end

-- add_citation(str) ----------------------------------
-- Toma un texto en formato de cadena plana en el que identifica si existe un marcador de cita, el cual reemplaza 
--      por el formato adecuado para xmljats.
-- Return: Cadena de texto plano (con cita transformada de marca a formato específico).


local function add_citation(str)

  -- Cuenta marcadores de cita
  local _, cita_count = string.gsub(str,  mark_citation, "")
  local cita_new = ""

  if cita_count > 0 then

    -- print("\nCantidad de citas:", cita_count)

    for i = 1, cita_count do
    
      -- Obtiene cita i (primera disponible)
      local cita_mark = str:match(mark_citation)
    
      -- Obtiene elementos de la cita
      local el = citation_elements(cita_mark)

      -- Devuelve cita en formato
      if FORMAT:match 'latex' or FORMAT:match 'pdf' then
        cita_new = el.prev .. '\\citeproc{ref-' .. el.id .. '}{' .. el.cita_comp .. '}' .. el.post 
      elseif FORMAT:match 'html' or FORMAT:match 'json' then
        cita_new = '<span class="citation">' .. el.prev .. '<a href="#ref-' .. el.id .. '">' .. el.cita_comp .. '</a>' .. el.post .. '</span>'                            -- '<span class="citation">(' .. alll cita_new .. ')</span>'
      elseif FORMAT:match 'jats'  then
        cita_new = el.prev .. '<xref alt="' .. el.cita_comp .. '" rid="ref-' .. el.id .. '" ref-type="bibr">' .. el.cita_comp .. '</xref>' .. el.post         -- '(' .. alll cita_new .. ')'
      end   

      -- Reemplaza la cita formateada por la marca de cita
      str = str:gsub(mark_citation, cita_new, 1)

    end 

  end

  return(str)

end


-- fig_latex(label, float_attr) ----------------------------------------
-- Genera un texto de código plano (RawBlock) para latex que incluye figuras
-- Return: RawBlock con ambiente figure (latex)

local function fig_latex(label, float_attr)

  local title, source, note, fignum = float_attr.title, float_attr.source, float_attr.note, float_attr.fignum

  -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
  if source ~= "" then source = '\\source{' ..  add_citation(source) .. '}\n' end
  if note ~= "" then note = '\\notes{' ..  add_citation(note) .. '}\n' end

  local raw_elem = '\\begin{figure}\n' ..
                    '\\centering\n' .. 
                    '\\includegraphics[width=0.9\\textwidth]{' .. root .. label .. '}\n' .. 
                    '\\caption{' .. title .. '}\n' .. 
                    source .. note ..
                    '\\label{' .. label .. '}\n' ..
                    '\\end{figure}'

  return RawBlock('latex', raw_elem)

end

-- fig_html(label, float_attr) ----------------------------------------
-- Genera un texto de código plano (RawBlock) para html que incluye figuras
-- Return: RawBlock con ambiente figure (html)

local function fig_html(label, float_attr)

  local title, source, note, fignum, path = float_attr.title, float_attr.source, float_attr.note, float_attr.fignum, float_attr.path
  path = path:gsub('^%' .. root, "")

  -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
  if source ~= "" then source = '<figcaption class="extra"><em>Fuente: ' ..  add_citation(source) .. '</em></figcaption>\n' end
  if note ~= "" then note = '<figcaption class="extra">Nota: ' ..  add_citation(note) .. '</figcaption>\n' end

  local raw_elem = '<figure id="' .. label .. '">\n' ..
                    '<img src="' .. path .. '" alt="' .. label .. '"/>\n' .. 
                    '<figcaption>Figura ' .. fignum .. ". " .. title .. '</figcaption>\n' ..
                    source .. note ..
                    '</figure>'

  return RawBlock('html', raw_elem)

end

-- fig_jats(path, float_attr) --------------------------------
-- Genera un texto de código plano (RawBlock) para jats que incluye figuras
-- Return: RawBlock con ambiente figure (jats)

local function fig_jats(label, float_attr)

  local title, source, note, fignum, path = float_attr.title, float_attr.source, float_attr.note, float_attr.fignum, float_attr.path
  path = path:gsub('^%' .. root, "")

  -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
  if source ~= '' then source = '<attrib>Fuente: ' ..  add_citation(source) .. '</attrib>\n' end
  if note ~= '' then note = '<p content-type="Figure-Notes">Notas: ' ..  add_citation(note) .. '</p>\n' end

  local raw_elem = '<fig id="' .. label .. '">\n' ..
                    '<label>Figura ' ..  fignum .. '.</label>\n' ..
                    '<caption>\n' ..
                    '<p>' .. title .. '</p>' .. 
                    '</caption>\n' ..
                    '<graphic xlink:href="'.. path .. '"/>\n' ..
                    note .. source .. 
                    '</fig>'
              
  return RawBlock('jats', raw_elem)

end
  
-- tab_float(label, float_attr) ----------------------------------
-- Genera un texto de código plano (RawBlock) para latex/html/jats que incluye tablas.
-- Return: RawBlock con ambiente table.

local function tab_float(label, float_attr)
  
  local title, source, note, tabnum = float_attr.title, float_attr.source, float_attr.note, float_attr.tabnum

  local format_out = ''
  local format_ext = ''
  local tabla = ''
  local raw_content = ''

  -- Variables de formato (format_out, format_ext) y específicas de formato (tabla, source, note)
  if FORMAT:match 'latex' or FORMAT:match 'pdf' then
      format_out = 'latex'
      format_ext = '.tex'
      tabla = false

      -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
      if source ~= "" then source = '\\source{' ..  add_citation(source) .. '}\n' end
      if note   ~= "" then note   = '\\notes{' ..  add_citation(note) .. '}\n' end

  elseif FORMAT:match 'html' or FORMAT:match 'json' then
      format_out = 'html'
      format_ext = '.html'

      -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
      if source ~= "" then source = '<figcaption class="extra"><em>Fuente: ' ..  add_citation(source) .. '</em></figcaption>\n' end
      if note ~= "" then note = '<figcaption class="extra">Nota: ' ..  add_citation(note) .. '</figcaption>\n' end

  elseif FORMAT:match 'jats' then
      format_out = 'jats'
      format_ext = '.html'

      -- add citation toma el str y devuelve str modificado reemplazando marca de cita con formato adecuado de cita (según FORMAT)
      if source ~= "" then source = '<attrib>Fuente: ' ..  add_citation(source) .. '</attrib>\n' end
      if note ~= "" then note = '<table-wrap-foot><p>Notas: ' ..  add_citation(note) .. '</p></table-wrap-foot>\n' end
  end
    
  -- Abrir conexión con archivo
  local fh = open(root .. label .. format_ext)

  if not fh then
      io.stderr:write('Cannot open file ' .. fh .. ' | Skipping includes\n')
  else

    -- TODO Es posible unificar este código para los formatos de salida. Posiblemente generando una tabla  común a todos 
    --        los formatos con el contenido del archivo y luego aplicando las midificaciones.
    for line in fh:lines('L') do
        -- Salida latex
        if format_out == 'latex' then
            -- (a) Inicio de entorno 'table' (agregar 'caption' y 'label')
            if line:match "\\begin{table}" then
                tabla = true
                raw_content = raw_content .. line .. 
                                '\\caption{' .. title .. '}\n' ..
                                '\\label{' .. label .. '}\n'
            -- (b) Final de entorno 'table' (agregar source y note )
            elseif line:match "\\end{table}" then
                tabla = false
                raw_content = raw_content .. source .. note .. line  
            -- (c) Contenido de entorno 'table'        
            elseif tabla then
                raw_content = raw_content .. line
            -- (d) Incluir en header (anterior al entorno table)
            else
                -- Quitar elementos no utilizados
                line = line:gsub('%%.*', ''):gsub('\\documentclass{.*', ''):gsub('\\begin{document}.*', ''):gsub('\\end{document}.*', '')
                
                -- reemplazar usepackage por condicional de carga \IfPackageLoadedTF{package}{}{\usepackage{package}}
                if line:match "^\\usepackage" then
                  line = line:gsub("\n", "")
                  local package = line:gsub("\\usepackage", "")
                  line = "\\IfPackageLoadedTF" .. package .. "{}" .. "{" .. line .. "}\n"
                end

                to_header = to_header .. line
            end
        -- Salida html / jats
        elseif format_out == 'html' or format_out == 'jats' then
            raw_content = raw_content .. line
        end
    end
    fh:close()

    
    if format_out == 'html' then        -- Salida html
      raw_content = '<figure id="' .. label .. '">\n' ..
                    '<figcaption>Tabla ' .. tabnum .. ". " .. title .. '</figcaption>\n' ..
                    raw_content .. source .. note ..
                    '</figure>'
    elseif format_out == 'jats' then    -- Salida jats
      
      raw_content = raw_content:gsub('<br>', '<break/>'):gsub('<br/>', '<break/>'):gsub(
                                      '<b>', '<bold>'):gsub('</b>', '</bold>'):gsub(
                                      '<strong>', '<bold>'):gsub('</strong>', '</bold>'):gsub(
                                      '<i>', '<italic>'):gsub('</i>', '</italic>'):gsub(
                                      '<em>', '<italic>'):gsub('</em>', '</italic>')

      raw_content = '<table-wrap id="' .. label .. '">\n' ..
                    '<label>Tabla ' .. tabnum .. '.</label>\n' ..
                    '<caption>\n' .. 
                    '<title>' .. title .. '</title>\n' ..
                    '</caption>\n' ..
                    raw_content .. source .. note ..
                    '</table-wrap>'
    end
  end     
  -- return final code block
  return RawBlock(format_out, raw_content)
  
end

---  CodeBlock(cb) --------------------------------------------------------

function CodeBlock(cb)

  if cb.classes[1] == "FIG" then
        
    local label = cb.identifier
    local float_meta = cb.attributes
        
    if FORMAT:match 'latex' or FORMAT:match 'pdf' then
      cb = fig_latex(label, float_meta)
    elseif FORMAT:match 'html' or FORMAT:match 'json' then
      cb = fig_html(label, float_meta)
    elseif FORMAT:match 'jats'  then
      cb = fig_jats(label, float_meta)
    end 
    
  elseif cb.classes[1] == "TAB" then
      
    local label = cb.identifier
    local float_meta = cb.attributes
    
    cb = tab_float(label, float_meta)
  end

  return cb
end

-- Contar figuras y tablas (para xml-jats)
function Meta(m)
  if to_header then
    m.to_header = pandoc.RawBlock('latex', to_header)
  end
  return m
end