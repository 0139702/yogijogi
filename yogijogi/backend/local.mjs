import { createServer } from 'node:http';
import { createHandler } from './src/api.mjs';

const items = new Map();
const handler = createHandler({
  async list() { return [...items.values()].reverse().slice(0, 50); },
  async get(id) { return items.get(id); },
  async create(item) { items.set(item.id, item); },
  async update(id, fields) {
    const previous = items.get(id);
    if (!previous) return null;
    const item = { ...previous, ...fields };
    items.set(id, item);
    return item;
  },
}, { environment: 'local', reportsEnabled: true });

const host = process.env.HOST || '127.0.0.1';
const port = Number(process.env.PORT || 3000);
const server = createServer(async (request, response) => {
  try {
    const chunks = [];
    let size = 0;
    for await (const chunk of request.iterator({ destroyOnReturn: false })) {
      size += chunk.length;
      if (size > 16 * 1024) {
        response.writeHead(413, { connection: 'close' }).end();
        return;
      }
      chunks.push(chunk);
    }
    const result = await handler({
      rawPath: new URL(request.url, 'http://localhost').pathname,
      requestContext: { http: { method: request.method } },
      body: Buffer.concat(chunks).toString('utf8'),
    });
    response.writeHead(result.statusCode, result.headers).end(result.body);
  } catch {
    if (!response.headersSent) response.writeHead(400).end();
  }
});

server.listen(port, host, () => {
  console.log(`YogiJogi local API on http://${host}:${server.address().port}`);
});
