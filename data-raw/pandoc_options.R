data_excel <- "data-raw/pandoc_options.xlsx"
sheets <- c("type", "opts", "lua")
# pandoc_options <- purrr::map(sheets, \(.x) readxl::read_excel(data_excel, sheet = .x)) |>
#   purrr::set_names(sheets)

pandoc_options <- lapply(sheets, \(.x) readxl::read_excel(data_excel, sheet = .x))
names(pandoc_options) <- sheets

usethis::use_data(pandoc_options, overwrite = TRUE, internal = TRUE)
