#!/bin/bash
# run_busco_check.sh
# Runs BUSCO completeness check on all three ProbioLR-NF assemblies, one at a time.
# Usage: bash run_busco_check.sh

set -euo pipefail

RESULTS_DIR=~/probiotics/results

echo "=== Running BUSCO on B_animalis ==="
docker run --rm -v ${RESULTS_DIR}:/data staphb/busco:latest \
    busco -i /data/assembly/B_animalis/assembly.fasta -o busco_B_animalis_v2 -m genome -l bacteria_odb10

echo ""
echo "=== Running BUSCO on L_brevis ==="
docker run --rm -v ${RESULTS_DIR}:/data staphb/busco:latest \
    busco -i /data/assembly/L_brevis/assembly.fasta -o busco_L_brevis_v2 -m genome -l bacteria_odb10

echo ""
echo "=== Running BUSCO on L_plantarum ==="
docker run --rm -v ${RESULTS_DIR}:/data staphb/busco:latest \
    busco -i /data/assembly/L_plantarum/assembly.fasta -o busco_L_plantarum_v2 -m genome -l bacteria_odb10

echo ""
echo "=== All done. Summary lines: ==="
grep -A1 "Results:" ${RESULTS_DIR}/busco_B_animalis_v2/*.txt 2>/dev/null | head -2
grep -A1 "Results:" ${RESULTS_DIR}/busco_L_brevis_v2/*.txt 2>/dev/null | head -2
grep -A1 "Results:" ${RESULTS_DIR}/busco_L_plantarum_v2/*.txt 2>/dev/null | head -2
