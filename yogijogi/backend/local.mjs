import { randomUUID } from 'node:crypto';
import { createServer } from 'node:http';
import { createHandler, PHOTO_MAX_BYTES } from './src/api.mjs';
import { seedReports } from './local-seed.mjs';

const items = new Map();
if (process.env.SEED_REPORTS !== 'false') seedReports(items);

// Stands in for S3 presigned URLs: one-time upload tokens and in-memory files.
const uploads = new Map();
const photos = new Map();
const UPLOAD_TTL_MS = 5 * 60 * 1000;

function baseUrl(event) {
  return `http://${event.headers?.host ?? `127.0.0.1:${port}`}`;
}

const photoStorage = {
  async createUpload(key, { contentType, size }, event) {
    const token = randomUUID();
    uploads.set(key, { token, contentType, size, expiresAt: Date.now() + UPLOAD_TTL_MS });
    return {
      method: 'PUT',
      url: `${baseUrl(event)}/_local/uploads/${key}?token=${token}`,
      headers: { 'content-type': contentType },
      expiresIn: UPLOAD_TTL_MS / 1000,
    };
  },
  async head(key) {
    const photo = photos.get(key);
    return photo ? { contentType: photo.contentType, size: photo.body.length } : null;
  },
  async getUrl(key, event) {
    return `${baseUrl(event)}/_local/photos/${key}`;
  },
  async remove(key) {
    photos.delete(key);
  },
};

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
  async remove(id) { items.delete(id); },
}, { environment: 'local', reportsEnabled: true, photoStorage });

function handleUpload(request, response, url, body) {
  const key = url.pathname.slice('/_local/uploads/'.length);
  const upload = uploads.get(key);
  const contentType = request.headers['content-type'];
  if (!upload || upload.token !== url.searchParams.get('token') || upload.expiresAt < Date.now()) {
    return response.writeHead(403).end();
  }
  if (contentType !== upload.contentType || body.length !== upload.size) {
    return response.writeHead(400).end();
  }
  uploads.delete(key);
  photos.set(key, { contentType, body });
  response.writeHead(200).end();
}

function handlePhoto(response, url) {
  const photo = photos.get(url.pathname.slice('/_local/photos/'.length));
  if (!photo) return response.writeHead(404).end();
  response.writeHead(200, { 'content-type': photo.contentType }).end(photo.body);
}

const host = process.env.HOST || '127.0.0.1';
const port = Number(process.env.PORT || 3000);
const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://localhost');
    const isUpload = request.method === 'PUT' && url.pathname.startsWith('/_local/uploads/');
    if (request.method === 'GET' && url.pathname.startsWith('/_local/photos/')) {
      return handlePhoto(response, url);
    }

    const limit = isUpload ? PHOTO_MAX_BYTES : 16 * 1024;
    const chunks = [];
    let size = 0;
    for await (const chunk of request.iterator({ destroyOnReturn: false })) {
      size += chunk.length;
      if (size > limit) {
        response.writeHead(413, { connection: 'close' }).end();
        return;
      }
      chunks.push(chunk);
    }
    const body = Buffer.concat(chunks);
    if (isUpload) return handleUpload(request, response, url, body);

    const result = await handler({
      rawPath: url.pathname,
      headers: request.headers,
      requestContext: { http: { method: request.method } },
      body: body.toString('utf8'),
    });
    response.writeHead(result.statusCode, result.headers).end(result.body);
  } catch {
    if (!response.headersSent) response.writeHead(400).end();
  }
});

server.listen(port, host, () => {
  console.log(`YogiJogi local API on http://${host}:${server.address().port}`);
});
