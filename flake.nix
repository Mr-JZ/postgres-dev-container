{
  description = "PostgreSQL development container setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    setupScript = { 
      containerName ? "dev-postgres",
      port ? 5432,
      postgresUser ? "postgres",
      postgresPassword ? "postgres",
      postgresDb ? "postgres",
      postgresVersion ? "15"
    }: ''
      if ! docker info > /dev/null 2>&1; then
        echo "🚫 Docker is not running. Please start Docker first."
        exit 1
      fi

      CONTAINER_NAME="${containerName}"
      
      if ! docker container inspect $CONTAINER_NAME > /dev/null 2>&1; then
        echo "🐘 PostgreSQL container not found. Starting new container..."
        docker run --name $CONTAINER_NAME \
          -e POSTGRES_PASSWORD="${postgresPassword}" \
          -e POSTGRES_USER="${postgresUser}" \
          -e POSTGRES_DB="${postgresDb}" \
          -p ${toString port}:5432 \
          -d postgres:${postgresVersion}
        
        echo "⏳ Waiting for PostgreSQL to be ready..."
        while ! docker exec $CONTAINER_NAME pg_isready > /dev/null 2>&1; do
          sleep 1
        done
        echo "✅ PostgreSQL is ready!"
      else
        if ! docker container inspect $CONTAINER_NAME --format '{{.State.Running}}' | grep -q "true"; then
          echo "🔄 PostgreSQL container exists but is not running. Starting it..."
          docker start $CONTAINER_NAME
          
          echo "⏳ Waiting for PostgreSQL to be ready..."
          while ! docker exec $CONTAINER_NAME pg_isready > /dev/null 2>&1; do
            sleep 1
          done
          echo "✅ PostgreSQL is ready!"
        else
          echo "✨ PostgreSQL container is already running"
        fi
      fi
    '';
  };
}
