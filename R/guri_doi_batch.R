#' Generate a `doi_batch` xml file for Crossref deposit
#'
#' @param list_art A data.frame with the article information as returned by
#'   [guri_list_articles]. It must contain the following columns: `id`
#'   (character), with the article id; and `path` (character), with the path to
#'   the article.
#' @param path_issue A string with the path to the issue folder.
#'
#' @details The `doi_batch` xml file is saved in the `doi_register` folder,
#' inside the issue folder.
#'
#' The `doi_batch` xml file searches each of the article folders for the
#' `art[id]_crossref.xml` file (inside the '_temp' folder), and uses the
#' information in these files to create a unified `doi_batch` xml file (each
#' article is saved as a `<journal_article>` element in the xml file).
#'
#' In adition to the `doi_batch` xml file, this function also creates a text
#' file with the information of the articles that will be deposited in Crossref.
#' The text file is saved in the same folder as the `doi_batch` xml file.
#'
#' @return A string with the path to the `doi_batch` xml file.
#'
#' @export

guri_doi_batch <- function(list_art, path_issue){

  # Create 'JOURNAL/ISSUE/doi_register'
  path_doi <- fs::path(path_issue, "doi_register")
  fs::dir_create(path_doi)

  list_art$path_crossref <- fs::path(list_art$path, "_temp",
                                     paste0(list_art$id, "_crossref"),
                                     ext = "xml")

  # read xml files
  xml_docs <- list_art$path_crossref[file.exists(list_art$path_crossref)] |>
    purrr::map(xml2::read_xml)

  # Create xml_base
  xml_base <- xml2::xml_unserialize(xml2::xml_serialize(xml_docs[[1]], NULL))
  xml_base |> xml2::xml_find_all("//d1:journal_article") |> xml2::xml_remove(free = FALSE)

  time_stamp <- xml_base |> xml2::xml_find_all("//d1:timestamp") |> xml2::xml_text()

  # Find all <journal_article> in xml_docx
  journal_article <- purrr::map(xml_docs,
                                \(.x) xml2::xml_find_all(.x, "//d1:journal_article"))

  # Add all <journal_article> to `xml_base`
  purrr::walk(journal_article,
              \(art) xml2::xml_add_child(.x = xml2::xml_find_all(xml_base, "//d1:journal"),
                                         .value = art) )

  # Write inform
  info_batch <- xml_journal_info(xml_base, journal_article) |>
    cat(file = fs::path(path_doi, paste0("doi_batch_", time_stamp), ext = "txt"))

  # Write xml doi_batch
  doi_batch_file <- fs::path(path_doi, paste0("doi_batch_", time_stamp), ext = "xml")

  xml2::write_xml(xml_base, doi_batch_file)

  return(doi_batch_file)

}

# xml_art_info: Create the content of `doi_batch` info file
# j: Complete journal xml file
# ja: List of articles xml files

xml_journal_info <- function(j, ja){

  paste(
    paste0("# ", xml2::xml_find_all(j, "//d1:journal_metadata/d1:full_title") |> xml2::xml_text()),
    paste0("ISSN: ", xml2::xml_find_all(j, "//d1:journal_metadata/d1:issn") |> xml2::xml_text() |> paste0(collapse = " / ")),
    paste0("Volumen: ", xml2::xml_find_all(j, "//d1:journal_issue/d1:journal_volume") |> xml2::xml_text()),
    paste0("Issue: ", xml2::xml_find_all(j, "//d1:journal_issue/d1:issue") |> xml2::xml_text()),
    paste0("Deposited date: ", as.POSIXct(xml2::xml_find_all(j, "//d1:head/d1:timestamp") |> xml2::xml_text() |> as.numeric() ) ),
    paste0("Deposited DOI: ", length(ja)),
    purrr::map_chr(ja, xml_art_info) |> paste0(collapse = "\n"),
    sep = "\n\n"
  )
}

# xml_art_info: Create the content of each article in `doi_batch` info file
# ja: List of articles xml files

xml_art_info <- function(ja){

  sub <- xml2::xml_find_all(ja, "//d1:titles/d1:subtitle") |> xml2::xml_text()
  if(length(sub) > 0) sub = paste0(sub, ". ")

  paste0(
    "* ",
    xml2::xml_find_all(ja, "//d1:surname") |> xml2::xml_text() |> paste0(collapse = "; "), ". ",
    xml2::xml_find_all(ja, "//d1:titles/d1:title") |> xml2::xml_text(), ". ", sub,
    paste0("DOI: ", xml2::xml_find_all(ja, "//d1:doi_data/d1:doi") |> xml2::xml_text())
  )
}
