--- credit-before-bib.lua – filter to include float elements from flags
--- https://github.com/estedeahora/guri/tree/main/files/filters/credit-before-bib.lua
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

stringify = pandoc.utils.stringify

function get_credit(meta)
  if(meta.credit) then
      
    credit_cont = "\\sffamily\\small\n"
    aut = meta.author
    for _, aut_i in pairs(aut) do

      credit_cont = credit_cont .. "\\textbf{" .. stringify(aut_i.surname) .. ":} \n"
      
      for k, cred_i in pairs(aut_i.credit) do
        
        credit_cont = credit_cont .. stringify(cred_i.cont) .. 
                      " (" .. stringify(cred_i.elem) .. ")"

        if k ~= #aut_i.credit then 
          credit_cont = credit_cont .. "; \n"
        else
          credit_cont = credit_cont .. ". \n"
        end
      end
    end

    credit_tit = pandoc.Header(2, "Declaración de contribuciones de autoría (CRediT)", pandoc.Attr("credit", {"unnumbered"}))

    credit_cont = credit_cont:gsub("&", "\\&")
    credit_cont = credit_cont .. "\n \\rmfamily \n \\normalsize"
    credit_cont = pandoc.RawBlock('latex', credit_cont)
  else
    io.stderr:write("Sin datos de credit.")
  end
end

function add_credit1(el)
  if(stringify(el) == "Referencias bibliográficas") then
    with_ref = true
    return {credit_tit, credit_cont, el}
  end
end

function add_credit2(doc)
  if(with_ref == nil) then
    doc.blocks:extend ({credit_tit, credit_cont})
    return doc
  end
end

return {{Meta = get_credit}, {Header = add_credit1}, {Pandoc = add_credit2}}


