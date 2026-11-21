// 실행: node --test backend/test/
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHandler } from '../src/api.mjs';
import {
  DEMO_USER_ID, REPORT_STAGES, createSampleMyReportStore, handleMyReportRequest,
} from '../src/my_reports.mjs';

const handler = createHandler({}, { environment: 'test', reportsEnabled: false });
const request = (method, path) => handler({ rawPath: path, requestContext: { http: { method } } });

// 2026-11-20(금) 14:00 서울 시각
const now = new Date('2026-11-20T05:00:00Z');
const store = createSampleMyReportStore(() => now);
const call = (method, path, options = {}) => handleMyReportRequest(method, path, { store, ...options });

test('lists my reports with stages and staff responses', async () => {
  const response = await call('GET', '/me/reports');
  assert.equal(response.statusCode, 200);
  const body = JSON.parse(response.body);
  assert.equal(body.isDemo, true);
  assert.equal(body.utcOffsetMinutes, 540);
  assert.equal(body.items.length, 7);
  assert.equal(body.items.filter((item) => item.status !== 'resolved').length, 2);

  const [first] = body.items;
  assert.equal(first.id, 'demo-1');
  assert.equal(first.status, 'in_progress');
  assert.equal(first.occurredAt, '2026-11-20T11:20:00+09:00');
  assert.equal(first.updatedAt, '2026-11-20T13:10:00+09:00');
  assert.deepEqual(first.statusHistory.map((change) => change.status), ['received', 'checking', 'in_progress']);
  assert.equal(first.staffResponse.department, '학생지원처');
  assert.equal(first.staffResponse.plan, '오늘 18:00 야간 방역 예정');
});

test('sorts by latest status change and keeps valid values', async () => {
  const { items } = JSON.parse((await call('GET', '/me/reports')).body);
  const times = items.map((item) => Date.parse(item.updatedAt));
  assert.deepEqual(times, [...times].sort((a, b) => b - a));
  for (const item of items) {
    assert.ok(REPORT_STAGES.includes(item.status));
    assert.equal(item.source, 'user_report');
    // 실제 부서와 연동 전이므로 담당자 답변은 모두 가상 답변이다.
    if (item.staffResponse) assert.equal(item.staffResponse.isDemo, true);
  }
});

test('handles dates across month boundaries in Seoul time', async () => {
  const early = createSampleMyReportStore(() => new Date('2026-12-01T01:00:00Z'));
  const [, , , , , , oldest] = await early.listByUser(DEMO_USER_ID);
  assert.equal(oldest.occurredAt, '2026-11-19T17:40:00+09:00');
});

test('returns a single report and 404 for unknown ids', async () => {
  const found = await call('GET', '/me/reports/demo-3');
  assert.equal(found.statusCode, 200);
  assert.equal(JSON.parse(found.body).item.status, 'resolved');
  assert.equal((await call('GET', '/me/reports/unknown')).statusCode, 404);
});

test('returns no reports for other users', async () => {
  const response = await call('GET', '/me/reports', { resolveUserId: () => 'someone-else' });
  assert.deepEqual(JSON.parse(response.body).items, []);
});

test('rejects writes and ignores other paths', async () => {
  assert.equal((await call('POST', '/me/reports')).statusCode, 405);
  assert.equal(await call('GET', '/reports'), null);
  assert.equal(await call('GET', '/me/reports/Bad_ID'), null);
});

test('reports storage errors as 500', async () => {
  const broken = { async listByUser() { throw new Error('db down'); } };
  const response = await call('GET', '/me/reports', { store: broken });
  assert.equal(response.statusCode, 500);
});

test('routes through the shared API handler without touching report routes', async () => {
  assert.equal((await request('GET', '/me/reports')).statusCode, 200);
  assert.equal((await request('GET', '/me/reports/demo-1')).statusCode, 200);
  // 기존 제보 라우트 동작은 그대로다 (비활성화 시 403).
  assert.equal((await request('GET', '/reports')).statusCode, 403);
  assert.equal((await request('GET', '/health')).statusCode, 200);
  assert.equal((await request('GET', '/unknown')).statusCode, 404);
});
