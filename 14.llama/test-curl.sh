curl http://192.168.0.244:8080/v1/chat/completions   -H "Content-Type: application/json"   -d '{
    "model": "kanana-nano-2.1b-instruct",
    "messages": [
      {"role": "user", "content": "넌 뭐야?"}
    ],
    "temperature": 0.7,
    "max_tokens": 512
  }'