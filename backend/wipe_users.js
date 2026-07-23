const { Client } = require('pg');

const connectionString = "postgresql://neondb_owner:npg_qbApwLUDWI12@ep-sweet-unit-awy2ncd5-pooler.c-12.us-east-1.aws.neon.tech/neondb?sslmode=require";

async function main() {
  const client = new Client({
    connectionString: connectionString,
  });
  
  try {
    await client.connect();
    console.log("Connected to database successfully via pooler.");
    
    await client.query('TRUNCATE TABLE "User" CASCADE;');
    console.log("Successfully deleted all users and related data.");
    
  } catch (err) {
    console.error("Error executing query", err.stack);
  } finally {
    await client.end();
  }
}

main();
