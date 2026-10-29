import pg from 'pg';
import { embed } from './embed_lib.mjs';

const query = process.argv.slice(2).join(' ');
if (!query) {
  console.log('Usage: node scripts/search_lite.mjs "your search text"');
  process.exit(1);
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const { rows } = await client.query(
  `SELECT question_id, question_text,
          ROUND((1 - (embedding <=> $1::vector))::numeric, 3) AS similarity
   FROM question
   WHERE embedding IS NOT NULL
   ORDER BY embedding <=> $1::vector
   LIMIT 5`,
  [embed(query)]
);

console.table(rows);
await client.end();
