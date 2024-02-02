--- author-list.lua – filter to obtain filter to modify fields for latex output
--- (a) make aut_short: first two author names or "FirstSurname et al"; (b) tipo & tipo: history in date format
--- https://github.com/estedeahora/guri/tree/main/files/filters/author-list.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

function Meta(m)
  if FORMAT:match 'latex' or FORMAT:match 'pdf' then
  -- or FORMAT:match 'jats' or FORMAT:match 'json' 
    if m.author then
      -- Listado de autores 
      local aut_short
      local aut_i

      if #m.author > 2 then
        aut_short = m.author[1]["surname"]
        aut_short = pandoc.utils.stringify(aut_short) .. ' et al'
      else
        for i = 1, #m.author do
          aut_i = m.author[i]["surname"]
          aut_i = pandoc.utils.stringify(aut_i)
          if i == 1 then
            aut_short = aut_i
          else
            aut_short = aut_short .. ' & ' .. aut_i
          end
        end
      end

      -- Amrado de elementos para history (mes y tipo)
      local tipo = {accepted = "Aceptado", received = "Recibido"}
      local mes = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"}
      
      if(m.history) then
        for i = 1, #m.history do
          local mes_num = tonumber(m.history[i].month[1].text)
          m.history[i].mes = mes[mes_num]
          m.history[i].tipo = tipo[m.history[i].type[1].text]

        end
      end

      m.author_header = aut_short
      
      return m
    end
  end
end
