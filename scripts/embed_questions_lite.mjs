import pg from 'pg';
import { embed } from './embed_lib.mjs';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const { rows } = await client.query(
  'SELECT question_id, question_text FROM question WHERE embedding IS NULL'
);
console.log(`Embedding ${rows.length} questions...`);

for (const r of rows) {
  await client.query(
    'UPDATE question SET embedding = $1::vector WHERE question_id = $2',
    [embed(r.question_text), r.question_id]
  );
  console.log(`  question ${r.question_id} done`);
}

await client.end();
console.log('Finished.');
