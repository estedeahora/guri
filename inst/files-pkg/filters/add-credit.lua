--- add-credit.lua – filter to add credit data to author metadata (from art[~]_credit.csv file)
--- https://github.com/estedeahora/guri/tree/main/inst/files-pkg/filters/add-credit.lua
--- The filter is part of the R package {guri}.
---
--- Copyright: © 2024 Pablo Santiago SERRATI
--- License: CC-by-nc-sa. The licence for this filter is the same as for the {guri} package 
---          (see https://github.com/estedeahora/guri/).

-- Summary:
--- The add-credit.lua is a Pandoc Lua filter that adds credit data to the author metadata. 
--- The filter reads the credit data from a CSV file (art[XXX]_credit.csv) and adds it to the
--- author metadata in the YAML file. The filter also adds the credit data to the article metadata. 

-- function credit_dict() --------------------------------------------------------------
-- Description: [en] Creates lists with credit terms and url to credit 
--				[es] Crea listas con términos credit (en inglés) y url a credit
-- Return: [en] A list with two lists. The first with the credit terms in English ('credit_term') 
--					and the second with the urls to each of the credit roles ('credit_uri').
--		   [es] Una lista con dos listas. La primera con los términos credit en inglés ('credit_term')
--					 y la segunda con los url a cada uno de los roles credir ('credit_uri').  

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

-- Meta(m) ----------------------------------------------------------------------------
-- Description: [en] Incorporates credit roles (as table) within author 
--				[es] Incorpora roles credit (como tabla) dentro de author
-- Return: [en] Modified 'Meta' containing a table with the credit roles inside meta.author[i].credit
--				  (according to the role it has in the article). Each table contains 'cont' with
--				  the role translated into the language of the article (take the terms from the 
--				  first column of art[~]_credit.xlsx);  'elem' with the credit role in english; 
--				  and 'uri' with the url to the credit role.
--		   [es] Meta modificado conteniendo una tabla con los roles credit dentro de meta.author[i].credit 
--				  (según el rol que tiene en el artículo). Cada tabla contiene 'cont' con el rol 
--				  traducido al idioma del artículo (toma los términos de la primera columna de 
--				  art[~]_credit.xlsx); 'elem' con el rol credit traducido; y 'uri' con la url al 
--				  rol credit.

function Meta(m)

	local credit_file = ''

	-- detect credit_file (art[XXX]_credit.csv)
    local archivos = pandoc.system.list_directory('.')

	for i = 1, #archivos do
        credit_file = archivos[i]:match('^art[0-9][0-9][0-9]_credit%.csv')
        if credit_file then break end
    end 

	if credit_file then
		-- make credit dictionary terms and uri
		local credit_term, credit_uri = credit_dict() 

		-- require csv library and read credit file
		local csv = pandoc.system.with_working_directory(m.config_path, function() return dofile("CSV.lua") end)

		local datos, header = csv.load(credit_file, ',', true)

		-- count authors ('n_aut')
		local n_aut = #header - 1
		if #m.author ~= n_aut then
			error('The number of authors in article.yaml  (' .. #m.author .. ') and '
					 .. credit_file .. ' (' .. n_aut .. ') do not match.')
		end

		-- create 'credit' table ({cont, elem, uri})
		local credit = {}
		for i = 1, n_aut do
			credit[i] = {}
		end
	
		-- assigns credit according to roles performed by each author.
		for i, row in pairs(datos) do
			for k = 2, n_aut + 1 do
				if row[k] ~= "" then

					table.insert(credit[k-1], {cont = row[1], 
											   elem = credit_term[i], 
											   uri = credit_uri[i]})
				end
			end
		end
	
		-- modify 'Meta'
		for i = 1, n_aut do
			m.author[i].credit = credit[i]
		end
		m.credit = true
	else
		warn('WARNING: There is no credit file.\n')
	end

	return m
end