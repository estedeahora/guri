--- add-credit.lua – filter to filter to add credit data to author metadata (in art[~]_credit.csv file)
--- https://github.com/estedeahora/guri/tree/main/files/filters/add-credit.lua
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa

local function credit_dict()
	local credit_term = {"Conceptualization", "Data curation", "Formal Analysis", 
						"Funding acquisition", "Investigation", "Methodology",
						"Project administration", "Resources", "Software",
						"Supervision", "Validation", "Visualization", 
						"Writing – original draft", "Writing – review & editing"}

	local credit_uri = {"conceptualization/", "data-curation/", "formal-analysis/",
						"funding-acquisition/", "investigation/", "methodology/", 
						"project-administration/", "resources/", "software/",
						"supervision/", "validation/", "visualization/",
						"writing-original-draft/", "writing-review-editing/"}
	for i = 1, #credit_uri do
		credit_uri[i] = "https://credit.niso.org/contributor-roles/" .. credit_uri[i]
	end

	return credit_term, credit_uri
end

-- Meta(m)
-- Incorpora roles credit (como tabla) dentro de author // Incorporates credit roles (as table) within author
-- Return: Meta modificado con tabla con roles credit dentro de meta.author 

function Meta(m)

	local credit_file = ''

	-- detect credit_file (art[XXX]_credit.csv)
    local archivos = pandoc.system.list_directory('.')
	for i = 1, #archivos do
        credit_file = archivos[i]:match('art[0-9][0-9][0-9]_credit%.csv')
        if credit_file then break end
    end 

	if credit_file then
		-- make credit dictionary terms and uri
		local credit_term, credit_uri = credit_dict() 
		
		-- require csv library and read credit file
		local csv = dofile("../../../files/filters/CSV.lua")
		local datos, header = csv.load('./' .. credit_file, ',', true)

		-- count authors ('n_aut') 
		local n_aut = #header - 1
		if #m.author ~= n_aut then
			error('El numero de autores en article.yaml (' .. #m.author .. ') y en '
					 .. credit_file .. ' (' .. n_aut .. ') no coincide.')
		end

		-- create 'credit' table ({cont, elem, uri})
		local credit = {}
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