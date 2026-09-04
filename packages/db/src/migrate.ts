import { pool } from "./index";
import * as fs from "fs";
import * as path from "path";

async function migrate() {
  const schema = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf-8");
  await pool.query(schema);
  console.log("Migration complete");
  process.exit(0);
}
migrate().catch(err => {
  console.error(err);
  process.exit(1);
});