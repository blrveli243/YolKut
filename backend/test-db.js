const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://postgres.fmawelqddxulcaqpejet:zekiveli999@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres",
  ssl: {
    rejectUnauthorized: false
  }
});

console.log("Connecting to Supabase...");
client.connect()
  .then(() => {
    console.log("SUCCESSFULLY CONNECTED!");
    return client.query("SELECT version();");
  })
  .then(res => {
    console.log("VERSION:", res.rows[0]);
    return client.end();
  })
  .catch(err => {
    console.error("CONNECTION ERROR DETAILS:");
    console.error(err);
    process.exit(1);
  });
