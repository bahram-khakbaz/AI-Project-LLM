#!/bin/bash
# فایل: create_admin.sh
# استفاده: bash create_admin.sh <username> <password>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

USERNAME="$1"
PASSWORD="$2"
DB_HOST_PATH="/volumes/ai-project_open-webui-data/_data/webui.db"

if [ ! -f "$DB_HOST_PATH" ]; then
  echo "webui.db not found at $DB_HOST_PATH"
  exit 2
fi

HASH=$(python3 - <<PY
import bcrypt,sys
p=b"${PASSWORD.encode()}"
print(bcrypt.hashpw(p, bcrypt.gensalt()).decode())
PY
)

sqlite3 "$DB_HOST_PATH" "INSERT INTO user (username, password_hash, is_admin) VALUES ('$USERNAME', '$HASH', 1);"
echo "Done. Restarting container..."
docker restart open-webui