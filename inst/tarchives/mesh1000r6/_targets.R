library(targets)

tarchives::tar_source_archive("ksjdata")

ksj_pipeline("mesh1000r6")
