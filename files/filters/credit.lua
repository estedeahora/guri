--- credit.lua – filter to 
--- https://github.com/..
--- Copyright: © 2023 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local function credit_dict()
	credit_term = {"Conceptualization", "Data curation", "Formal Analysis", 
					"Funding acquisition", "Investigation", "Methodology",
					"Project administration", "Resources", "Software",
					"Supervision", "Validation", "Visualization", 
					"Writing – original draft", "Writing – review & editing"}

	credit_uri = {"conceptualization/", "data-curation/", "formal-analysis/",
					"funding-acquisition/", "investigation/", "methodology/", 
					"project-administration/", "resources/", "software/",
					"supervision/", "validation/", "visualization/",
					"writing-original-draft/", "writing-review-editing/"}
	for i = 1, #credit_uri do
		credit_uri[i] = "https://credit.niso.org/contributor-roles/" .. credit_uri[i]
		-- print(credit_term[i])
		-- print(credit_uri[i])
	end

	return credit_term, credit_uri
end

function Meta(m)

	-- detect credit_file (art[XXX]_credit.csv)
    local archivos = pandoc.system.list_directory('.')
	for i = 1, #archivos do
        credit_file = archivos[i]:match('art[0-9][0-9][0-9]_credit%.csv')
        if credit_file then break end
    end 

	if credit_file then
		-- make credit dictionary terms and uri
		credit_term, credit_uri = credit_dict() 
		
		-- require csv library and read credit file
		local csv = dofile("../../../files/filters/CSV.lua")
		datos, header = csv.load('./' .. credit_file, ',', true)

		-- count authors ('n_aut') 
		n_aut = #header - 1
		if #m.author ~= n_aut then
			error('El numero de autores en article.yaml (' .. #m.author .. ') y en '
					 .. credit_file .. ' (' .. n_aut .. ') no coincide.')
		end

		-- create 'credit' table ({cont, elem, uri})
		credit = {}
		for i = 1, n_aut do
			credit[i] = {}
		end
	
		for i, row in pairs(datos) do
			for k = 2, n_aut + 1 do
				if row[k] ~= "" then
					table.insert(credit[k-1], {cont = row[1], elem = credit_term[i], uri = credit_uri[i]})
				end
			end
		end
	
		-- modify 'Meta'
		for i = 1, n_aut do
			m.author[i].credit = credit[i]
		end
		m.credit = true
	else
		io.stderr:write('WARNING: No existe credit file".\n')
	end

	return m
end
	
    

    -- print("total de autores = " .. n_aut, '\n')
    -- for i, row in pairs(header) do
    --     print(i, row)
    -- end

    -- for i = 1, n_aut do
    --     print(header[i+2] .. ":")
    --     print(table.unpack(credit[i]))
    --     print()
    -- end


    -- for j,k in pairs(m.author) do
    --     print(j, k)
    -- end
