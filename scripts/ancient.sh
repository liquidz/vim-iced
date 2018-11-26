RESULT=$(clojure -A:ancient)
echo "$RESULT"

echo "$RESULT" | grep "All up to date" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    exit 1
fi

exit 0
