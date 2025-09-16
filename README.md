# trilium-stresstesting (WIP)
Tools to stress-test Trilium, to help prove it works at scale.
Tools to stresstest trilium, to help proof it working at scale.

Still experimental, and subject to change a lot.

The goal is to test if Trilium can scale, and hopefully make reproducing errors at scale easier.

# Goal
Make errors on large-scale databases for Trilium more reproducible by providing code to automatically create them.

# WIP
What still has to be done to make it useful?

Legend:  
' ' = TODO; '<-' = Currently Doing; 'X' = DONE

- [ ] Include Trilium database for WordNet [^1] to create notes that feel kind of "natural" (text only) <-
  - [ ] Create enhanced Trilium WordNet notes + random images  
  - [ ] Create enhanced Trilium WordNet notes + Lorem Ipsum content  
- [ ] Include Trilium database for ConceptNet [^2] or YAGO [^3]
- [ ] Create Trilium databases with lots of images (using open machine learning datasets)
- [ ] Create Trilium databases with lots of videos (using open machine learning datasets)
- [ ] Write a simple guide to test it with trilium

# References
[^1]: https://www.nltk.org/howto/wordnet.html
[^2]: https://conceptnet.io/
[^3]: https://yago-knowledge.org/
The goal is to test, if trilium can scale. Especially for personal/research interest

## Execute
```bash
docker compose up -d
```

After being done
```
docker compose down
```
