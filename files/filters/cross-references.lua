--- cross-references.lua – filter to add cross-references from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/cross-references.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Cambio de referencias cruzadas por vínculos (pandoc.Link) o \ref (latex)
---------------------------------------------------------------------------

function Str(str)
  local texto = str.text
  local flotante = ''
  -- Identifica marcador de figura / tabla
  if texto:match('<!FIG_[0-9][0-9]>') or texto:match("<!TAB_[0-9][0-9]>") then
    
    -- Identifica tipo de flotante (FIG o TAB) y asigna etiqueta
    local tipo = texto:gsub('^.*<!', ''):gsub('_[0-9][0-9]>.*$', '')
    if tipo == 'FIG' then
      flotante = 'Figura'
    elseif tipo == 'TAB' then
      flotante = 'Tabla'
    else
      print('Warning: "', texto, '" no es un marcador válido.')
    end

    -- Extrae contenido previo y posterior al flotante
    local extra_pre = texto:gsub('<!' .. tipo .. '_[0-9][0-9]>.*$', '')  
    local extra_pos = texto:gsub("^.*<!" .. tipo .. "_[0-9][0-9]>", '')
    
    -- Obtiene target (label) y número de figura
    target = texto:match('<!' .. tipo .. '_[0-9][0-9]>'):gsub('<!', ''):gsub('>', '')
    numero = target:gsub(tipo .. '_', ''):gsub('^0', '')

    str = {pandoc.Str(extra_pre),
            pandoc.Link(pandoc.Str(flotante .. ' ' .. numero), '#' .. target), 
            pandoc.Str(extra_pos)}

  end

  return str
  
end