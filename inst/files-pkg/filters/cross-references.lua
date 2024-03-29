--- cross-references.lua – filter to add cross-references from flags
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/cross-references.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Str(str) --------------------------------------------------------------------------------------
-- Description: [en] Changes cross-reference flags to links (pandoc.Link) to floating elements.
--				      [es] Cambia  marcas de referencias cruzadas por vínculos (pandoc.Link) a elementos flotantes.
-- Return: [en] Link (pandoc.Link). A text string (pandoc.Str) is also added before and after if necessary.
--		     [es] Vínculo (pandoc.Link). Se agrega también cadena de texto (pandoc.Str) antes y después si fuera necesario.

function Str(str)

  local texto = str.text
  local flotante = ''

  -- Identify figure/table flags.
  if texto:match('<!FIG_[0-9][0-9]>') or texto:match("<!TAB_[0-9][0-9]>") then
    
    -- Identify float type ('FIG' or 'TAB') and assigns associated label.
    local tipo = texto:gsub('^.*<!', ''):gsub('_[0-9][0-9]>.*$', '')
    if tipo == 'FIG' then
      flotante = 'Figura'
    elseif tipo == 'TAB' then
      flotante = 'Tabla'
    else
      print('Warning: "', texto, '" no es un marcador válido.')
    end

    -- Extracts pre- and post-float content.
    local extra_pre = texto:gsub('<!' .. tipo .. '_[0-9][0-9]>.*$', '')  
    local extra_pos = texto:gsub("^.*<!" .. tipo .. "_[0-9][0-9]>", '')
    
    -- Gets target (label) and figure number.
    target = texto:match('<!' .. tipo .. '_[0-9][0-9]>'):gsub('<!', ''):gsub('>', '')
    numero = target:gsub(tipo .. '_', ''):gsub('^0', '')

    str = {pandoc.Str(extra_pre),
            pandoc.Link(pandoc.Str(flotante .. ' ' .. numero), '#' .. target), 
            pandoc.Str(extra_pos)}
  end

  return str
  
end