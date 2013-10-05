getModule <- function(course, module){
  require(plyr)
  load(file.path(course, module))
  names(mod) = tolower(gsub("\\.", "_", names(mod)))
  mod = transform(mod, type = ifelse(is.na(answer_type), 
   output_type, paste(output_type, answer_type, sep = "_"))
  )
  mod_list = alply(mod, 1, as.list)
  attr(mod_list, 'split_labels') = NULL
  return(mod_list)
}

getTemplates <- function(){
  tdir = system.file('templates', package = 'swirl')
  tfiles = dir(tdir, full = T)
  tpls = lapply(tfiles, read_file_)
  names(tpls) = tools::file_path_sans_ext(basename(tfiles))
  return(tpls)
}

read_file_ <- function(file, warn = F, ...){
  paste(readLines(file, warn = warn, ...), collapse = "\n")
}

render_template_ <- function (template, data = parent.frame(1), ...){
  if (file.exists(template){
    template <- read_file_(template)
  }
  paste(capture.output(cat(whisker.render(template, data = data))), 
    collapse = "\n"
  )
}

qParse <- function (x, ...) {
  UseMethod("qParse", x)
}

qParse.default <- function(x){
  x
}

qParse.figure <- function(x){
  x$code <- slidify:::read_file(
    file.path('course', 'Figures', x$figure),
    warn = F
  )
  return(x)
}

qParse.question_multiple <- function(x){
  require(stringr)
  x$Choices = gsub(
    paste0("^(", x$correct_answer, ')$'), 
    '_\\1_', 
    strsplit(x$choices, '\\;\\s*')[[1]], 
    perl = TRUE
  )
  x$choices = slidify:::zip_vectors(
    options = x$Choices,
    num = seq_along(x$Choices)
  )
  return(x)
}

process_q = function(q, templates){
  class(q) = as.character(q$type)
  if (class(q) %in% names(templates)){
    template = templates[[class(q)]]
  } else {
    template = templates[['text']]
  }
  rCharts::render_template(
    template = template,
    list(q = Filter(Negate(is.na), qParse(q)))
  )
}


templates <- getTemplates()
slides <- lapply(module[c(1, 4, 17)], process_q, templates = templates)

cat(process_q(module[[17]], templates = templates))

module <- getModule('course', 'Module1.Rda')
module_small = module[c(1, 4, 17)]

swirl2slidify <- function(course, module){
  module <- getModule(course, module)
  templates <- getTemplates()
  slides <- paste(
    lapply(module, process_q, templates = templates),
    collapse = '\n\n'
  )
  deck <- rCharts::render_template(
    template = templates[['master']],
    list(slides = slides)
  )
  return(deck)
}
