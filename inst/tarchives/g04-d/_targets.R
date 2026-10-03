library(targets)

tarchives::tar_source_archive("ksjdata")

ksj_pipeline("g04-d")
