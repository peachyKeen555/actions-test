- id: create-matrix
  name: "Create metadata.json matrix"
  run: |
    if [ -d "json-files" ]; then
      # Initialize an empty JSON array
      MATRIX_JSON=$(jq -n '[]')

      # Loop through all metadata.json files in the specified directory
      for file in $(find json-files -name 'metadata.json'); do
        # Read the current file content
        FILE_CONTENT=$(cat "$file")

        # Determine if the current file content is a single object or an array
        if jq -e . <<< "$FILE_CONTENT" > /dev/null 2>&1; then
          # It's a single object, wrap it in an array
          FILE_CONTENT=$(jq -n '[$input]' --argjson input "$FILE_CONTENT")
        fi

        # Merge the current file content (now guaranteed to be an array) into MATRIX_JSON
        MATRIX_JSON=$(jq -s '.[0] + .[1]' <<< "$MATRIX_JSON $FILE_CONTENT")
      done

      # Check if MATRIX_JSON is not just an empty array
      if [[ "$MATRIX_JSON" != "[]" ]]; then
        # Wrap the combined array in an 'include' object
        MATRIX_JSON=$(jq '{include: .}' <<< "$MATRIX_JSON")

        # Echo the final MATRIX_JSON into a file named 'matrix.json'
        echo "$MATRIX_JSON" > /tmp/matrix.json

        # Set the matrix JSON as an output variable using the $GITHUB_OUTPUT environment variable
        echo "matrix<<EOF" >> $GITHUB_OUTPUT
        cat /tmp/matrix.json >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT

        echo "🟢 Successfully merged metadata.json:"
        cat /tmp/matrix.json
      else
        echo "🚨 No metadata.json files found or they are empty."
      fi
    else
      echo "🚨 Directory 'json-files' does not exist, skipping matrix creation."
    fi