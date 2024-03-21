# Armado de archivos base ------------------------------

# GURI_listfiles() ----------------------------------------

GURI_listfiles <- function(path_issue){

  if(!dir.exists(path_issue)){
    stop("No existe el directorio ", "\033[34m", path_issue, "\033[39m", "\n",
         "Cree el directorio con los artículos a maquetar.",
         "Recuerde colocar una carpeta para artículo.")
  }

  art <- data.frame(art_path = list.dirs(path_issue, recursive = F)) |>
    filter(str_detect(art_path, paste0(path_issue, "art[0-9]{3}.*"), negate = F)
    ) |>
    mutate(#g = str_detect(art_path, paste0(path_issue, "art[0-9]{3}_*.*?/")),
      art_id = str_remove(art_path, path_issue),
      art_id = str_remove(art_id, "_.*$"),
      art_path = paste0(art_path, "/"))

  files <- map(art$art_path, ~list.files(.x, all.files = T, recursive = T)) |>
    map2_df(.y = art$art_id, ~GURI_filetype(.x, .y)) |>
    mutate(across(starts_with("is_"), as.logical) )

  art <- cbind(art, files)

  return(art)
}

# GURI_filetype() -----------------------------------------

GURI_filetype <- function(art_files, art_id){

  search1 <- c(".docx", ".yaml", "_credit.xlsx", # "_biblio.json",
               "_app[0-9]{2}.docx", "_notes.md")

  res1 <- map_lgl(search1, ~any(str_detect(art_files, paste0(art_id, .x) ))) |>
    set_names(c("is_docx", "is_yaml", "is_credit", # "is_biblio",
                "is_appendix", "is_notes"))

  # bib <- art_files[str_detect(art_files, paste0(art_id, "_biblio.json"))]
  # print(read.delim(paste0(path_issue, bib)))

  search2 <- c("float/TAB_[0-9]{2}.xlsx+", "float/FIG_[0-9]{2}.+")

  res2 <- map_int(search2, ~sum(str_detect(art_files, .x ))) |>
    set_names(c("float_tab", "float_fig"))

  return(c(res1, res2))
}



