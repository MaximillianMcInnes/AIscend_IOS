#!/bin/sh
set -eu

APP_INFO_PLIST="${1:-}"
ENV_FILE="${2:-${PROJECT_DIR:-.}/.env}"

if [ -z "${APP_INFO_PLIST}" ] || [ ! -f "${APP_INFO_PLIST}" ]; then
  exit 0
fi

if [ ! -f "${ENV_FILE}" ]; then
  echo ".env not found at ${ENV_FILE}; skipping API URL injection."
  exit 0
fi

dotenv_value() {
  KEY="$1"
  awk -v key="${KEY}" '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }

    /^[[:space:]]*(#|$)/ {
      next
    }

    {
      line = $0
      sub(/^[[:space:]]*export[[:space:]]+/, "", line)
      split(line, pair, "=")
      name = trim(pair[1])

      if (name != key) {
        next
      }

      sub(/^[^=]*=/, "", line)
      value = trim(line)

      first = substr(value, 1, 1)
      last = substr(value, length(value), 1)

      if ((first == "\"" && last == "\"") || (first == "\047" && last == "\047")) {
        value = substr(value, 2, length(value) - 2)
      }

      print value
      exit
    }
  ' "${ENV_FILE}"
}

first_dotenv_value() {
  for KEY in "$@"; do
    VALUE="$(dotenv_value "${KEY}")"

    if [ -n "${VALUE}" ]; then
      printf "%s" "${VALUE}"
      return 0
    fi
  done

  return 0
}

plist_value() {
  KEY="$1"
  /usr/libexec/PlistBuddy -c "Print :${KEY}" "${APP_INFO_PLIST}" 2>/dev/null || true
}

first_value() {
  for VALUE in "$@"; do
    if [ -n "${VALUE}" ]; then
      printf "%s" "${VALUE}"
      return 0
    fi
  done

  return 0
}

set_plist_string() {
  KEY="$1"
  VALUE="$2"

  if [ -z "${VALUE}" ]; then
    return 0
  fi

  /usr/libexec/PlistBuddy -c "Delete :${KEY}" "${APP_INFO_PLIST}" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :${KEY} string ${VALUE}" "${APP_INFO_PLIST}"
}

API_URL="$(first_value "$(plist_value API_BASE_URL)" "$(plist_value AISCEND_API_BASE_URL)" "$(first_dotenv_value API_BASE_URL AISCEND_API_BASE_URL NEXT_PUBLIC_API_BASE_URL)")"
RAG_URL="$(first_value "$(plist_value RAG_BASE_URL)" "$(plist_value AISCEND_RAG_BASE_URL)" "$(plist_value AISCEND_CHATBOT_API_URL)" "$(first_dotenv_value RAG_BASE_URL AISCEND_RAG_BASE_URL AISCEND_CHATBOT_API_URL NEXT_PUBLIC_CHATBOT_API_URL)")"
SCAN_ANALYZE_PATH="$(first_value "$(plist_value AISCEND_SCAN_ANALYZE_PATH)" "$(first_dotenv_value AISCEND_SCAN_ANALYZE_PATH)")"
SCAP_API_URL="$(first_value "$(plist_value AISCEND_SCAP_API_URL)" "$(first_dotenv_value AISCEND_SCAP_API_URL NEXT_PUBLIC_SCAP_API_URL)")"

set_plist_string API_BASE_URL "${API_URL}"
set_plist_string RAG_BASE_URL "${RAG_URL}"
set_plist_string AISCEND_API_BASE_URL "${API_URL}"
set_plist_string AISCEND_CHATBOT_API_URL "${RAG_URL}"
set_plist_string AISCEND_RAG_BASE_URL "${RAG_URL}"
set_plist_string AISCEND_SCAN_ANALYZE_PATH "${SCAN_ANALYZE_PATH}"
set_plist_string AISCEND_SCAP_API_URL "${SCAP_API_URL}"
