#!/bin/bash

# Usage: ./generate_project.sh <project_name>

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to display usage information
usage() {
  echo "Usage: $0 <project_name>"
  exit 1
}

# Check if project name is provided
if [ -z "$1" ]; then
  usage
fi

PROJECT_NAME=$1

# Create project directory
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize git repository
git init

# Initialize npm project with default settings
npm init -y

# Install runtime dependencies
npm install dotenv@^16.4.5 express@^4.20.0 ts-node@^10.9.2 typescript@^5.6.2 uuid@^10.0.0

# Install development dependencies
npm install --save-dev @types/cors@^2.8.17 @types/express@^4.17.21 @types/nodemon@^1.19.6 @types/node@^22.5.4 @types/uuid@^10.0.0 nodemon@^3.1.4

# Create tsconfig.json with the specified configuration
cat > tsconfig.json <<EOL
{
  "compilerOptions": {
    /* Base Options */
    "target": "ES2022",
    "module": "NodeNext",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "allowJs": true,
    "resolveJsonModule": true,
    "moduleDetection": "force",
    "isolatedModules": true,
    "verbatimModuleSyntax": true,

    /* Strictness */
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,

    /* Output Options */
    "outDir": "dist",
    "sourceMap": true,

    /* Library Options */
    "lib": ["ES2022"],

    /* Declaration Files */
    "declaration": true,
    "declarationMap": true,
    "composite": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
EOL

# Create Dockerfile with the provided content
cat > Dockerfile <<EOL
# Use the official Node.js 18 image.
FROM node:18-alpine

# Create and change to the app directory.
WORKDIR /usr/src

# Copy package.json and package-lock.json.
COPY package*.json ./

# Install dependencies.
RUN npm ci --omit='dev'

# Copy the rest of the application code.
COPY . .

# Expose the port the app runs on.
EXPOSE 8080

# Build the TypeScript code.
RUN npm run build

# Start the application.
CMD ["node", "dist/index.js"]
EOL

# Create a basic source directory and index.ts
mkdir src
cat > src/index.ts <<EOL
import express from 'express';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

dotenv.config();

const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send('Hello, Cloud Run!');
});

app.get('/uuid', (req, res) => {
  res.send(\`Generated UUID: \${uuidv4()}\`);
});

app.listen(port, () => {
  console.log(\`App listening on port \${port}\`);
});
EOL

# Function to add scripts to package.json
add_scripts() {
  # Detect OS type
  OS_TYPE=$(uname)

  if command -v jq > /dev/null; then
    # Use jq to add scripts
    jq '.scripts = {
      "start": "node dist/index.js",
      "dev": "nodemon src/index.ts",
      "build": "rm -rf ./dist && npx tsc"
    }' package.json > tmp.$$.json && mv tmp.$$.json package.json
  else
    # Use sed as a fallback
    if [ "$OS_TYPE" = "Darwin" ]; then
      # macOS requires a backup extension or empty string
      sed -i '' '/"scripts": {/a\
        "start": "node dist/index.js",\
        "dev": "nodemon src/index.ts",\
        "build": "rm -rf ./dist && npx tsc",\
      ' package.json
    else
      # Assume Linux for GNU sed
      sed -i '/"scripts": {/a \
        "start": "node dist/index.js", \
        "dev": "nodemon src/index.ts", \
        "build": "rm -rf ./dist && npx tsc", \
      ' package.json
    fi
  fi
}

# Add start, dev, and build scripts to package.json
add_scripts

# Create a .env file with default variables
cat > .env <<EOL
PORT=8080
# Add other environment variables below
EOL

# Create a .gitignore file
cat > .gitignore <<EOL
node_modules
dist
.env
EOL

echo "Project '$PROJECT_NAME' has been created successfully."
echo "Next steps:"
echo "1. Navigate to the project directory: cd $PROJECT_NAME"
echo "2. Install dependencies if not already installed: npm install"
echo "3. Build the project: npm run build"
echo "4. Run the project: npm start"
echo "5. For development with auto-reloading: npm run dev"