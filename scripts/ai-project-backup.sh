#!/bin/bash
# فایل: /usr/local/bin/ai-project-backup.sh
OUTDIR=/backup/ai-project/$(date +%F)
mkdir -p "$OUTDIR"

docker run --rm -v ai-project_open-webui-data:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/openwebui-data.tgz -C /data ."
docker run --rm -v ai-project_open-webui-storage:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/openwebui-storage.tgz -C /data ."
docker run --rm -v ai-project_qdrant:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/qdrant.tgz -C /data ."
docker run --rm -v ai-project_ollama:/data -v "$OUTDIR":/backup busybox \
  sh -c "tar czf /backup/ollama.tgz -C /data ."
