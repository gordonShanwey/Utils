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

# Install necessary dependencies
npm install express
npm install typescript @types/node @types/express --save-dev

# Create tsconfig.json with the corrected content
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

const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send('Hello, Cloud Run!');
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
    jq '.scripts += {"build":"tsc", "start":"node dist/index.js"}' package.json > tmp.$$.json && mv tmp.$$.json package.json
  else
    # Use sed as a fallback
    if [ "$OS_TYPE" = "Darwin" ]; then
      # macOS requires a backup extension or empty string
      sed -i '' '/"test":/a\
        "build": "tsc",\
        "start": "node dist/index.js",
      ' package.json
    else
      # Assume Linux for GNU sed
      sed -i '/"test":/a \
        "build": "tsc",\
        "start": "node dist/index.js",
      ' package.json
    fi
  fi
}

# Add build and start scripts to package.json
add_scripts

# Create a .gitignore file
cat > .gitignore <<EOL
node_modules
dist
.env
EOL

# Initialize TypeScript configuration
# Note: Since we've already created tsconfig.json, this step can be skipped or ensured to match
# Here, we skip it to avoid overwriting
# Uncomment the next line if you want to ensure tsconfig.json is initialized
# npx tsc --init

echo "Project '$PROJECT_NAME' has been created successfully."
echo "Next steps:"
echo "1. Navigate to the project directory: cd $PROJECT_NAME"
echo "2. Install dependencies if not already installed: npm install"
echo "3. Build the project: npm run build"
echo "4. Run the project: npm start"