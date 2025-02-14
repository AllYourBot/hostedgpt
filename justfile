containerid := `docker ps | grep hostedgpt-base | cut -d " " -f 1`

start:
    docker compose up --build

bash:
    docker exec -it {{containerid}} bash

overmind:
    docker exec -it {{containerid}} overmind connect
    
teardown:
    docker compose down --volumes
    