
local root = "./float/"                       
local to_header = ''

local RawBlock = pandoc.RawBlock 
local open = io.open

-- fig_latex(label, float_attr) ----------------------------------------
-- Genera un texto de código plano (RawBlock) para latex que incluye figuras
-- Return: RawBlock con ambiente figure (latex)

function fig_latex(label, float_attr)

  local title, source, note, tabnum = float_attr.title, float_attr.source, float_attr.note, float_attr.tabnum

  if source ~= "" then source = '\\source{' ..  source .. '}\n' end
  if note ~= "" then note = '\\notes{' ..  note .. '}\n' end

  raw_elem = '\\begin{figure}\n' ..
              '\\centering\n' .. 
              '\\includegraphics[width=0.9\\textwidth]{' .. root .. label .. '}\n' .. 
              '\\caption{' .. float_attr.title .. '}\n' .. 
              source .. note ..
              '\\label{' .. label .. '}\n' ..
              '\\end{figure}'

  return RawBlock('latex', raw_elem)

end
  
  -- fig_html(label, float_attr) ----------------------------------------
  -- Genera un texto de código plano (RawBlock) para html que incluye figuras
  -- Return: RawBlock con ambiente figure (html)
  
  function fig_html(label, float_attr)

    local title, source, note, tabnum = float_attr.title, float_attr.source, float_attr.note, float_attr.tabnum

    if source ~= "" then source = '<figcaption><em>Fuente: ' ..  source .. '</em></figcaption>\n' end
    if note ~= "" then note = '<figcaption>Nota: ' ..  note .. '</figcaption>\n' end
  
    raw_elem = '<figure id="' .. label .. '">\n' ..
                '<img src="' .. float_attr.path .. '" alt="' .. label .. '"/>\n' .. 
                '<figcaption>Figura ' .. float_attr.fignum .. ". " .. float_attr.title .. '</figcaption>\n' ..
                source .. note ..
                '</figure>'

    return RawBlock('html', raw_elem)

  end
  
  -- fig_jats(path, float_attr) --------------------------------
  -- Genera un texto de código plano (RawBlock) para jats que incluye figuras
  -- Return: RawBlock con ambiente figure (jats)
  
  function fig_jats(label, float_attr)

    local title, source, note, tabnum = float_attr.title, float_attr.source, float_attr.note, float_attr.tabnum

    if source ~= '' then source = '<attrib>Fuente: ' ..  citation_jats(source) .. '</attrib>\n' end
    if note ~= '' then note = '<p content-type="Figure-Notes">Notas: ' ..  citation_jats(note) .. '</p>\n' end
  
    raw_elem = '<fig id="' .. label .. '">\n' ..
                '<label>Figura ' ..  float_attr.fignum .. '.</label>\n' ..
                '<caption>\n' ..
                '<p>' .. float_attr.title .. '</p>' .. 
                '</caption>\n' ..
                '<graphic xlink:href="'.. float_attr.path .. '"/>\n' ..
                note .. source .. 
                '</fig>'
                
    return RawBlock('jats', raw_elem)

  end
  
-- tab_float(tab_path, label, float_meta, fignum, format) ----------------------------------
-- Genera un texto de código plano (RawBlock) para latex/html/jats que incluye tablas
-- Return: RawBlock con ambiente table

local function tab_float(label, float_attr, format)
  
  local title, source, note, tabnum = float_attr.title, float_attr.source, float_attr.note, float_attr.tabnum

  -- Variables de formato (format_out, format_ext) y específicas de formato (tabla, source, note)
  if format:match 'latex' or format:match 'pdf' then
      format_out = 'latex'
      format_ext = '.tex'
      tabla = false

      if source ~= "" then source = '\\source{' ..  source .. '}\n' end
      if note   ~= "" then note   = '\\notes{' ..  note .. '}\n' end

  elseif format:match 'html' or format:match 'json' then
      format_out = 'html'
      format_ext = '.html'

      if source ~= "" then source = '<figcaption><em>Fuente: ' ..  source .. '</em></figcaption>\n' end
      if note ~= "" then note = '<figcaption>Nota: ' ..  note .. '</figcaption>\n' end

  elseif format:match 'jats' then
      format_out = 'jats'
      format_ext = '.html'

      if source ~= "" then source = '<attrib>Fuente: ' ..  source .. '</attrib>\n' end
      if note ~= "" then note = '<table-wrap-foot><p>Notas: ' ..  note .. '</p></table-wrap-foot>\n' end
  end
    
  -- Abrir conexión con archivo
  local raw_content = ''
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
 
-- citation_jats(str) ----------------------------------
-- Toma un texto en formato de cadena plana en el que identifica si existe un marcador de cita, el cual reemplaza 
--      por el formato adecuado para xmljats.
-- Return: Cadena de texto plano

function citation_jats(str)

  -- Identifica marcador de cita
  cita = str:match('%[{.*}{@%d+}{.*}]{.*}')
  
  if cita ~= nill then

    -- Obtiene elementos de la cita
    local el = citation_elements(cita)

    local cita_comp = el.cita_comp:gsub('^%(', ''):gsub('%)$', '') 
    local cita_jats = '(<xref alt="' .. cita_comp .. '" rid="ref-' .. el.id:gsub('@', '') .. '" ref-type="bibr">' .. cita_comp .. '</xref>)'

    str = str:gsub('%[{.*}{@%d+}{.*}]{.*}', cita_jats)
  end

  return(str)

end

-- citation_elements(cita) ----------------------------------
-- Toma un texto con un marcador de cita con la forma: "[{prefix}{@id}{suffix}]{cita textual}". Como resultado devuelve los elementos que componen la cita.
-- Return: Table con elementos de cita


function citation_elements(cita)

  -- print(cita)                                      -- [{}{@21909}{, p. 3 }]{(Weber, 2002, p. 3)}
  local pre = cita:match('^%[{.*}{@'):gsub('^%[{', ''):gsub('}{@', '')
  -- print("prefix", pre)                             -- prefix	
  local id = cita:match('@.+}'):gsub('}.+', '')
  -- print("id", id)                                  -- id	@21909
  local suf = cita:gsub('^%[{' .. pre .. '}{' .. id .. '}{', ''):gsub('}]{.+}$', '')
  -- print("suffix", suf)                             -- suffix	, p. 3 
  local cita_comp = cita:gsub('^%[{' .. pre .. '}{' .. id .. '}{' .. suf .. '}]{', ''):gsub('}$', '')
  -- print(cita_comp)                                 -- (Weber, 2002, p. 3)
  local cita_conten = cita_comp:gsub(suf:gsub('%s$', ''), '')
  -- print(cita_conten)                               -- (Weber, 2002)

  return {pre = pre, id = id, suf = suf, 
          cita_comp = cita_comp, cita_conten = cita_conten}

end


---  CodeBlock(cb) --------------------------------------------------------

function CodeBlock(cb)

  if cb.classes[1] == "FIG" then
        
    label = cb.identifier
    float_meta = cb.attributes
        
    if FORMAT:match 'latex' or FORMAT:match 'pdf' then
      cb = fig_latex(label, float_meta)
    elseif FORMAT:match 'html' or FORMAT:match 'json' then
      cb = fig_html(label, float_meta)
    elseif FORMAT:match 'jats'  then
      cb = fig_jats(label, float_meta)
    end 
    
  elseif cb.classes[1] == "TAB" then
      
    label = cb.identifier
    float_meta = cb.attributes
    
    cb = tab_float(label, float_meta, FORMAT)
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