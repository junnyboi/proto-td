# S3 deterministic world-art candidate pipeline

This isolated pipeline publishes exactly six `world.s3.*` logical candidates from original integer Pillow geometry. `art-src/world/s3/s3-production-source.png` is mandatory GPT Image 2 palette/material/provenance input only; source modules are never resized, cropped, pasted, or shipped as runtime rasters.

```sh
python3 tools/art_pipeline/world/s3/normalize_s3_world.py
python3 tools/art_pipeline/world/s3/validate_s3_world.py
python3 -m unittest -v tools/art_pipeline/world/s3/test_s3_world.py
```

Managed candidate roots are complete-replacement trees. Clean A/B and contaminated-C tests require identical path sets and bytes and prove stale owned files are removed. Candidate state remains `CANDIDATE_MACHINE_CONFORMANT_H1_PENDING`, `human_final_art:false`; H0 token `ACT-II-S2-S3-H0` authorizes production but no approved content hash gates launch and H1 is still required.
