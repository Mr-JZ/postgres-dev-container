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
      postgresVersion ? "15",
      includeNvimDbee ? false,
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

      ${if includeNvimDbee then ''
      # Read DATABASE_URL from .env if it exists
      if [ -f .env ]; then
        DB_URL=$(grep DATABASE_URL .env | cut -d '=' -f2-)
        if [ ! -z "$DB_URL" ]; then
          export DBEE_CONNECTIONS="[{\"name\": \"brideboard-local\", \"url\": \"$DB_URL\", \"type\": \"postgres\"}]"
          echo "📦 Database connection configured from .env file"
        else
          echo "⚠️  DATABASE_URL not found in .env file, using default connection"
          export DBEE_CONNECTIONS='[{"name": "brideboard-local", "url": "postgresql://postgres:postgres@127.0.0.1:5432/postgres?sslmode=disable", "type": "postgres"}]'
        fi
      else
        echo "⚠️  No .env file found, using default connection"
        export DBEE_CONNECTIONS='[{"name": "brideboard-local", "url": "postgresql://postgres:postgres@127.0.0.1:5432/postgres?sslmode=disable", "type": "postgres"}]'
      fi
      '' else ""}
    '';
  };
}
