--- cross-references.lua – filter to add cross-references from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/cross-references.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

-- Cambio de referencias cruzadas por vínculos (pandoc.Link) o \ref (latex)
---------------------------------------------------------------------------

function Str(str)
  texto = str.text

  if texto:match('<!FIG_[0-9][0-9]>') 
    or texto:match("<!TAB_[0-9][0-9]>") then
    
    tipo = texto:gsub('^.*<!', ''):gsub('_[0-9][0-9]>.*$', '')
    if tipo == 'FIG' then
      flotante = 'Figura'
    elseif tipo == 'TAB' then
      flotante = 'Tabla'
    else
      print('Warning: "', texto, '" no es un marcador válido.')
    end

    extra_pre = texto:gsub('<!' .. tipo .. '_[0-9][0-9]>.*$', '')  
    extra_pos = texto:gsub("^.*<!" .. tipo .. "_[0-9][0-9]>", '')
    
    target = texto:match('<!' .. tipo .. '_[0-9][0-9]>'):gsub('<!', ''):gsub('>', '')
    numero = target:gsub(tipo .. '_', ''):gsub('^0', '')

    if FORMAT:match 'latex' or FORMAT:match 'pdf' then
      link = pandoc.RawInline("latex", extra_pre .. flotante .. '~\\ref{'.. target .. '}' .. extra_pos)
    else
      link = {pandoc.Str(extra_pre),
              pandoc.Link(pandoc.Str( flotante .. ' ' .. numero), '#' .. target), 
              pandoc.Str(extra_pos)}
    end

    return link
  else
    return str
  end
end