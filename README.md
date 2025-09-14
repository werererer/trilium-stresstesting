# trilium-stresstesting
Tools to stress-test Trilium, to help prove it works at scale.

Still experimental, and subject to change a lot.

The goal is to test if Trilium can scale, and hopefully make reproducing errors at scale easier.

# Goal
Make errors on large-scale databases for Trilium more reproducible by providing code to automatically create them.

# WIP
What still has to be done to make it useful?

Legend:  
' ' = TODO; '<-' = Currently Doing; 'X' = DONE

- [ ] Include Trilium databases from WordNet to create notes that feel kind of "natural" (text only) <-
  - [ ] Create enhanced Trilium WordNet notes + random images  
  - [ ] Create enhanced Trilium WordNet notes + Lorem Ipsum content  
- [ ] Create Trilium databases with lots of images (maybe using machine learning datasets)
