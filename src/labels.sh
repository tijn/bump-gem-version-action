# Create labels if they don't exist
create_labels() {
  echo "::group::🏷 Setting up bump labels ..."

  for label_file in /labels/*.json; do
    if [ -f "$label_file" ]; then
      label_name=$(jq -r '.name' "$label_file")
      label_color=$(jq -r '.color' "$label_file")
      label_desc=$(jq -r '.description' "$label_file")

      echo "::notice::Creating label: ${label_name}"
      github_create_label "${label_name}" "${label_color}" "${label_desc}"
    fi
  done

  echo "::endgroup::"
}
